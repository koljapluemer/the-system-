import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../models/floating_note_entry.dart';
import '../models/note_file.dart';

/// Reads/writes/lists/deletes note files that live as flat JSON files
/// directly inside a single data folder. Mirrors the file-IO command
/// boundary the Rust backend used to expose over Tauri's invoke bridge.
class NotesService {
  const NotesService();

  static const _forbiddenTokens = ['/', '\\', '..'];

  void _assertSafeFilename(String filename) {
    for (final token in _forbiddenTokens) {
      if (filename.contains(token)) {
        throw ArgumentError('invalid filename: $filename');
      }
    }
  }

  File _notePath(String folder, String filename) {
    _assertSafeFilename(filename);
    return File(p.join(folder, filename));
  }

  /// Scans the data folder for scratchpad notes that still need triage, i.e.
  /// `primaryType == "scratchpad"` and `triaged != "true"`. Returns filenames
  /// only; use [readJsonFile] to load the full contents of one.
  Future<List<String>> listScratchpadUntriaged(String folder) async {
    final dir = Directory(folder);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final matches = <String>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final data = jsonDecode(await entity.readAsString());
        if (data is! Map<String, dynamic>) continue;
        if (data['primaryType'] != 'scratchpad') continue;
        if (data['triaged'] == 'true') continue;
        matches.add(p.basename(entity.path));
      } catch (_) {
        continue;
      }
    }
    return matches;
  }

  /// Scans the data folder for art notes that still need triage, i.e.
  /// `primaryType == "art"` and `triaged != "true"`. Returns filenames only;
  /// use [readJsonFile] to load the full contents of one.
  Future<List<String>> listArtUntriaged(String folder) async {
    final dir = Directory(folder);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final matches = <String>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final data = jsonDecode(await entity.readAsString());
        if (data is! Map<String, dynamic>) continue;
        if (data['primaryType'] != 'art') continue;
        if (data['triaged'] == 'true') continue;
        matches.add(p.basename(entity.path));
      } catch (_) {
        continue;
      }
    }
    return matches;
  }

  /// Scans the data folder for notes eligible to appear on the floating-notes
  /// canvas: `primaryType == "unknown"`, or `primaryType == "scratchpad"` that
  /// has already been triaged (`triaged == "true"`). Every matching note is
  /// yielded eventually — nothing is dropped or capped, however large the
  /// folder — but reads happen [concurrency]-wide instead of one file at a
  /// time, so the wall-clock cost of scanning a folder with tens of thousands
  /// of files is dominated by per-file I/O latency in parallel rather than in
  /// series (this matters most on Android, where each file read on
  /// MANAGE_EXTERNAL_STORAGE-backed paths carries real per-call overhead).
  /// Results still stream out incrementally, so callers can render matches as
  /// they arrive instead of waiting for the whole folder to finish.
  Stream<FloatingNoteEntry> streamFloatingNotes(String folder, {int concurrency = 32}) async* {
    final dir = Directory(folder);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return;
    }

    final jsonFiles = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        jsonFiles.add(entity);
      }
    }

    for (var i = 0; i < jsonFiles.length; i += concurrency) {
      final batch = jsonFiles.skip(i).take(concurrency);
      final results = await Future.wait(batch.map(_readFloatingEntry));
      for (final entry in results) {
        if (entry != null) yield entry;
      }
    }
  }

  Future<FloatingNoteEntry?> _readFloatingEntry(File file) async {
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) return null;
      final primaryType = data['primaryType'];
      final isUnknown = primaryType == 'unknown';
      final isTriagedScratchpad = primaryType == 'scratchpad' && data['triaged'] == 'true';
      if (!isUnknown && !isTriagedScratchpad) return null;
      return FloatingNoteEntry(
        filename: p.basename(file.path),
        title: data['title'] as String? ?? '',
        body: data['body'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  Future<NoteFile> readJsonFile(String folder, String filename) async {
    final file = _notePath(folder, filename);
    return jsonDecode(await file.readAsString()) as NoteFile;
  }

  Future<void> writeJsonFile(
    String folder,
    String filename,
    NoteFile content,
  ) async {
    final file = _notePath(folder, filename);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(content));
  }

  Future<void> deleteJsonFile(String folder, String filename) async {
    final file = _notePath(folder, filename);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Creates a new `primaryType: "unknown"` note from the Quick Add flow.
  /// The filename is a slug of the title plus a random 6-hex-digit suffix,
  /// so titles can repeat without colliding on disk.
  Future<String> createQuickNote(
    String folder, {
    required String title,
    String body = '',
  }) async {
    final filename = '${_slugify(title)}-${_randomHex6()}.json';
    await writeJsonFile(folder, filename, {
      'primaryType': 'unknown',
      'title': title,
      'body': body,
    });
    return filename;
  }

  String _slugify(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'note' : slug;
  }

  String _randomHex6() {
    final value = Random().nextInt(0x1000000);
    return value.toRadixString(16).padLeft(6, '0');
  }
}
