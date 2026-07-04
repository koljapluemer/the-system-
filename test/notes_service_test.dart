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

  group('listScratchpadUntriaged', () {
    test('includes scratchpad notes with no triaged field', () async {
      await writeFixture('a.json', {'primaryType': 'scratchpad', 'title': 'A'});
      final result = await service.listScratchpadUntriaged(tempDir.path);
      expect(result, contains('a.json'));
    });

    test('excludes notes already triaged "true"', () async {
      await writeFixture('b.json', {'primaryType': 'scratchpad', 'triaged': 'true'});
      final result = await service.listScratchpadUntriaged(tempDir.path);
      expect(result, isNot(contains('b.json')));
    });

    test('excludes notes with a different primaryType', () async {
      await writeFixture('c.json', {'primaryType': 'contact'});
      final result = await service.listScratchpadUntriaged(tempDir.path);
      expect(result, isNot(contains('c.json')));
    });

    test('skips unparsable json files without throwing', () async {
      await File('${tempDir.path}/broken.json').writeAsString('{not json');
      await writeFixture('ok.json', {'primaryType': 'scratchpad'});
      final result = await service.listScratchpadUntriaged(tempDir.path);
      expect(result, ['ok.json']);
    });

    test('ignores non-json files', () async {
      await File('${tempDir.path}/notes.txt').writeAsString('hello');
      final result = await service.listScratchpadUntriaged(tempDir.path);
      expect(result, isEmpty);
    });
  });

  group('streamFloatingNotes', () {
    test('includes notes with primaryType "unknown"', () async {
      await writeFixture('u.json', {'primaryType': 'unknown', 'title': 'U', 'body': 'body'});
      final result = await service.streamFloatingNotes(tempDir.path).toList();
      expect(result.map((n) => n.filename), contains('u.json'));
    });

    test('includes scratchpad notes only once triaged "true"', () async {
      await writeFixture('s1.json', {'primaryType': 'scratchpad', 'triaged': 'true', 'title': 'S1'});
      await writeFixture('s2.json', {'primaryType': 'scratchpad', 'title': 'S2'});
      final result = await service.streamFloatingNotes(tempDir.path).toList();
      final filenames = result.map((n) => n.filename);
      expect(filenames, contains('s1.json'));
      expect(filenames, isNot(contains('s2.json')));
    });

    test('excludes other primaryTypes', () async {
      await writeFixture('c.json', {'primaryType': 'contact', 'title': 'C'});
      final result = await service.streamFloatingNotes(tempDir.path).toList();
      expect(result.map((n) => n.filename), isNot(contains('c.json')));
    });

    test('carries title and body through', () async {
      await writeFixture('u2.json', {'primaryType': 'unknown', 'title': 'Title', 'body': 'Body text'});
      final result = await service.streamFloatingNotes(tempDir.path).toList();
      final entry = result.firstWhere((n) => n.filename == 'u2.json');
      expect(entry.title, 'Title');
      expect(entry.body, 'Body text');
    });

    test('skips unparsable json files without throwing', () async {
      await File('${tempDir.path}/broken.json').writeAsString('{not json');
      await writeFixture('ok.json', {'primaryType': 'unknown'});
      final result = await service.streamFloatingNotes(tempDir.path).toList();
      expect(result.map((n) => n.filename), ['ok.json']);
    });

    test('finds every match across multiple concurrency batches, none dropped', () async {
      const total = 90;
      for (var i = 0; i < total; i++) {
        await writeFixture('n$i.json', {'primaryType': 'unknown', 'title': 'N$i'});
      }
      // concurrency (32) doesn't evenly divide total, exercising a partial final batch too.
      final result = await service.streamFloatingNotes(tempDir.path, concurrency: 32).toList();
      expect(result.length, total);
      expect(
        result.map((n) => n.filename).toSet(),
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
