import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;

/// Validates the flat note JSON files in the data folder against
/// `assets/note_schema.json`, the schema for the note shapes this app
/// currently reads and writes (see NotesService).
class JsonSchemaService {
  const JsonSchemaService();

  static const schemaAssetPath = 'assets/note_schema.json';

  Future<JsonSchema> _loadSchema() async {
    final raw = await rootBundle.loadString(schemaAssetPath);
    return JsonSchema.create(jsonDecode(raw));
  }

  /// Scans [folder] for `.json` files that either aren't valid JSON or don't
  /// conform to the note schema. Returns their filenames, sorted.
  Future<List<String>> findInvalidJsonFiles(String folder) async {
    final schema = await _loadSchema();
    final dir = Directory(folder);
    if (!await dir.exists()) return const [];

    final invalid = <String>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final filename = p.basename(entity.path);
      try {
        final data = jsonDecode(await entity.readAsString());
        if (!schema.validate(data).isValid) {
          invalid.add(filename);
        }
      } catch (_) {
        invalid.add(filename);
      }
    }
    invalid.sort();
    return invalid;
  }
}
