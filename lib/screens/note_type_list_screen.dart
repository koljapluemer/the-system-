import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_summary.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import '../widgets/undo_snackbar.dart';
import 'add_screen.dart';
import 'note_editor_navigation.dart';

/// Lists every note of [spec]'s primaryType. Tapping a note opens it for
/// editing; a trailing delete action removes it. Also offers a "new note"
/// action when [NoteTypeSpec.creatable] is set. Reacts
/// automatically to the shared note index, including changes made from other
/// screens (e.g. Triage or the edit form) — no manual reload.
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
    return Scaffold(
      appBar: AppBar(title: Text(spec.label)),
      floatingActionButton: spec.creatable
          ? FloatingActionButton(
              tooltip: 'New ${spec.label}',
              onPressed: () => _create(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: asyncIndex.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load notes: $error')),
        data: (index) {
          final summaries = index.summariesOfType(spec.primaryType);
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
    );
  }
}
