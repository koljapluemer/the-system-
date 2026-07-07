import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../state/note_index_notifier.dart';

/// Detail/edit view for a single hypothesis: four free-text logs (Context,
/// Experiment, Notes, Findings) plus the ACTIVE -> SUPPORTED/DISPROVEN
/// resolution. Watches the shared note index reactively, so changes made
/// here (including status) are reflected immediately if the Hypotheses list
/// screen underneath is popped back to.
class HypothesisDetailScreen extends ConsumerWidget {
  final String filename;

  const HypothesisDetailScreen({super.key, required this.filename});

  Future<void> _updateList(WidgetRef ref, NoteFile note, String key, List<String> items) {
    return ref.read(noteIndexProvider.notifier).write(filename, {...note, key: items});
  }

  Future<void> _setStatus(WidgetRef ref, NoteFile note, String status) {
    return ref.read(noteIndexProvider.notifier).write(filename, {...note, 'status': status});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteIndexProvider).value?.entries[filename];

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
    final status = note['status'] as String? ?? 'ACTIVE';
    final resolved = status != 'ACTIVE';

    return Scaffold(
      appBar: AppBar(title: Text(title.isEmpty ? filename : title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Status: $status', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          _ArrayListSection(
            label: 'Context',
            items: note.stringList('context'),
            onChanged: (items) => _updateList(ref, note, 'context', items),
          ),
          _ArrayListSection(
            label: 'Experiment',
            items: note.stringList('experiment'),
            onChanged: (items) => _updateList(ref, note, 'experiment', items),
          ),
          _ArrayListSection(
            label: 'Notes',
            items: note.stringList('notes'),
            onChanged: (items) => _updateList(ref, note, 'notes', items),
          ),
          _ArrayListSection(
            label: 'Findings',
            items: note.stringList('findings'),
            onChanged: (items) => _updateList(ref, note, 'findings', items),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: resolved ? null : () => _setStatus(ref, note, 'SUPPORTED'),
                  child: const Text('Mark supported'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: resolved ? null : () => _setStatus(ref, note, 'DISPROVEN'),
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

/// One editable header + list of plaintext entries: each entry has an inline
/// edit (swap to a TextField with confirm/cancel) and delete, and the list
/// ends with an inline "add" field.
class _ArrayListSection extends StatefulWidget {
  final String label;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  const _ArrayListSection({
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_ArrayListSection> createState() => _ArrayListSectionState();
}

class _ArrayListSectionState extends State<_ArrayListSection> {
  int? _editingIndex;
  final _editController = TextEditingController();
  final _addController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    _addController.dispose();
    super.dispose();
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      _editController.text = widget.items[index];
    });
  }

  void _confirmEdit() {
    final index = _editingIndex;
    if (index == null) return;
    final text = _editController.text.trim();
    if (text.isEmpty) return;
    final updated = [...widget.items];
    updated[index] = text;
    widget.onChanged(updated);
    setState(() => _editingIndex = null);
  }

  void _cancelEdit() {
    setState(() => _editingIndex = null);
  }

  void _delete(int index) {
    final updated = [...widget.items]..removeAt(index);
    widget.onChanged(updated);
    if (_editingIndex == index) {
      setState(() => _editingIndex = null);
    }
  }

  void _add() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    widget.onChanged([...widget.items, text]);
    _addController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          for (var i = 0; i < widget.items.length; i++)
            _editingIndex == i
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _editController,
                            autofocus: true,
                            onSubmitted: (_) => _confirmEdit(),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Save',
                          icon: const Icon(Icons.check),
                          onPressed: _confirmEdit,
                        ),
                        IconButton(
                          tooltip: 'Cancel',
                          icon: const Icon(Icons.close),
                          onPressed: _cancelEdit,
                        ),
                      ],
                    ),
                  )
                : ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(widget.items[i]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _startEdit(i),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete),
                          onPressed: () => _delete(i),
                        ),
                      ],
                    ),
                  ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    decoration: InputDecoration(labelText: 'Add to ${widget.label}'),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                IconButton(
                  tooltip: 'Add',
                  icon: const Icon(Icons.add),
                  onPressed: _add,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
