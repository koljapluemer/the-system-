import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_system/state/netting_notifier.dart';
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
    tempDir = await Directory.systemTemp.createTemp('netting_notifier_test_');
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

  /// Triggers the notifier's build(), waits for the index to resolve, then
  /// flushes the event loop (a real Timer, not just a microtask, so any
  /// chain of awaits started by build()'s scheduled _loadNext has settled)
  /// before returning the resulting state.
  Future<NettingState> settle() async {
    container.read(nettingProvider);
    await container.read(noteIndexProvider.future);
    await Future<void>.delayed(Duration.zero);
    return container.read(nettingProvider);
  }

  test('picks the only eligible ifThen/description note with an unanswered question', () async {
    await writeFixture('a.json', {'primaryType': 'ifThen', 'title': 'A', 'content': 'if X then Y'});
    await writeFixture('b.json', {'primaryType': 'scratchpad', 'title': 'B', 'body': 'not eligible'});

    final state = await settle();
    expect(state.loading, isFalse);
    expect(state.currentFilename, 'a.json');
    expect(nettingQuestions, contains(state.currentQuestion));
  });

  test('save persists the answer under the asked question and advances', () async {
    await writeFixture('a.json', {'primaryType': 'ifThen', 'title': 'A', 'content': 'if X then Y'});
    final state = await settle();
    final question = state.currentQuestion!;

    await container.read(nettingProvider.notifier).save('my answer');

    final index = container.read(noteIndexProvider).value!;
    expect(index.entries['a.json']?['questions'], {question: 'my answer'});
  });

  test('markNotRelevant persists false under the asked question and advances', () async {
    await writeFixture('a.json', {'primaryType': 'description', 'title': 'A', 'content': 'shape'});
    final state = await settle();
    final question = state.currentQuestion!;

    await container.read(nettingProvider.notifier).markNotRelevant();

    final index = container.read(noteIndexProvider).value!;
    expect(index.entries['a.json']?['questions'], {question: false});
  });

  test('defer advances without writing anything', () async {
    await writeFixture('a.json', {'primaryType': 'ifThen', 'title': 'A', 'content': 'if X then Y'});
    await settle();

    await container.read(nettingProvider.notifier).defer();

    final index = container.read(noteIndexProvider).value!;
    expect(index.entries['a.json']?['questions'], isNull);
  });

  test('a note with every question already answered drops out of the pool', () async {
    final answered = {for (final q in nettingQuestions) q: 'done'};
    await writeFixture('a.json', {
      'primaryType': 'ifThen',
      'title': 'A',
      'content': 'if X then Y',
      'questions': answered,
    });

    final state = await settle();
    expect(state.loading, isFalse);
    expect(state.currentNote, isNull);
  });

  test('a note where every question is marked not relevant drops out of the pool', () async {
    final skipped = {for (final q in nettingQuestions) q: false};
    await writeFixture('a.json', {
      'primaryType': 'description',
      'title': 'A',
      'content': 'shape',
      'questions': skipped,
    });

    final state = await settle();
    expect(state.loading, isFalse);
    expect(state.currentNote, isNull);
  });

  test('no eligible notes at all leaves the empty state', () async {
    await writeFixture('a.json', {'primaryType': 'scratchpad', 'title': 'A', 'body': 'not eligible'});

    final state = await settle();
    expect(state.loading, isFalse);
    expect(state.currentNote, isNull);
  });
}
