import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RecentEntryKind { note, flow, search }

/// One entry in the recent-history bar: a note (identified by filename), a
/// flow (identified by [FlowSpec.id]), or a search query (identified by the
/// query string itself — see `search_navigation.dart`).
class RecentEntry {
  final RecentEntryKind kind;
  final String id;
  final String label;

  const RecentEntry({required this.kind, required this.id, required this.label});

  /// Identity for dedup purposes — same kind/id is the same entry even if
  /// its label changed (e.g. a note was renamed) since it was last recorded.
  String get key => '${kind.name}:$id';
}

const maxRecentEntries = 8;

/// Most-recently-opened notes and flows, newest first, for the "recent" bar
/// (see RecentBar) — re-recording an already-present entry moves it to the
/// front and refreshes its label rather than adding a duplicate. In-memory
/// only, resetting on app restart, like every other provider in this app
/// (see SecondaryTypeFilterNotifier).
class RecentHistoryNotifier extends Notifier<List<RecentEntry>> {
  @override
  List<RecentEntry> build() => [];

  void record(RecentEntry entry) {
    state = [
      entry,
      ...state.where((e) => e.key != entry.key),
    ].take(maxRecentEntries).toList();
  }
}

final recentHistoryProvider =
    NotifierProvider<RecentHistoryNotifier, List<RecentEntry>>(RecentHistoryNotifier.new);
