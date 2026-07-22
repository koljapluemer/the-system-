// ignore_for_file: avoid_print
// One-time throwaway migration: reshapes `rels` entries in the data folder
// from 2-element [label, filename] pairs to 3-element
// [label, filename, mirrorLabel] triples, and backfills the reverse link on
// the related note wherever it's missing (e.g. today's one-directional
// `seeAlso`/`log` rels) — see the "Simplify inter-note relationships" plan.
//
// Deliberately has zero imports from lib/ so it keeps working even after
// lib/models/relationship_type_spec.dart (the historical registry this
// script's mirror table is copied from) is deleted.
//
// Usage:
//   dart run tool/migrate_rels_v2.dart <folder> [--apply] [--verbose]
//
// Dry-run by default (prints a summary, touches nothing on disk). Pass
// --apply to actually write the changed files. Safe to re-run: already
// migrated (3-element) entries are left untouched, so a second run is a
// no-op.

import 'dart:convert';
import 'dart:io';

/// Historical mirrorRelType mapping, copied from the soon-to-be-deleted
/// lib/models/relationship_type_spec.dart. Anything not listed here
/// (including seeAlso and log, which were never mirrored) falls back to
/// 'backlink'.
const _historicalMirrors = <String, String>{
  'source': 'sourceOf',
  'sourceOf': 'source',
  'evidence': 'evidenceFor',
  'evidenceFor': 'evidence',
  'entity': 'entityOf',
  'entityOf': 'entity',
  'description': 'gestalt',
  'gestalt': 'description',
  'context': 'ifThen',
  'ifThen': 'context',
  'opposite': 'opposite',
  'agrees': 'agrees',
  'parent': 'child',
  'child': 'parent',
};

String _mirrorFor(String label) => _historicalMirrors[label] ?? 'backlink';

bool _isRelEntry(dynamic entry) =>
    entry is List && entry.length >= 2 && entry.every((e) => e is String);

void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.isEmpty) {
    stderr.writeln('Usage: dart run tool/migrate_rels_v2.dart <folder> [--apply] [--verbose]');
    exitCode = 1;
    return;
  }
  final folder = positional.first;
  final apply = args.contains('--apply');
  final verbose = args.contains('--verbose');

  final dir = Directory(folder);
  if (!dir.existsSync()) {
    stderr.writeln('Folder does not exist: $folder');
    exitCode = 1;
    return;
  }

  final notes = <String, Map<String, dynamic>>{};
  for (final entity in dir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final filename = entity.uri.pathSegments.last;
    try {
      final decoded = jsonDecode(entity.readAsStringSync());
      if (decoded is Map<String, dynamic>) notes[filename] = decoded;
    } catch (_) {
      // Unparsable file — left alone, same as the app's own scanNotes.
    }
  }

  final changed = <String>{};
  var upgradedCount = 0;
  var backfilledCount = 0;
  var danglingCount = 0;

  // Pass 1: upgrade every 2-element entry to 3 elements in place.
  final pending = <(String file, String label, String target, String mirrorLabel)>[];
  for (final entry in notes.entries) {
    final filename = entry.key;
    final rels = entry.value['rels'];
    if (rels is! List) continue;

    for (var i = 0; i < rels.length; i++) {
      final rel = rels[i];
      if (!_isRelEntry(rel) || rel.length != 2) continue;
      final label = rel[0] as String;
      final target = rel[1] as String;
      final mirrorLabel = _mirrorFor(label);
      rels[i] = [label, target, mirrorLabel];
      changed.add(filename);
      upgradedCount++;
      pending.add((filename, label, target, mirrorLabel));
      if (verbose) {
        print('[upgrade] $filename: [$label, $target] -> [$label, $target, $mirrorLabel]');
      }
    }
  }

  // Pass 2: backfill/upgrade the reverse entry on each target note.
  for (final (filename, label, target, mirrorLabel) in pending) {
    final targetNote = notes[target];
    if (targetNote == null) {
      danglingCount++;
      if (verbose) print('[dangling] $filename -> $target ($label) has no target note, skipped');
      continue;
    }

    final targetRels = (targetNote['rels'] as List?) ?? [];
    final existingIndex = targetRels.indexWhere(
      (r) => _isRelEntry(r) && r[0] == mirrorLabel && r[1] == filename,
    );

    if (existingIndex == -1) {
      targetNote['rels'] = [...targetRels, [mirrorLabel, filename, label]];
      changed.add(target);
      backfilledCount++;
      if (verbose) {
        print('[backfill] $target: new entry [$mirrorLabel, $filename, $label]');
      }
    } else if ((targetRels[existingIndex] as List).length == 2) {
      targetRels[existingIndex] = [mirrorLabel, filename, label];
      targetNote['rels'] = targetRels;
      changed.add(target);
      upgradedCount++;
      if (verbose) {
        print('[upgrade] $target: [$mirrorLabel, $filename] -> [$mirrorLabel, $filename, $label]');
      }
    }
    // else: already a 3-element entry — leave it untouched (don't clobber a
    // hand-edited divergence).
  }

  print('Scanned ${notes.length} notes.');
  print('Entries upgraded to 3 elements: $upgradedCount');
  print('Reverse entries backfilled: $backfilledCount');
  print('Dangling targets skipped: $danglingCount');
  print('Files ${apply ? "written" : "that would be written"}: ${changed.length}');

  if (!apply) {
    print('\nDry run only — no files were changed. Re-run with --apply to write changes.');
    return;
  }

  const encoder = JsonEncoder.withIndent('  ');
  for (final filename in changed) {
    File('$folder/$filename').writeAsStringSync(encoder.convert(notes[filename]));
  }
  print('\nDone.');
}
