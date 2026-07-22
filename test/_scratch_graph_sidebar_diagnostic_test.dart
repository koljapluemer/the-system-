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

Future<void> pumpUntilSettled(WidgetTester tester, {int maxPumps = 30}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (!tester.binding.hasScheduledFrame) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

final _index = NoteIndex(entries: {
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
  'lonely.json': {'primaryType': 'gestalt', 'title': 'Lonely', 'rels': []},
});

void main() {
  testWidgets('wide layout shows an inline sidebar and can re-focus via search', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteIndexProvider.overrideWith(() => _FixedIndexNotifier(_index))],
        child: const MaterialApp(home: GraphViewScreen()),
      ),
    );
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('Search notes'), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);

    await tester.enterText(find.byType(TextField), 'lonely');
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Lonely'), findsWidgets);

    await tester.tap(find.text('Lonely').last);
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Centered on: Lonely'), findsOneWidget);
    expect(find.text('No relationships found'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('narrow layout puts the sidebar in an endDrawer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteIndexProvider.overrideWith(() => _FixedIndexNotifier(_index))],
        child: const MaterialApp(home: GraphViewScreen()),
      ),
    );
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('Search notes'), findsNothing);

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openEndDrawer();
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Search notes'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'b');
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('B').last);
    await pumpUntilSettled(tester);
    expect(tester.takeException(), isNull);
    expect(scaffoldState.isEndDrawerOpen, isFalse);
    expect(find.text('Centered on: B'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
