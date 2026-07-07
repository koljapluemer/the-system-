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
}
