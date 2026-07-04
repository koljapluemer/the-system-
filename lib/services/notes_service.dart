import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

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
}
