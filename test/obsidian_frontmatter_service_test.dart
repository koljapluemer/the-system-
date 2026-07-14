import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/services/obsidian_frontmatter_service.dart';

void main() {
  const service = ObsidianFrontmatterService();

  group('parse', () {
    test('parses nested Obsidian frontmatter into a JSON-compatible map', () {
      final result = service.parse('''
aliases:
created-at: 2025-06-08
q:
  template: misc
  due: 2025-02-06T02:00:00.000Z
  seen: 2025-02-05T08:36:05.427Z
see-you-again:
  sometimes: iterate
zk-id: "263"
''');
      expect(result, {
        'aliases': null,
        'created-at': '2025-06-08',
        'q': {
          'template': 'misc',
          'due': '2025-02-06T02:00:00.000Z',
          'seen': '2025-02-05T08:36:05.427Z',
        },
        'see-you-again': {'sometimes': 'iterate'},
        'zk-id': '263',
      });
    });

    test('strips leading and trailing --- delimiters', () {
      final result = service.parse('''
---
title: Some Note
tags:
  - one
  - two
---
''');
      expect(result, {
        'title': 'Some Note',
        'tags': ['one', 'two'],
      });
    });

    test('returns an empty map for blank input', () {
      expect(service.parse(''), {});
      expect(service.parse('   \n  '), {});
    });

    test('throws FormatException for invalid YAML', () {
      expect(() => service.parse('key: ["unclosed'), throwsFormatException);
    });

    test('throws FormatException when the top level is not a mapping', () {
      expect(() => service.parse('- one\n- two'), throwsFormatException);
    });
  });
}
