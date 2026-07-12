import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_summary.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import '../state/secondary_type_session.dart';
import '../widgets/secondary_type_filter_bar.dart';
import '../widgets/undo_snackbar.dart';
import 'add_screen.dart';
import 'note_editor_navigation.dart';

/// Lists every note of [spec]'s primaryType. Tapping a note opens it for
/// editing; a trailing delete action removes it; a FAB offers a "new note"
/// action. When [spec.secondaryTypes] is non-empty, a [SecondaryTypeFilterBar]
/// lets the user show/hide notes by secondaryType (session-only — see
/// [secondaryTypeFilterProvider]); notes with no secondaryType set are always
/// shown regardless of the filter. Reacts automatically to the shared note
/// index, including changes made from other screens (e.g. Triage or the edit
/// form) — no manual reload.
class NoteTypeListScreen extends ConsumerWidget {
  final NoteTypeSpec spec;

  const NoteTypeListScreen({super.key, required this.spec});

  void _edit(BuildContext context, NoteSummary summary) {
    pushNoteEditor(context, spec: spec, filename: summary.filename);
  }

  void _create(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddScreen(
          allowedTypes: [spec.primaryType],
          appBarTitle: 'New ${spec.label}',
          showBackButton: true,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, NoteSummary summary) async {
    final indexNotifier = ref.read(noteIndexProvider.notifier);
    final note = ref.read(noteIndexProvider).value?.entries[summary.filename];
    await indexNotifier.delete(summary.filename);
    final label = summary.title.isEmpty ? summary.filename : summary.title;
    if (context.mounted && note != null) {
      showUndoSnackBar(
        context,
        message: 'Deleted "$label"',
        onUndo: () => indexNotifier.write(summary.filename, note),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncIndex = ref.watch(noteIndexProvider);
    final hasSecondaryTypes = spec.secondaryTypes.isNotEmpty;
    ref.watch(secondaryTypeFilterProvider);
    final visible = hasSecondaryTypes
        ? ref.read(secondaryTypeFilterProvider.notifier).visibleFor(spec)
        : const <String>{};
    return Scaffold(
      appBar: AppBar(title: Text(spec.label)),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New ${spec.label}',
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (hasSecondaryTypes)
            SecondaryTypeFilterBar(
              secondaryTypes: spec.secondaryTypes,
              visible: visible,
              onChanged: (updated) => ref
                  .read(secondaryTypeFilterProvider.notifier)
                  .setVisible(spec.primaryType, updated),
            ),
          Expanded(
            child: asyncIndex.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Failed to load notes: $error')),
              data: (index) {
                final summaries = index
                    .summariesOfType(spec.primaryType)
                    .where((s) => !hasSecondaryTypes ||
                        s.secondaryType == null ||
                        visible.contains(s.secondaryType))
                    .toList();
                if (summaries.isEmpty) {
                  return const Center(child: Text('No notes yet.'));
                }
                return ListView.separated(
                  itemCount: summaries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, listIndex) {
                    final summary = summaries[listIndex];
                    return ListTile(
                      title: Text(summary.title.isEmpty ? summary.filename : summary.title),
                      onTap: () => _edit(context, summary),
                      trailing: IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(context, ref, summary),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
