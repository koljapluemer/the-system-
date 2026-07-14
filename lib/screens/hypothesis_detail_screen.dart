import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../state/note_index_notifier.dart';
import '../widgets/array_list_section.dart';
import '../widgets/logs_section.dart';
import '../widgets/obsidian_import_dialog.dart';

/// Detail/edit view for a single hypothesis: four free-text logs (Context,
/// Experiment, Notes, Findings) plus the active -> supported/disproven
/// resolution, stored as `secondaryType`. Watches the shared note index
/// reactively, so changes made here are reflected immediately if the
/// Hypotheses list screen underneath is popped back to.
class HypothesisDetailScreen extends ConsumerWidget {
  final String filename;

  const HypothesisDetailScreen({super.key, required this.filename});

  Future<void> _updateList(WidgetRef ref, NoteFile note, String key, List<String> items) {
    return ref.read(noteIndexProvider.notifier).write(filename, {...note, key: items});
  }

  Future<void> _setSecondaryType(WidgetRef ref, NoteFile note, String secondaryType) {
    return ref
        .read(noteIndexProvider.notifier)
        .write(filename, {...note, 'secondaryType': secondaryType});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(noteIndexProvider).value;
    final note = index?.entries[filename];

    if (note == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This hypothesis no longer exists.'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final title = note['title'] as String? ?? '';
    final secondaryType = note['secondaryType'] as String? ?? 'active';
    final resolved = secondaryType != 'active';

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? filename : title),
        actions: [
          IconButton(
            tooltip: 'Add props from Obsidian',
            icon: const Icon(Icons.data_object),
            onPressed: () => showObsidianImportDialog(context, ref, filename: filename),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Status: $secondaryType', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          ArrayListSection(
            label: 'Context',
            items: note.stringList('context'),
            onChanged: (items) => _updateList(ref, note, 'context', items),
          ),
          ArrayListSection(
            label: 'Experiment',
            items: note.stringList('experiment'),
            onChanged: (items) => _updateList(ref, note, 'experiment', items),
          ),
          ArrayListSection(
            label: 'Notes',
            items: note.stringList('notes'),
            onChanged: (items) => _updateList(ref, note, 'notes', items),
          ),
          ArrayListSection(
            label: 'Findings',
            items: note.stringList('findings'),
            onChanged: (items) => _updateList(ref, note, 'findings', items),
          ),
          LogsSection(filename: filename, note: note, index: index!),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: resolved ? null : () => _setSecondaryType(ref, note, 'supported'),
                  child: const Text('Mark supported'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: resolved ? null : () => _setSecondaryType(ref, note, 'disproven'),
                  child: const Text('Mark disproven'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
