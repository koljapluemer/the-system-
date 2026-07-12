import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_index.dart';

void main() {
  group('untriagedOfType', () {
    test('includes notes matching primaryType with no triaged field', () {
      final index = NoteIndex(entries: {
        'a.json': {'primaryType': 'scratchpad', 'title': 'A'},
      });
      expect(index.untriagedOfType('scratchpad'), contains('a.json'));
    });

    test('excludes notes already triaged "true"', () {
      final index = NoteIndex(entries: {
        'b.json': {'primaryType': 'scratchpad', 'triaged': 'true'},
      });
      expect(index.untriagedOfType('scratchpad'), isNot(contains('b.json')));
    });

    test('excludes notes with a different primaryType', () {
      final index = NoteIndex(entries: {
        'c.json': {'primaryType': 'art'},
      });
      expect(index.untriagedOfType('scratchpad'), isNot(contains('c.json')));
    });
  });

  group('summariesOfType', () {
    test('includes notes matching primaryType regardless of triaged status', () {
      final index = NoteIndex(entries: {
        's1.json': {'primaryType': 'scratchpad', 'triaged': 'true', 'title': 'S1'},
        's2.json': {'primaryType': 'scratchpad', 'title': 'S2'},
      });
      final filenames = index.summariesOfType('scratchpad').map((s) => s.filename);
      expect(filenames, containsAll(['s1.json', 's2.json']));
    });

    test('excludes notes with a different primaryType', () {
      final index = NoteIndex(entries: {
        'd.json': {'primaryType': 'entity', 'title': 'D'},
      });
      expect(index.summariesOfType('scratchpad'), isEmpty);
    });

    test('carries filename and title through', () {
      final index = NoteIndex(entries: {
        's.json': {'primaryType': 'scratchpad', 'title': 'Some Title'},
      });
      final summary = index.summariesOfType('scratchpad').first;
      expect(summary.filename, 's.json');
      expect(summary.title, 'Some Title');
    });

    test('defaults title to empty string when missing', () {
      final index = NoteIndex(entries: {
        'notitle.json': {'primaryType': 'scratchpad'},
      });
      expect(index.summariesOfType('scratchpad').first.title, '');
    });

    test('carries secondaryType through', () {
      final index = NoteIndex(entries: {
        'h1.json': {'primaryType': 'hypothesis', 'title': 'H1', 'secondaryType': 'active'},
      });
      expect(index.summariesOfType('hypothesis').first.secondaryType, 'active');
    });

    test('defaults secondaryType to null when missing', () {
      final index = NoteIndex(entries: {
        'h2.json': {'primaryType': 'hypothesis', 'title': 'H2'},
      });
      expect(index.summariesOfType('hypothesis').first.secondaryType, isNull);
    });
  });

  group('floatingPool', () {
    test('includes scratchpad notes only once triaged "true"', () {
      final index = NoteIndex(entries: {
        's1.json': {'primaryType': 'scratchpad', 'triaged': 'true', 'title': 'S1'},
        's2.json': {'primaryType': 'scratchpad', 'title': 'S2'},
      });
      final filenames = index.floatingPool().map((n) => n.filename);
      expect(filenames, contains('s1.json'));
      expect(filenames, isNot(contains('s2.json')));
    });

    test('excludes other primaryTypes', () {
      final index = NoteIndex(entries: {
        'c.json': {'primaryType': 'art', 'title': 'C'},
      });
      expect(index.floatingPool(), isEmpty);
    });

    test('carries title and body through', () {
      final index = NoteIndex(entries: {
        's2.json': {
          'primaryType': 'scratchpad',
          'triaged': 'true',
          'title': 'Title',
          'body': 'Body text',
        },
      });
      final entry = index.floatingPool().first;
      expect(entry.title, 'Title');
      expect(entry.body, 'Body text');
    });
  });
}
