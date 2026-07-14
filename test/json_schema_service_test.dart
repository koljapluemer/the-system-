import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_index.dart';
import 'package:the_system/services/json_schema_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = JsonSchemaService();

  group('findInvalid', () {
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

    test('accepts a well-formed source note with a valid secondaryType', () async {
      final index = NoteIndex(entries: {
        'bk.json': {'primaryType': 'source', 'title': 'Some Book', 'secondaryType': 'book'},
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('bk.json')));
    });

    test('flags a source note with an invalid secondaryType value', () async {
      final index = NoteIndex(entries: {
        'bk.json': {'primaryType': 'source', 'title': 'Some Book', 'secondaryType': 'ebook'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('bk.json'));
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

    test('accepts a well-formed hypothesis note with populated sections', () async {
      final index = NoteIndex(entries: {
        'g.json': {
          'primaryType': 'hypothesis',
          'title': 'G',
          'secondaryType': 'active',
          'context': ['some context'],
          'experiment': ['do the thing'],
          'notes': ['a note'],
          'findings': ['a finding'],
        },
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('g.json')));
    });

    test('accepts a well-formed hypothesis note with empty sections', () async {
      final index = NoteIndex(entries: {
        'h.json': {
          'primaryType': 'hypothesis',
          'title': 'H',
          'secondaryType': 'active',
          'context': <String>[],
          'experiment': <String>[],
          'notes': <String>[],
          'findings': <String>[],
        },
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('h.json')));
    });

    test('accepts a hypothesis note with no secondaryType (legacy status field retired)', () async {
      final index = NoteIndex(entries: {
        'h2.json': {'primaryType': 'hypothesis', 'title': 'H2'},
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('h2.json')));
    });

    test('flags a legacy hypothesis note still carrying the retired status field', () async {
      final index = NoteIndex(entries: {
        'legacy.json': {'primaryType': 'hypothesis', 'title': 'Legacy', 'status': 'ACTIVE'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('legacy.json'));
    });

    test('flags a hypothesis note with an invalid secondaryType value', () async {
      final index = NoteIndex(entries: {
        'i.json': {'primaryType': 'hypothesis', 'title': 'I', 'secondaryType': 'MAYBE'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('i.json'));
    });

    test('flags a hypothesis note missing the required title field', () async {
      final index = NoteIndex(entries: {
        'j.json': {'primaryType': 'hypothesis', 'secondaryType': 'active'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('j.json'));
    });

    test('flags a hypothesis note with a non-string array element', () async {
      final index = NoteIndex(entries: {
        'k.json': {
          'primaryType': 'hypothesis',
          'title': 'K',
          'secondaryType': 'active',
          'context': [1, 2],
        },
      });
      final result = await service.findInvalid(index);
      expect(result, contains('k.json'));
    });

    test('accepts a well-formed milestone note with a valid secondaryType', () async {
      final index = NoteIndex(entries: {
        'm.json': {'primaryType': 'milestone', 'title': 'M', 'content': 'ship it', 'secondaryType': 'open'},
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('m.json')));
    });

    test('flags a milestone note with an invalid secondaryType value', () async {
      final index = NoteIndex(entries: {
        'n.json': {'primaryType': 'milestone', 'title': 'N', 'secondaryType': 'somewhat'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('n.json'));
    });

    test('flags a scratchpad note missing the required body field', () async {
      final index = NoteIndex(entries: {
        'd.json': {'primaryType': 'scratchpad', 'title': 'D'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('d.json'));
    });

    test('accepts a well-formed log note', () async {
      final index = NoteIndex(entries: {
        'log1.json': {
          'primaryType': 'log',
          'title': 'Checked in',
          'content': 'still going',
          'createdAt': '2026-07-13T10:30:00.000',
          'rels': [
            ['seeAlso', 'other.json'],
          ],
        },
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('log1.json')));
    });

    test('flags a log note missing the required createdAt field', () async {
      final index = NoteIndex(entries: {
        'log2.json': {'primaryType': 'log', 'title': 'Checked in'},
      });
      final result = await service.findInvalid(index);
      expect(result, contains('log2.json'));
    });

    test('accepts a well-formed new flashcard note with no fsrs data yet', () async {
      final index = NoteIndex(entries: {
        'fc1.json': {
          'primaryType': 'flashcard',
          'title': 'Capital of France',
          'front': 'What is the capital of France?',
          'back': 'Paris',
        },
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('fc1.json')));
    });

    test('accepts a well-formed flashcard note with fsrs learning data', () async {
      final index = NoteIndex(entries: {
        'fc2.json': {
          'primaryType': 'flashcard',
          'title': 'Capital of Japan',
          'front': 'What is the capital of Japan?',
          'back': 'Tokyo',
          'fsrs': {
            'cardId': 1,
            'state': 2,
            'step': null,
            'stability': 5.2,
            'difficulty': 4.1,
            'due': '2026-07-20T10:30:00.000Z',
            'lastReview': '2026-07-14T10:30:00.000Z',
          },
        },
      });
      final result = await service.findInvalid(index);
      expect(result, isNot(contains('fc2.json')));
    });

    test('flags a flashcard note missing the required back field', () async {
      final index = NoteIndex(entries: {
        'fc3.json': {
          'primaryType': 'flashcard',
          'title': 'Incomplete',
          'front': 'Only a front',
        },
      });
      final result = await service.findInvalid(index);
      expect(result, contains('fc3.json'));
    });

    test('flags a flashcard note with unexpected extra fields', () async {
      final index = NoteIndex(entries: {
        'fc4.json': {
          'primaryType': 'flashcard',
          'title': 'Extra',
          'front': 'front',
          'back': 'back',
          'unexpected': 'field',
        },
      });
      final result = await service.findInvalid(index);
      expect(result, contains('fc4.json'));
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
          'primaryType': 'scratchpad',
          'title': 'F',
          'body': 'body text',
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
