import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_file.dart';
import 'package:the_system/models/note_search.dart';

void main() {
  final entries = <String, NoteFile>{
    'skepticism.json': {'primaryType': 'story', 'title': 'Skepticism'},
    'other-story.json': {'primaryType': 'story', 'title': 'Completely unrelated title'},
    'project-note.json': {'primaryType': 'project', 'title': 'Skepticism'},
    'aliased.json': {
      'primaryType': 'question',
      'title': 'Something else entirely',
      'aliases': ['Skepticism'],
    },
  };
  final notes = normalizeNotes(entries);

  test('exact title match ranks first', () {
    final matches = findSimilarNotes(
      notes,
      query: 'Skepticism',
      allowedPrimaryTypes: ['story', 'project', 'question'],
    );

    expect(matches.first.filename, 'skepticism.json');
  });

  test('tolerates a typo via edit-distance similarity', () {
    final matches = findSimilarNotes(
      notes,
      query: 'Scepticism',
      allowedPrimaryTypes: ['story'],
    );

    expect(matches.map((m) => m.filename), contains('skepticism.json'));
  });

  test('matches on aliases, not just title', () {
    final matches = findSimilarNotes(
      notes,
      query: 'Skepticism',
      allowedPrimaryTypes: ['question'],
    );

    expect(matches.map((m) => m.filename), contains('aliased.json'));
  });

  test('respects allowedPrimaryTypes', () {
    final matches = findSimilarNotes(
      notes,
      query: 'Skepticism',
      allowedPrimaryTypes: ['story'],
    );

    expect(matches.map((m) => m.filename), isNot(contains('project-note.json')));
  });

  test('unrelated titles are excluded', () {
    final matches = findSimilarNotes(
      notes,
      query: 'Skepticism',
      allowedPrimaryTypes: ['story'],
    );

    expect(matches.map((m) => m.filename), isNot(contains('other-story.json')));
  });

  test('respects limit', () {
    final manyEntries = <String, NoteFile>{
      for (var i = 0; i < 10; i++) 'note-$i.json': {'primaryType': 'story', 'title': 'Topic $i'},
    };

    final matches = findSimilarNotes(
      normalizeNotes(manyEntries),
      query: 'Topic',
      allowedPrimaryTypes: ['story'],
      limit: 3,
    );

    expect(matches.length, 3);
  });

  test('empty query returns no matches', () {
    final matches = findSimilarNotes(notes, query: '', allowedPrimaryTypes: ['story']);
    expect(matches, isEmpty);
  });
}
