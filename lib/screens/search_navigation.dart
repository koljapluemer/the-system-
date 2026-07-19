import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/recent_history_notifier.dart';
import 'search_screen.dart';

/// Records [query] (trimmed) as a `.search` entry in [recentHistoryProvider],
/// keyed on the query string itself. Shared by [pushSearch] (reopening a past
/// search from a recent-history chip) and [SearchScreen]'s submit handler, so
/// both go through identical logic. No-ops for an empty/whitespace query.
void recordSearch(WidgetRef ref, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return;
  ref
      .read(recentHistoryProvider.notifier)
      .record(RecentEntry(kind: RecentEntryKind.search, id: trimmed, label: trimmed));
}

/// Pushes [SearchScreen] prefilled with [query] and records it in
/// [recentHistoryProvider] — the chokepoint for re-opening a past search from
/// a `.search` chip in [RecentBar]. Mirrors [pushFlow]/[pushNoteEditor]'s role
/// for their respective entry kinds.
void pushSearch(BuildContext context, WidgetRef ref, String query) {
  recordSearch(ref, query);
  Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: query)));
}
