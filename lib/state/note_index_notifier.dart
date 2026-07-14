import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../models/note_index.dart';
import '../models/note_type_spec.dart';
import '../models/relationship_type_spec.dart';
import 'providers.dart';

/// The app-wide cache of every note in the data folder. Built once per
/// folder by scanning disk (see [NotesService.scanNotes]), then kept in sync
/// in memory as the app itself writes/deletes/creates notes — this app is
/// the only writer to the folder, so no external-change staleness handling
/// is needed. All triage/list/floating-notes flows read from this instead of
/// each re-scanning disk independently.
class NoteIndexNotifier extends AsyncNotifier<NoteIndex> {
  @override
  Future<NoteIndex> build() async {
    // Await rather than read-and-bang: if dataFolderProvider hasn't resolved
    // yet, watching its raw AsyncValue and racing a null .value would throw,
    // and the resulting rebuild-on-settle would abandon this build's Future
    // — orphaning anyone already awaiting it. Awaiting .future here instead
    // suspends properly until it settles.
    final folder = (await ref.watch(dataFolderProvider.future))!;
    final entries = <String, NoteFile>{};
    final unparsable = <String>{};
    await for (final result in ref.read(notesServiceProvider).scanNotes(folder)) {
      if (result.data != null) {
        entries[result.filename] = result.data!;
      } else {
        unparsable.add(result.filename);
      }
    }
    return NoteIndex(entries: entries, unparsable: unparsable);
  }

