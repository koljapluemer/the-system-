import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A label + value display with a pencil button that swaps it into a
/// TextField with confirm/cancel, mirroring the per-item edit affordance in
/// [ArrayListSection] so both feel like one consistent pattern. The value is
/// rendered as markdown whenever it isn't being edited, unless [isUrl] is set
/// — then it renders as a tappable hyperlink (opened via `url_launcher`)
/// instead.
class InlineEditableText extends StatefulWidget {
  final String label;
  final String value;
  final bool multiline;
  final bool isUrl;
  final ValueChanged<String> onSave;

  const InlineEditableText({
    super.key,
    required this.label,
    required this.value,
    required this.onSave,
    this.multiline = false,
    this.isUrl = false,
  });

  @override
  State<InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<InlineEditableText> {
  bool _editing = false;
  // Tracks whether the field should render as multi-line. A field can contain
  // embedded newlines (e.g. a markdown title) even when [widget.multiline] is
  // false; forcing such text into a maxLines: 1 TextField breaks caret
  // positioning and scrolling, since that render path assumes the text never
  // wraps. So this also flips on whenever the text actually contains '\n'.
  bool _multiline = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEdit() {
    _controller.text = widget.value;
    _multiline = widget.multiline || widget.value.contains('\n');
    setState(() => _editing = true);
  }

  void _onChanged(String text) {
    final multiline = widget.multiline || text.contains('\n');
    if (multiline != _multiline) setState(() => _multiline = multiline);
  }

  void _confirmEdit() {
    widget.onSave(_multiline ? _controller.text : _controller.text.trim());
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
                  minLines: _multiline ? 4 : null,
                  maxLines: _multiline ? 12 : 1,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: _multiline,
                  ),
                  onSubmitted: _multiline ? null : (_) => _confirmEdit(),
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
                      if (widget.isUrl && widget.value.isNotEmpty && Uri.tryParse(widget.value) != null)
                        InkWell(
                          onTap: () => launchUrl(
                            Uri.parse(widget.value),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Text(
                            widget.value,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      else
                        MarkdownBody(data: widget.value.isEmpty ? '—' : widget.value),
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
