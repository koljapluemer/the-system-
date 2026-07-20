import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../models/note_type_spec.dart';
import '../screens/add_screen.dart';
import '../screens/flow_navigation.dart';
import '../screens/note_editor_navigation.dart';
import '../screens/search_navigation.dart';
import '../state/note_index_notifier.dart';
import '../state/recent_history_notifier.dart';

/// A home button plus a horizontally-scrolling row of chips for the most
/// recently opened notes and flows (see [recentHistoryProvider]) — not
/// literal nav breadcrumbs (it doesn't show a path/hierarchy), just quick
/// jump-back links. The home button is always shown; the chip row is empty
/// once history is empty (e.g. right after app start). Mounted once by
/// `_AppShell` as a sibling of the inner Navigator (see app.dart), so it
/// stays visible above every pushed screen rather than being embedded
/// per-screen.
class RecentBar extends ConsumerWidget {
  const RecentBar({super.key});

  static String _truncate(String label) =>
      label.length > 12 ? '${label.substring(0, 12)}…' : label;

  /// RecentBar sits outside the inner Navigator (a sibling, not a
  /// descendant — see app.dart), so pushing/popping with this widget's own
  /// context would find no Navigator ancestor. Use navigatorKey's context
  /// instead, which is a descendant of that Navigator.
  BuildContext? get _navContext => navigatorKey.currentContext;

  void _goHome() {
    final navContext = _navContext;
    if (navContext == null) return;
    Navigator.popUntil(navContext, (route) => route.isFirst);
  }

  void _openSearch(WidgetRef ref) {
    final navContext = _navContext;
    if (navContext == null) return;
    pushFlow(navContext, ref, 'search');
  }

  void _openAdd() {
    final navContext = _navContext;
    if (navContext == null) return;
    Navigator.push(navContext, MaterialPageRoute(builder: (_) => const AddScreen()));
  }

  void _open(WidgetRef ref, RecentEntry entry) {
    final navContext = _navContext;
    if (navContext == null) return;

    if (entry.kind == RecentEntryKind.flow) {
      pushFlow(navContext, ref, entry.id);
      return;
    }
    if (entry.kind == RecentEntryKind.search) {
      pushSearch(navContext, ref, entry.id);
      return;
    }

    final note = ref.read(noteIndexProvider).value?.entries[entry.id];
    if (note == null) return; // note was deleted since it was last opened
    final spec = noteTypeSpecs.firstWhere((s) => s.primaryType == note['primaryType']);
    pushNoteEditor(navContext, spec: spec, filename: entry.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentHistoryProvider);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: _goHome,
          ),
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(ref),
          ),
          IconButton(
            tooltip: 'Add',
            icon: const Icon(Icons.add),
            onPressed: _openAdd,
          ),
          if (recent.isNotEmpty)
            const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          if (recent.isNotEmpty)
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final entry = recent[i];
                  return ActionChip(
                    avatar: Icon(
                      switch (entry.kind) {
                        RecentEntryKind.flow => Icons.bolt_outlined,
                        RecentEntryKind.search => Icons.search,
                        RecentEntryKind.note => Icons.description_outlined,
                      },
                      size: 18,
                    ),
                    label: Text(_truncate(entry.label)),
                    onPressed: () => _open(ref, entry),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
