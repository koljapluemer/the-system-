import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_summary.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import '../widgets/undo_snackbar.dart';
import 'hypothesis_detail_screen.dart';
import 'note_edit_screen.dart';

final _hypothesisSpec = noteTypeSpecs.firstWhere((s) => s.primaryType == 'hypothesis');

/// Dedicated CRUD view of ACTIVE hypotheses, with an inline add field at the
/// bottom. Resolved hypotheses (SUPPORTED/DISPROVEN) drop off this list
/// automatically once their status changes, since it reactively watches the
/// shared note index — see HypothesisDetailScreen.
class HypothesesScreen extends ConsumerStatefulWidget {
  const HypothesesScreen({super.key});

  @override
  ConsumerState<HypothesesScreen> createState() => _HypothesesScreenState();
}

class _HypothesesScreenState extends ConsumerState<HypothesesScreen> {
  final _newTitleController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _newTitleController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final title = _newTitleController.text.trim();
    if (title.isEmpty || _adding) return;
    setState(() => _adding = true);
    await ref.read(noteIndexProvider.notifier).createHypothesis(title: title);
    _newTitleController.clear();
    if (mounted) setState(() => _adding = false);
  }

  void _openDetail(BuildContext context, NoteSummary summary) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HypothesisDetailScreen(filename: summary.filename)),
    );
  }

  void _edit(BuildContext context, NoteSummary summary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(spec: _hypothesisSpec, filename: summary.filename),
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
  Widget build(BuildContext context) {
    final asyncIndex = ref.watch(noteIndexProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hypotheses')),
      body: Column(
        children: [
          Expanded(
            child: asyncIndex.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Failed to load notes: $error')),
              data: (index) {
                final summaries = index.hypothesesWithStatus('ACTIVE');
                if (summaries.isEmpty) {
                  return const Center(child: Text('No active hypotheses.'));
                }
                return ListView.separated(
                  itemCount: summaries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, listIndex) {
                    final summary = summaries[listIndex];
                    return ListTile(
                      title: Text(summary.title.isEmpty ? summary.filename : summary.title),
                      onTap: () => _openDetail(context, summary),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _edit(context, summary),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete),
                            onPressed: () => _delete(context, ref, summary),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTitleController,
                    decoration: const InputDecoration(
                      labelText: 'New hypothesis',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Add',
                  icon: const Icon(Icons.add),
                  onPressed: _adding ? null : _add,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
