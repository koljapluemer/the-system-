import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:json_schema/json_schema.dart';

import '../models/note_index.dart';

/// Validates the notes in a [NoteIndex] against `assets/note_schema.json`,
/// the schema for the note shapes this app currently reads and writes (see
/// NotesService).
class JsonSchemaService {
  const JsonSchemaService();

  static const schemaAssetPath = 'assets/note_schema.json';

  Future<JsonSchema> _loadSchema() async {
    final raw = await rootBundle.loadString(schemaAssetPath);
    return JsonSchema.create(jsonDecode(raw));
  }

  /// Returns the filenames in [index] that either aren't valid JSON objects
  /// or don't conform to the note schema, sorted.
  Future<List<String>> findInvalid(NoteIndex index) async {
    final schema = await _loadSchema();
    final invalid = <String>{...index.unparsable};
    for (final entry in index.entries.entries) {
      if (!schema.validate(entry.value).isValid) {
        invalid.add(entry.key);
      }
    }
    final sorted = invalid.toList()..sort();
    return sorted;
  }
}
