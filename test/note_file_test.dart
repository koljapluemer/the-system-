import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_file.dart';

void main() {
  group('stringList', () {
    test('returns the list when the field is a well-formed string array', () {
      final NoteFile note = {'tags': ['a', 'b']};
      expect(note.stringList('tags'), ['a', 'b']);
    });

    test('returns an empty list when the key is missing', () {
      final NoteFile note = {};
      expect(note.stringList('tags'), <String>[]);
    });

    test('returns an empty list when the value is the wrong type', () {
      final NoteFile note = {'tags': 'not a list'};
      expect(note.stringList('tags'), <String>[]);
    });

    test('drops non-string elements from a mixed-type list', () {
      final NoteFile note = {'tags': ['a', 1, 'b', null]};
      expect(note.stringList('tags'), ['a', 'b']);
    });
  });

  group('relList', () {
    test('keeps 2-element entries', () {
      final NoteFile note = {
        'rels': [
          ['inspired by', 'a.json'],
        ],
      };
      expect(note.relList('rels'), [
        ['inspired by', 'a.json'],
      ]);
    });

    test('keeps 3-element entries', () {
      final NoteFile note = {
        'rels': [
          ['inspired by', 'a.json', 'backlink'],
        ],
      };
      expect(note.relList('rels'), [
        ['inspired by', 'a.json', 'backlink'],
      ]);
    });

    test('returns an empty list when the key is missing', () {
      final NoteFile note = {};
      expect(note.relList('rels'), <List<String>>[]);
    });

    test('drops entries with the wrong length', () {
      final NoteFile note = {
        'rels': [
          ['inspired by'],
          ['inspired by', 'a.json', 'backlink', 'extra'],
        ],
      };
      expect(note.relList('rels'), <List<String>>[]);
    });

    test('drops entries with a non-string element', () {
      final NoteFile note = {
        'rels': [
          ['inspired by', 1],
          [1, 'a.json', 'backlink'],
        ],
      };
      expect(note.relList('rels'), <List<String>>[]);
    });
  });
}
