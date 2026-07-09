import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import '../widgets/array_list_section.dart';
import '../widgets/inline_editable_text.dart';
import '../widgets/source_relationship_dialog.dart';

/// Post-create view for an Import Obs Flow note: title/content are shown
/// read-only with a pencil button to inline-edit each, aliases likewise
/// behind a pencil toggle, plus a "Source Relationships" section for
/// attaching `["source", filename]` rels via a smart-search modal.
class ImportObsDetailScreen extends ConsumerStatefulWidget {
  final NoteTypeSpec spec;
  final String filename;

  const ImportObsDetailScreen({super.key, required this.spec, required this.filename});

  @override
  ConsumerState<ImportObsDetailScreen> createState() => _ImportObsDetailScreenState();
}

class _ImportObsDetailScreenState extends ConsumerState<ImportObsDetailScreen> {
  bool _editingAliases = false;

  Future<void> _saveField(NoteFile note, String key, String value) {
    return ref.read(noteIndexProvider.notifier).write(widget.filename, {...note, key: value});
  }

  Future<void> _saveAliases(NoteFile note, List<String> aliases) {
    return ref
        .read(noteIndexProvider.notifier)
        .write(widget.filename, {...note, 'aliases': aliases});
  }

  Future<void> _removeSourceRel(NoteFile note, List<String> rel) {
    final rels = note.stringPairList('rels').where((r) => r != rel).toList();
    return ref.read(noteIndexProvider.notifier).write(widget.filename, {...note, 'rels': rels});
  }

  @override
  Widget build(BuildContext context) {
    final asyncIndex = ref.watch(noteIndexProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.spec.label)),
      body: asyncIndex.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load note: $error')),
        data: (index) {
          final note = index.entries[widget.filename];
          if (note == null) {
            return const Center(child: Text('This note no longer exists.'));
          }
          final aliases = note.stringList('aliases');
          final sourceRels =
              note.stringPairList('rels').where((rel) => rel[0] == 'source').toList();

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final field in widget.spec.fields)
                    InlineEditableText(
                      label: field.label,
                      value: note[field.key] as String? ?? '',
                      multiline: field.multiline,
                      onSave: (value) => _saveField(note, field.key, value),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _editingAliases
                            ? ArrayListSection(
                                label: 'Aliases',
                                items: aliases,
                                onChanged: (items) => _saveAliases(note, items),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Aliases', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  aliases.isEmpty
                                      ? const Text('—')
                                      : Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            for (final alias in aliases) Chip(label: Text(alias)),
                                          ],
                                        ),
                                ],
                              ),
                      ),
                      IconButton(
                        tooltip: _editingAliases ? 'Done' : 'Edit Aliases',
                        icon: Icon(_editingAliases ? Icons.check : Icons.edit),
                        onPressed: () => setState(() => _editingAliases = !_editingAliases),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Source Relationships', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  if (sourceRels.isEmpty) const Text('—'),
                  for (final rel in sourceRels)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(index.entries[rel[1]]?['title'] as String? ?? rel[1]),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeSourceRel(note, rel),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_link),
                    label: const Text('Add Source Relationship'),
                    onPressed: () =>
                        showSourceRelationshipDialog(context, ref, filename: widget.filename),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
