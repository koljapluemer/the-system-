import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_file.dart';

void main() {
  group('stringList', () {
    test('returns the list when the field is a well-formed string array', () {
      final NoteFile note = {'context': ['a', 'b']};
      expect(note.stringList('context'), ['a', 'b']);
    });

    test('returns an empty list when the key is missing', () {
      final NoteFile note = {};
      expect(note.stringList('context'), <String>[]);
    });

    test('returns an empty list when the value is the wrong type', () {
      final NoteFile note = {'context': 'not a list'};
      expect(note.stringList('context'), <String>[]);
    });

    test('drops non-string elements from a mixed-type list', () {
      final NoteFile note = {'context': ['a', 1, 'b', null]};
      expect(note.stringList('context'), ['a', 'b']);
    });
  });

  group('questionsMap', () {
    test('returns the map when the field is well-formed', () {
      final NoteFile note = {
        'questions': {'Why must this be true?': 'Because of Z.', 'What is implied?': false},
      };
      expect(note.questionsMap, {'Why must this be true?': 'Because of Z.', 'What is implied?': false});
    });

    test('returns an empty map when the key is missing', () {
      final NoteFile note = {};
      expect(note.questionsMap, <String, dynamic>{});
    });

    test('returns an empty map when the value is the wrong type', () {
      final NoteFile note = {'questions': 'not a map'};
      expect(note.questionsMap, <String, dynamic>{});
    });

    test('drops entries whose value is neither a string nor false', () {
      final NoteFile note = {
        'questions': {
          'kept string': 'an answer',
          'kept false': false,
          'dropped true': true,
          'dropped object': {'nested': 'object'},
          'dropped null': null,
        },
      };
      expect(note.questionsMap, {'kept string': 'an answer', 'kept false': false});
    });
  });
}
