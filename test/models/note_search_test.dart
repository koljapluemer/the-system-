import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_file.dart';
import 'package:the_system/models/note_search.dart';

void main() {
  final entries = <String, NoteFile>{
    'skepticism.json': {'primaryType': 'gestalt', 'title': 'Skepticism'},
    'other-gestalt.json': {'primaryType': 'gestalt', 'title': 'Completely unrelated title'},
    'source-note.json': {'primaryType': 'source', 'title': 'Skepticism'},
    'aliased.json': {
      'primaryType': 'context',
      'title': 'Something else entirely',
      'aliases': ['Skepticism'],
    },
  };

  test('exact title match ranks first', () {
    final matches = findSimilarNotes(
      entries,
      query: 'Skepticism',
      allowedPrimaryTypes: ['gestalt', 'source', 'context'],
    );

    expect(matches.first.filename, 'skepticism.json');
  });

  test('tolerates a typo via edit-distance similarity', () {
    final matches = findSimilarNotes(
      entries,
      query: 'Scepticism',
      allowedPrimaryTypes: ['gestalt'],
    );

    expect(matches.map((m) => m.filename), contains('skepticism.json'));
  });

  test('matches on aliases, not just title', () {
    final matches = findSimilarNotes(
      entries,
      query: 'Skepticism',
      allowedPrimaryTypes: ['context'],
    );

    expect(matches.map((m) => m.filename), contains('aliased.json'));
  });

  test('respects allowedPrimaryTypes', () {
    final matches = findSimilarNotes(
      entries,
      query: 'Skepticism',
      allowedPrimaryTypes: ['gestalt'],
    );

    expect(matches.map((m) => m.filename), isNot(contains('source-note.json')));
  });

  test('unrelated titles are excluded', () {
    final matches = findSimilarNotes(
      entries,
      query: 'Skepticism',
      allowedPrimaryTypes: ['gestalt'],
    );

    expect(matches.map((m) => m.filename), isNot(contains('other-gestalt.json')));
  });

  test('respects limit', () {
    final manyEntries = <String, NoteFile>{
      for (var i = 0; i < 10; i++) 'note-$i.json': {'primaryType': 'gestalt', 'title': 'Topic $i'},
    };

    final matches = findSimilarNotes(
      manyEntries,
      query: 'Topic',
      allowedPrimaryTypes: ['gestalt'],
      limit: 3,
    );

    expect(matches.length, 3);
  });

  test('empty query returns no matches', () {
    final matches = findSimilarNotes(entries, query: '', allowedPrimaryTypes: ['gestalt']);
    expect(matches, isEmpty);
  });
}
