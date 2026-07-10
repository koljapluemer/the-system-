import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_system/state/note_index_notifier.dart';
import 'package:the_system/state/providers.dart';

/// Returns a fixed folder path immediately, so tests don't need a real
/// SharedPreferences platform channel.
class _FixedFolderNotifier extends DataFolderNotifier {
  final String folder;
  _FixedFolderNotifier(this.folder);

  @override
  Future<String?> build() async => folder;
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('note_index_notifier_test_');
    container = ProviderContainer(
      overrides: [
        dataFolderProvider.overrideWith(() => _FixedFolderNotifier(tempDir.path)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> writeFixture(String filename, Map<String, dynamic> content) async {
    await File('${tempDir.path}/$filename').writeAsString(jsonEncode(content));
  }

  test('build scans the folder into entries and unparsable', () async {
    await writeFixture('a.json', {'primaryType': 'scratchpad', 'title': 'A'});
    await File('${tempDir.path}/broken.json').writeAsString('{not json');

    final index = await container.read(noteIndexProvider.future);
    expect(index.entries['a.json'], {'primaryType': 'scratchpad', 'title': 'A'});
    expect(index.unparsable, contains('broken.json'));
  });

  test('write updates both the in-memory entry and the file on disk', () async {
    await container.read(noteIndexProvider.future);
    await container
        .read(noteIndexProvider.notifier)
        .write('new.json', {'primaryType': 'scratchpad', 'title': 'New'});

    final index = container.read(noteIndexProvider).value!;
    expect(index.entries['new.json'], {'primaryType': 'scratchpad', 'title': 'New'});

    final onDisk = jsonDecode(await File('${tempDir.path}/new.json').readAsString());
    expect(onDisk['title'], 'New');
  });

  test('delete removes both the in-memory entry and the file on disk', () async {
    await writeFixture('gone.json', {'primaryType': 'scratchpad', 'title': 'Gone'});
    await container.read(noteIndexProvider.future);

    await container.read(noteIndexProvider.notifier).delete('gone.json');

    final index = container.read(noteIndexProvider).value!;
    expect(index.entries.containsKey('gone.json'), isFalse);
    expect(await File('${tempDir.path}/gone.json').exists(), isFalse);
  });

  test('createHypothesis adds an ACTIVE hypothesis with empty sections', () async {
    await container.read(noteIndexProvider.future);

    final filename =
        await container.read(noteIndexProvider.notifier).createHypothesis(title: 'My Hypothesis');

    final index = container.read(noteIndexProvider).value!;
    expect(index.entries[filename]?['primaryType'], 'hypothesis');
    expect(index.entries[filename]?['title'], 'My Hypothesis');
    expect(index.entries[filename]?['status'], 'ACTIVE');
    expect(index.entries[filename]?['context'], <String>[]);
    expect(index.entries[filename]?['experiment'], <String>[]);
    expect(index.entries[filename]?['notes'], <String>[]);
    expect(index.entries[filename]?['findings'], <String>[]);

    final onDisk = jsonDecode(await File('${tempDir.path}/$filename').readAsString());
    expect(onDisk['status'], 'ACTIVE');
  });
}
