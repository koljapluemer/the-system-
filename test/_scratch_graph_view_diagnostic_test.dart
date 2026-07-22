import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/models/note_index.dart';
import 'package:the_system/screens/graph_view_screen.dart';
import 'package:the_system/state/note_index_notifier.dart';

class _FixedIndexNotifier extends NoteIndexNotifier {
  final NoteIndex fixed;
  _FixedIndexNotifier(this.fixed);

  @override
  Future<NoteIndex> build() async => fixed;
}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxPumps = 20}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (!tester.binding.hasScheduledFrame) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('single isolated note does not crash', (tester) async {
    final index = NoteIndex(entries: {
      'lonely.json': {'primaryType': 'gestalt', 'title': 'Lonely', 'rels': []},
    });

    await tester.binding.setSurfaceSize(const Size(800, 600));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteIndexProvider.overrideWith(() => _FixedIndexNotifier(index))],
        child: const MaterialApp(home: GraphViewScreen()),
      ),
    );
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Lonely'), findsOneWidget);
    expect(find.text('No relationships found'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  }, timeout: const Timeout(Duration(seconds: 20)));

  testWidgets('connected notes still render and are tappable', (tester) async {
    final index = NoteIndex(entries: {
      'root.json': {
        'primaryType': 'gestalt',
        'title': 'Root',
        'rels': [
          ['relates', 'a.json', 'relates'],
        ],
      },
      'a.json': {
        'primaryType': 'gestalt',
        'title': 'A',
        'rels': [
          ['relates', 'root.json', 'relates'],
          ['relates', 'b.json', 'relates'],
        ],
      },
      'b.json': {
        'primaryType': 'gestalt',
        'title': 'B',
        'rels': [
          ['relates', 'a.json', 'relates'],
        ],
      },
    });

    await tester.binding.setSurfaceSize(const Size(800, 600));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteIndexProvider.overrideWith(() => _FixedIndexNotifier(index))],
        child: const MaterialApp(home: GraphViewScreen()),
      ),
    );
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('B'), findsOneWidget);
    await tester.tap(find.text('B'));
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
