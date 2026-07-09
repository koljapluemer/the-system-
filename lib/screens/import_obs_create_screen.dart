import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import '../widgets/array_list_section.dart';
import 'import_obs_detail_screen.dart';

/// First step of an Import Obs Flow "Add `<Type>`" form: standard title /
/// content / aliases affordances, kept local until Confirm so aborting
/// leaves no orphan note on disk. Confirming creates the note and hands off
/// to [ImportObsDetailScreen].
class ImportObsCreateScreen extends ConsumerStatefulWidget {
  final NoteTypeSpec spec;

  const ImportObsCreateScreen({super.key, required this.spec});

  @override
  ConsumerState<ImportObsCreateScreen> createState() => _ImportObsCreateScreenState();
}

class _ImportObsCreateScreenState extends ConsumerState<ImportObsCreateScreen> {
  final _controllers = <String, TextEditingController>{};
  List<String> _aliases = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.spec.fields) {
      _controllers[field.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    for (final field in widget.spec.fields) {
      if (field.required && _controllers[field.key]!.text.trim().isEmpty) return;
    }

    setState(() => _saving = true);
    final fields = <String, dynamic>{};
    for (final field in widget.spec.fields) {
      final raw = _controllers[field.key]!.text;
      fields[field.key] = field.multiline ? raw : raw.trim();
    }
    fields['aliases'] = _aliases;

    final filename = await ref.read(noteIndexProvider.notifier).createNoteWithFields(
          primaryType: widget.spec.primaryType,
          fields: fields,
          slugSource: fields['title'] as String? ?? widget.spec.label,
        );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ImportObsDetailScreen(spec: widget.spec, filename: filename),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add ${widget.spec.label}')),
      body: ConstrainedBox(
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
              ArrayListSection(
                label: 'Aliases',
                items: _aliases,
                onChanged: (items) => setState(() => _aliases = items),
              ),
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
