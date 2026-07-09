import 'package:flutter/material.dart';

/// A label + value display with a pencil button that swaps it into a
/// TextField with confirm/cancel, mirroring the per-item edit affordance in
/// [ArrayListSection] so both feel like one consistent pattern.
class InlineEditableText extends StatefulWidget {
  final String label;
  final String value;
  final bool multiline;
  final ValueChanged<String> onSave;

  const InlineEditableText({
    super.key,
    required this.label,
    required this.value,
    required this.onSave,
    this.multiline = false,
  });

  @override
  State<InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<InlineEditableText> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEdit() {
    _controller.text = widget.value;
    setState(() => _editing = true);
  }

  void _confirmEdit() {
    widget.onSave(widget.multiline ? _controller.text : _controller.text.trim());
    setState(() => _editing = false);
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _editing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: widget.multiline ? 4 : null,
                  maxLines: widget.multiline ? 12 : 1,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: widget.multiline,
                  ),
                  onSubmitted: widget.multiline ? null : (_) => _confirmEdit(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(widget.value.isEmpty ? '—' : widget.value),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit ${widget.label}',
                  icon: const Icon(Icons.edit),
                  onPressed: _startEdit,
                ),
              ],
            ),
    );
  }
}