  Future<void> write(String filename, NoteFile content) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    await ref.read(notesServiceProvider).writeJsonFile(folder, filename, content);
    await update((index) => index.copyWith(entries: {...index.entries, filename: content}));
  }

  Future<void> delete(String filename) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    await ref.read(notesServiceProvider).deleteJsonFile(folder, filename);
    await update((index) => index.copyWith(entries: {...index.entries}..remove(filename)));
  }

  /// Attaches `[relType, relatedFilename]` to `filename`'s `rels`, then — if
  /// `relType` has a [RelationshipTypeSpec.mirrorRelType] and
  /// `relatedFilename` exists — also attaches `[mirrorRelType, filename]` to
  /// the related note, so e.g. adding a source to a quote also adds the
  /// quote back to the source. `log` and `seeAlso` have no mirrorRelType, so
  /// they're never mirrored, per docs/specs/type-improve.md. Idempotent: a
  /// pair already present on either side is not duplicated (needed so
  /// `_deleteRelated`'s Undo, which restores the related note's full
  /// pre-delete content and then re-attaches, doesn't double the mirror).
  Future<void> attachRelationship({
    required String filename,
    required String relType,
    required String relatedFilename,
  }) async {
    final index = await future;
    final note = index.entries[filename];
    if (note == null) return;
    final rel = [relType, relatedFilename];
    if (!note.stringPairList('rels').any((r) => r[0] == rel[0] && r[1] == rel[1])) {
      await write(filename, {
        ...note,
        'rels': [...note.stringPairList('rels'), rel],
      });
    }

    final mirrorRelType = _mirrorRelTypeFor(relType);
    if (mirrorRelType == null) return;
    final related = (await future).entries[relatedFilename];
    if (related == null) return;
    final mirrorRel = [mirrorRelType, filename];
    if (!related.stringPairList('rels').any((r) => r[0] == mirrorRel[0] && r[1] == mirrorRel[1])) {
      await write(relatedFilename, {
        ...related,
        'rels': [...related.stringPairList('rels'), mirrorRel],
      });
    }
  }

  /// Removes [rel] from `filename`'s `rels`, then — if `rel[0]` has a
  /// [RelationshipTypeSpec.mirrorRelType] and the related note exists —
  /// also removes the mirrored `[mirrorRelType, filename]` pair from it.
  Future<void> detachRelationship({required String filename, required List<String> rel}) async {
    final index = await future;
    final note = index.entries[filename];
    if (note != null) {
      final rels = note.stringPairList('rels').where((r) => r[0] != rel[0] || r[1] != rel[1]);
      await write(filename, {...note, 'rels': rels.toList()});
    }

    final mirrorRelType = _mirrorRelTypeFor(rel[0]);
    if (mirrorRelType == null) return;
    final relatedFilename = rel[1];
    final related = (await future).entries[relatedFilename];
    if (related == null) return;
    final mirrorRels = related
        .stringPairList('rels')
        .where((r) => !(r[0] == mirrorRelType && r[1] == filename));
    await write(relatedFilename, {...related, 'rels': mirrorRels.toList()});
  }

  /// Falls back to `null` (no mirroring) for a relType not in the registry
  /// (e.g. a hand-edited file, or a relType retired from the registry) —
  /// degrades gracefully rather than crashing, matching
  /// `NoteDetailScreen._relationshipLabel`'s conventions.
  String? _mirrorRelTypeFor(String relType) {
    for (final spec in relationshipTypeSpecs) {
      if (spec.relType == relType) return spec.mirrorRelType;
    }
    return null;
  }

  /// Creates a new `primaryType: "hypothesis"` note, active with empty
  /// context/experiment/notes/findings sections, from the inline add field on
  /// the Hypotheses screen.
  Future<String> createHypothesis({required String title}) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    final hypothesisSpec = noteTypeSpecs.firstWhere((s) => s.primaryType == 'hypothesis');
    final content = <String, dynamic>{
      'primaryType': 'hypothesis',
      'title': title,
      'secondaryType': hypothesisSpec.defaultSecondaryType,
      'context': <String>[],
      'experiment': <String>[],
      'notes': <String>[],
      'findings': <String>[],
    };
    final filename =
        await ref.read(notesServiceProvider).createNote(folder, content, slugSource: title);
    await update((index) => index.copyWith(entries: {...index.entries, filename: content}));
    return filename;
  }

  /// Creates a new `primaryType: "log"` note, stamped with the current
  /// moment as `createdAt` (ISO 8601) — a generic title-only
  /// [createFromSpec] create can't set that, so this is used instead (see
  /// the `hypothesis` branch alongside it in `_AddScreenState._createNote`).
  /// Always reached via the relationship-attach flow from a
  /// hypothesis/source/milestone note, never as a standalone create.
  Future<String> createLog({required String title}) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    final content = <String, dynamic>{
      'primaryType': 'log',
      'title': title,
      'content': '',
      'createdAt': DateTime.now().toIso8601String(),
    };
    final filename =
        await ref.read(notesServiceProvider).createNote(folder, content, slugSource: title);
    await update((index) => index.copyWith(entries: {...index.entries, filename: content}));
    return filename;
  }

  /// Creates a new note of [spec]'s primaryType with [title] and an empty
  /// string for every other field in [spec.fields] (e.g. `content`), for the
  /// "new note" action on a type's Lists screen. [secondaryType], when given,
  /// is stamped onto the note too (the Add screen's secondaryType picker,
  /// when [spec.secondaryTypes] is non-empty).
  Future<String> createFromSpec(
    NoteTypeSpec spec, {
    required String title,
    String? secondaryType,
  }) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    final content = <String, dynamic>{'primaryType': spec.primaryType, 'title': title};
    for (final field in spec.fields) {
      if (field.key != 'title') content[field.key] = '';
    }
    if (secondaryType != null) content['secondaryType'] = secondaryType;
    final filename =
        await ref.read(notesServiceProvider).createNote(folder, content, slugSource: title);
    await update((index) => index.copyWith(entries: {...index.entries, filename: content}));
    return filename;
  }

  /// Forces a fresh full-folder rescan, e.g. as a manual escape hatch if the
  /// in-memory index is ever suspected to have drifted from disk.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final noteIndexProvider = AsyncNotifierProvider<NoteIndexNotifier, NoteIndex>(NoteIndexNotifier.new);
