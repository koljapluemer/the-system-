import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/services/notes_service.dart';

void main() {
  late Directory tempDir;
  const service = NotesService();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('notes_service_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> writeFixture(String filename, Map<String, dynamic> content) async {
    await File('${tempDir.path}/$filename').writeAsString(jsonEncode(content));
  }

  group('scanNotes', () {
    test('yields decoded content for a well-formed note', () async {
      await writeFixture('a.json', {'primaryType': 'scratchpad', 'title': 'A'});
      final result = await service.scanNotes(tempDir.path).toList();
      final entry = result.firstWhere((r) => r.filename == 'a.json');
      expect(entry.data, {'primaryType': 'scratchpad', 'title': 'A'});
    });

    test('yields every file regardless of primaryType', () async {
      await writeFixture('b.json', {'primaryType': 'contact'});
      final result = await service.scanNotes(tempDir.path).toList();
      expect(result.map((r) => r.filename), contains('b.json'));
    });

    test('yields null data for unparsable json files, without throwing', () async {
      await File('${tempDir.path}/broken.json').writeAsString('{not json');
      final result = await service.scanNotes(tempDir.path).toList();
      final entry = result.firstWhere((r) => r.filename == 'broken.json');
      expect(entry.data, isNull);
    });

    test('yields null data for json that decodes to a non-object', () async {
      await File('${tempDir.path}/list.json').writeAsString('[1, 2, 3]');
      final result = await service.scanNotes(tempDir.path).toList();
      final entry = result.firstWhere((r) => r.filename == 'list.json');
      expect(entry.data, isNull);
    });

    test('ignores non-json files', () async {
      await File('${tempDir.path}/notes.txt').writeAsString('hello');
      final result = await service.scanNotes(tempDir.path).toList();
      expect(result.map((r) => r.filename), isNot(contains('notes.txt')));
    });

    test('finds every file across multiple concurrency batches, none dropped', () async {
      const total = 90;
      for (var i = 0; i < total; i++) {
        await writeFixture('n$i.json', {'primaryType': 'unknown', 'title': 'N$i'});
      }
      // concurrency (32) doesn't evenly divide total, exercising a partial final batch too.
      final result = await service.scanNotes(tempDir.path, concurrency: 32).toList();
      expect(result.length, total);
      expect(
        result.map((r) => r.filename).toSet(),
        {for (var i = 0; i < total; i++) 'n$i.json'},
      );
    });
  });

  group('writeJsonFile', () {
    test('writes triaged as the literal string "true", not a boolean', () async {
      await writeFixture('d.json', {'primaryType': 'scratchpad'});
      final note = await service.readJsonFile(tempDir.path, 'd.json');
      await service.writeJsonFile(tempDir.path, 'd.json', {...note, 'triaged': 'true'});

      final raw = await File('${tempDir.path}/d.json').readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['triaged'], 'true');
      expect(decoded['triaged'], isA<String>());
    });

    test('preserves the rels field untouched through a write', () async {
      final rels = [
        ['source', 'some-file.json'],
      ];
      await writeFixture('e.json', {'primaryType': 'scratchpad', 'rels': rels});
      final note = await service.readJsonFile(tempDir.path, 'e.json');
      await service.writeJsonFile(tempDir.path, 'e.json', {...note, 'triaged': 'true'});

      final reloaded = await service.readJsonFile(tempDir.path, 'e.json');
      expect(reloaded['rels'], [
        ['source', 'some-file.json'],
      ]);
    });
  });

  group('createQuickNote', () {
    test('writes primaryType "unknown" with title and body', () async {
      final filename = await service.createQuickNote(
        tempDir.path,
        title: 'My Title',
        body: 'some body',
      );
      final note = await service.readJsonFile(tempDir.path, filename);
      expect(note['primaryType'], 'unknown');
      expect(note['title'], 'My Title');
      expect(note['body'], 'some body');
    });

    test('slugifies the title and appends a 6-hex-digit suffix', () async {
      final filename = await service.createQuickNote(tempDir.path, title: 'Buy Milk!! 2%');
      expect(filename, matches(RegExp(r'^buy-milk-2-[0-9a-f]{6}\.json$')));
    });

    test('falls back to "note" when the title has no alphanumeric characters', () async {
      final filename = await service.createQuickNote(tempDir.path, title: '!!!');
      expect(filename, matches(RegExp(r'^note-[0-9a-f]{6}\.json$')));
    });

    test('defaults body to empty string when omitted', () async {
      final filename = await service.createQuickNote(tempDir.path, title: 'No Body');
      final note = await service.readJsonFile(tempDir.path, filename);
      expect(note['body'], '');
    });

    test('two notes with the same title get different filenames', () async {
      final a = await service.createQuickNote(tempDir.path, title: 'Same');
      final b = await service.createQuickNote(tempDir.path, title: 'Same');
      expect(a, isNot(b));
    });
  });

  group('deleteJsonFile', () {
    test('removes the file from disk', () async {
      await writeFixture('f.json', {'primaryType': 'scratchpad'});
      await service.deleteJsonFile(tempDir.path, 'f.json');
      expect(await File('${tempDir.path}/f.json').exists(), isFalse);
    });
  });

  group('filename traversal guard', () {
    test('rejects filenames containing ".."', () {
      expect(
        () => service.readJsonFile(tempDir.path, '../evil.json'),
        throwsArgumentError,
      );
    });

    test('rejects filenames containing "/"', () {
      expect(
        () => service.writeJsonFile(tempDir.path, 'sub/file.json', {}),
        throwsArgumentError,
      );
    });

    test(r'rejects filenames containing "\"', () {
      expect(
        () => service.deleteJsonFile(tempDir.path, r'a\b.json'),
        throwsArgumentError,
      );
    });
  });
}
