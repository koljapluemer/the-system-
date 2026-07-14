import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_type_spec.dart';
import '../screens/flow_navigation.dart';
import '../screens/note_editor_navigation.dart';
import '../state/note_index_notifier.dart';
import '../state/recent_history_notifier.dart';

/// A horizontally-scrolling row of chips for the most recently opened notes
/// and flows (see [recentHistoryProvider]) — not literal nav breadcrumbs
/// (it doesn't show a path/hierarchy), just quick jump-back links. Renders
/// nothing once history is empty (e.g. right after app start).
class RecentBar extends ConsumerWidget {
  const RecentBar({super.key});

  void _open(BuildContext context, WidgetRef ref, RecentEntry entry) {
    if (entry.kind == RecentEntryKind.flow) {
      pushFlow(context, ref, entry.id);
      return;
    }

    final note = ref.read(noteIndexProvider).value?.entries[entry.id];
    if (note == null) return; // note was deleted since it was last opened
    final spec = noteTypeSpecs.firstWhere((s) => s.primaryType == note['primaryType']);
    pushNoteEditor(context, spec: spec, filename: entry.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentHistoryProvider);
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final entry = recent[i];
          return ActionChip(
            avatar: Icon(
              entry.kind == RecentEntryKind.flow ? Icons.bolt_outlined : Icons.description_outlined,
              size: 18,
            ),
            label: Text(entry.label),
            onPressed: () => _open(context, ref, entry),
          );
        },
      ),
    );
  }
}
