import 'package:flutter/material.dart';

/// One editable header + list of Netting-flow question/answer entries: each
/// entry has an inline edit (swap to a TextField with confirm/cancel,
/// mirroring [ArrayListSection]'s per-item edit) and delete. Unlike
/// [ArrayListSection], there's no "add new" row — entries only ever
/// originate from the Netting flow itself.
class QuestionsSection extends StatefulWidget {
  final Map<String, dynamic> questions;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const QuestionsSection({super.key, required this.questions, required this.onChanged});

  @override
  State<QuestionsSection> createState() => _QuestionsSectionState();
}

class _QuestionsSectionState extends State<QuestionsSection> {
  String? _editingQuestion;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEdit(String question, dynamic currentValue) {
    setState(() {
      _editingQuestion = question;
      _editController.text = currentValue is String ? currentValue : '';
    });
  }

  void _confirmEdit(String question) {
    final text = _editController.text.trim();
    if (text.isEmpty) return;
    widget.onChanged({...widget.questions, question: text});
    setState(() => _editingQuestion = null);
  }

  void _cancelEdit() {
    setState(() => _editingQuestion = null);
  }

  void _delete(String question) {
    final updated = {...widget.questions}..remove(question);
    widget.onChanged(updated);
    if (_editingQuestion == question) {
      setState(() => _editingQuestion = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.questions.entries.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Questions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (entries.isEmpty) const Text('—'),
          for (final entry in entries)
            _editingQuestion == entry.key
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _editController,
                            autofocus: true,
                            onSubmitted: (_) => _confirmEdit(entry.key),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Save',
                          icon: const Icon(Icons.check),
                          onPressed: () => _confirmEdit(entry.key),
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
                    title: Text(entry.key),
                    subtitle: Text(entry.value == false ? 'Not relevant' : entry.value as String),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _startEdit(entry.key, entry.value),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete),
                          onPressed: () => _delete(entry.key),
                        ),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }
}
