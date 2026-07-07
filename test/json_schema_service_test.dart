import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_index.dart';
import 'package:the_system/services/json_schema_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = JsonSchemaService();

  group('findInvalid', () {
    test('accepts a well-formed unknown note', () async {
      final index = NoteIndex(entries: {
        'a.json': {'primaryType': 'unknown', 'title': 'A'},
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('a.json')));
    });

    test('accepts a well-formed scratchpad note with rels and triaged', () async {
      final index = NoteIndex(entries: {
        'b.json': {
          'primaryType': 'scratchpad',
          'title': 'B',
          'body': 'body text',
          'rels': [
            ['source', 'other.json'],
          ],
          'triaged': 'true',
        },
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('b.json')));
    });

    test('accepts a well-formed book note', () async {
      final index = NoteIndex(entries: {
        'bk.json': {'primaryType': 'book', 'title': 'Some Book'},
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('bk.json')));
    });

    test('accepts a well-formed art note', () async {
      final index = NoteIndex(entries: {
        'c.json': {
          'primaryType': 'art',
          'title': 'C',
          'content': 'some content',
          'image': 'c.webp',
        },
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('c.json')));
    });

    test('flags a scratchpad note missing the required body field', () async {
      final index = NoteIndex(entries: {
        'd.json': {'primaryType': 'scratchpad', 'title': 'D'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('d.json'));
    });

    test('flags an unknown primaryType', () async {
      final index = NoteIndex(entries: {
        'e.json': {'primaryType': 'contact', 'title': 'E'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('e.json'));
    });

    test('flags unparsable JSON', () async {
      final index = NoteIndex(unparsable: {'broken.json'});
      final result = await service.findInvalid(index);
      expect(result, contains('broken.json'));
    });

    test('flags unexpected extra fields', () async {
      final index = NoteIndex(entries: {
        'f.json': {
          'primaryType': 'unknown',
          'title': 'F',
          'unexpected': 'field',
        },
      });
      final result = await service.findInvalid(index);
      expect(result, contains('f.json'));
    });

    test('empty index has no invalid files', () async {
      final result = await service.findInvalid(const NoteIndex());
      expect(result, isEmpty);
    });

    test('sorts results', () async {
      final index = NoteIndex(entries: {
        'z.json': {'primaryType': 'contact'},
        'a.json': {'primaryType': 'contact'},
      });
      final result = await service.findInvalid(index);
      expect(result, ['a.json', 'z.json']);
    });
  });
}
