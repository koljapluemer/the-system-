import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/services/json_schema_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const service = JsonSchemaService();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('json_schema_service_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> writeFixture(String filename, Object content) async {
    await File('${tempDir.path}/$filename').writeAsString(jsonEncode(content));
  }

  group('findInvalidJsonFiles', () {
    test('accepts a well-formed unknown note', () async {
      await writeFixture('a.json', {'primaryType': 'unknown', 'title': 'A'});
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, isNot(contains('a.json')));
    });

    test('accepts a well-formed scratchpad note with rels and triaged', () async {
      await writeFixture('b.json', {
        'primaryType': 'scratchpad',
        'title': 'B',
        'body': 'body text',
        'rels': [
          ['source', 'other.json'],
        ],
        'triaged': 'true',
      });
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, isNot(contains('b.json')));
    });

    test('accepts a well-formed book note', () async {
      await writeFixture('bk.json', {'primaryType': 'book', 'title': 'Some Book'});
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, isNot(contains('bk.json')));
    });

    test('accepts a well-formed art note', () async {
      await writeFixture('c.json', {
        'primaryType': 'art',
        'title': 'C',
        'content': 'some content',
        'image': 'c.webp',
      });
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, isNot(contains('c.json')));
    });

    test('flags a scratchpad note missing the required body field', () async {
      await writeFixture('d.json', {'primaryType': 'scratchpad', 'title': 'D'});
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, contains('d.json'));
    });

    test('flags an unknown primaryType', () async {
      await writeFixture('e.json', {'primaryType': 'contact', 'title': 'E'});
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, contains('e.json'));
    });

    test('flags unparsable JSON', () async {
      await File('${tempDir.path}/broken.json').writeAsString('{not json');
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, contains('broken.json'));
    });

    test('flags unexpected extra fields', () async {
      await writeFixture('f.json', {
        'primaryType': 'unknown',
        'title': 'F',
        'unexpected': 'field',
      });
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, contains('f.json'));
    });

    test('ignores non-json files', () async {
      await File('${tempDir.path}/notes.txt').writeAsString('hello');
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, isEmpty);
    });

    test('sorts results', () async {
      await writeFixture('z.json', {'primaryType': 'contact'});
      await writeFixture('a.json', {'primaryType': 'contact'});
      final result = await service.findInvalidJsonFiles(tempDir.path);
      expect(result, ['a.json', 'z.json']);
    });
  });
}
