import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_system/state/recent_history_notifier.dart';

void main() {
  test('starts empty', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(recentHistoryProvider), isEmpty);
  });

  test('record prepends new entries, most recent first', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(recentHistoryProvider.notifier);
    notifier.record(const RecentEntry(kind: RecentEntryKind.note, id: 'a.json', label: 'A'));
    notifier.record(const RecentEntry(kind: RecentEntryKind.flow, id: 'memorize', label: 'Memorize'));

    expect(container.read(recentHistoryProvider).map((e) => e.id), ['memorize', 'a.json']);
  });

  test('re-recording an existing entry moves it to the front instead of duplicating', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(recentHistoryProvider.notifier);
    notifier.record(const RecentEntry(kind: RecentEntryKind.note, id: 'a.json', label: 'A'));
    notifier.record(const RecentEntry(kind: RecentEntryKind.flow, id: 'memorize', label: 'Memorize'));
    notifier.record(const RecentEntry(kind: RecentEntryKind.note, id: 'a.json', label: 'A renamed'));

    final state = container.read(recentHistoryProvider);
    expect(state.map((e) => e.id), ['a.json', 'memorize']);
    expect(state.first.label, 'A renamed');
  });

  test('caps at maxRecentEntries, dropping the oldest', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(recentHistoryProvider.notifier);
    for (var i = 0; i < maxRecentEntries + 3; i++) {
      notifier.record(RecentEntry(kind: RecentEntryKind.note, id: '$i.json', label: '$i'));
    }

    final state = container.read(recentHistoryProvider);
    expect(state.length, maxRecentEntries);
    expect(state.first.id, '${maxRecentEntries + 2}.json');
  });
}
