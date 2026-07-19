import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_file.dart';
import 'package:the_system/models/note_search_query.dart';

void main() {
  final entries = <String, NoteFile>{
    'skepticism.json': {'primaryType': 'gestalt', 'title': 'Skepticism', 'content': 'A short note.'},
    'other-gestalt.json': {
      'primaryType': 'gestalt',
      'title': 'Completely unrelated title',
      'content': 'Nothing relevant here.',
    },
    'body-match.json': {
      'primaryType': 'scratchpad',
      'title': 'Random title',
      'body': 'Mentions skepticism deep in the body text.',
    },
    'aliased.json': {
      'primaryType': 'context',
      'title': 'Something else entirely',
      'aliases': ['Skepticism'],
    },
  };

  test('matches on title, case-insensitively', () {
    final results = searchNotes(entries, 'skepticism');
    expect(results.map((r) => r.filename), contains('skepticism.json'));
  });

  test('matches on a non-title field (body/content), not just title', () {
    final results = searchNotes(entries, 'skepticism');
    expect(results.map((r) => r.filename), contains('body-match.json'));
  });

  test('matches inside a string-list field (aliases)', () {
    final results = searchNotes(entries, 'skepticism');
    expect(results.map((r) => r.filename), contains('aliased.json'));
  });

  test('does not match unrelated notes', () {
    final results = searchNotes(entries, 'skepticism');
    expect(results.map((r) => r.filename), isNot(contains('other-gestalt.json')));
  });

  test('empty query returns no results', () {
    expect(searchNotes(entries, ''), isEmpty);
    expect(searchNotes(entries, '   '), isEmpty);
  });

  test('results are sorted by title', () {
    final unsorted = <String, NoteFile>{
      'z.json': {'primaryType': 'gestalt', 'title': 'Zebra topic'},
      'a.json': {'primaryType': 'gestalt', 'title': 'Apple topic'},
      'm.json': {'primaryType': 'gestalt', 'title': 'Middle topic'},
    };

    final results = searchNotes(unsorted, 'topic');

    expect(results.map((r) => r.title), ['Apple topic', 'Middle topic', 'Zebra topic']);
  });
}
