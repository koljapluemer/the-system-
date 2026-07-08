import 'package:flutter/material.dart';

/// One editable header + list of plaintext entries: each entry has an inline
/// edit (swap to a TextField with confirm/cancel) and delete, and the list
/// ends with an inline "add" field.
class ArrayListSection extends StatefulWidget {
  final String label;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  const ArrayListSection({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  State<ArrayListSection> createState() => _ArrayListSectionState();
}

class _ArrayListSectionState extends State<ArrayListSection> {
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
