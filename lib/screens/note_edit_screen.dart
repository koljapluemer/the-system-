import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';

/// Generic edit form for a note's core fields, driven by [spec].
class NoteEditScreen extends ConsumerStatefulWidget {
  final NoteTypeSpec spec;
  final String filename;

  const NoteEditScreen({super.key, required this.spec, required this.filename});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _controllers = <String, TextEditingController>{};
  NoteFile? _original;
  bool _missing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.spec.fields) {
      _controllers[field.key] = TextEditingController();
    }
    // The note is already resident in the shared index by the time this
    // screen is reachable (pushed from a row already listing it), so this
    // read is synchronous — no disk IO needed here at all.
    final note = ref.read(noteIndexProvider).value?.entries[widget.filename];
    if (note == null) {
      _missing = true;
      return;
    }
    for (final field in widget.spec.fields) {
      _controllers[field.key]!.text = note[field.key] as String? ?? '';
    }
    _original = note;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    final original = _original;
    if (original == null || _saving) return;

    for (final field in widget.spec.fields) {
      if (field.required && _controllers[field.key]!.text.trim().isEmpty) return;
    }

    setState(() => _saving = true);
    final updated = {...original};
    for (final field in widget.spec.fields) {
      final raw = _controllers[field.key]!.text;
      updated[field.key] = field.multiline ? raw : raw.trim();
    }
    await ref.read(noteIndexProvider.notifier).write(widget.filename, updated);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.spec.label}')),
      body: _missing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('This note no longer exists.'),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in widget.spec.fields) ...[
                      TextField(
                        controller: _controllers[field.key],
                        minLines: field.multiline ? 4 : null,
                        maxLines: field.multiline ? 12 : 1,
                        decoration: InputDecoration(
                          labelText: field.label,
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: field.multiline,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => Navigator.pop(context),
                            child: const Text('Abort'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _confirm,
                            child: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
