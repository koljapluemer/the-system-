import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../models/note_index.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import '../widgets/array_list_section.dart';
import '../widgets/inline_editable_text.dart';
import '../widgets/relationship_dialog.dart';
import '../widgets/undo_snackbar.dart';
import 'note_editor_navigation.dart';

/// primaryTypes eligible as "Evidence" for a note, per docs/obs-import.md —
/// deliberately excludes `source`, which has its own dedicated relationship.
const _evidencePrimaryTypes = ['gestalt', 'context', 'ifThen', 'description', 'quote', 'story'];

/// Richer view/edit UI for a note, used in place of [NoteEditScreen] for
/// primaryTypes with [NoteTypeSpec.richEdit] set (currently just `ifThen`):
/// title/content are shown read-only with a pencil button to inline-edit
/// each, aliases likewise behind a pencil toggle, plus "Source
/// Relationships"/"Evidence" sections for attaching `[relType, filename]`
/// rels via a smart-search modal. Originated as the Import Obs Flow's
/// post-create screen; also used as the Lists screen's edit destination for
/// richEdit types, so this is the general note-editing UI, not
/// flow-specific.
class NoteDetailScreen extends ConsumerStatefulWidget {
  final NoteTypeSpec spec;
  final String filename;

  const NoteDetailScreen({super.key, required this.spec, required this.filename});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  bool _editingAliases = false;

  Future<void> _saveField(NoteFile note, String key, String value) {
    return ref.read(noteIndexProvider.notifier).write(widget.filename, {...note, key: value});
  }

  Future<void> _saveAliases(NoteFile note, List<String> aliases) {
    return ref
        .read(noteIndexProvider.notifier)
        .write(widget.filename, {...note, 'aliases': aliases});
  }

  /// Removes [rel] from the note's `rels` without touching the related note
  /// itself, offering an Undo that re-attaches it.
  Future<void> _detachRel(
    BuildContext context,
    NoteFile note,
    List<String> rel,
    String relatedTitle,
  ) async {
    final notifier = ref.read(noteIndexProvider.notifier);
    final rels = note.stringPairList('rels').where((r) => r != rel).toList();
    await notifier.write(widget.filename, {...note, 'rels': rels});
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: 'Detached "$relatedTitle"',
      onUndo: () async {
        final current = ref.read(noteIndexProvider).value?.entries[widget.filename];
        if (current == null) return;
        await notifier.write(widget.filename, {
          ...current,
          'rels': [...current.stringPairList('rels'), rel],
        });
      },
    );
  }

  /// Deletes the related note itself (not just the link) and detaches [rel]
  /// so it doesn't dangle, offering an Undo that recreates the note and
  /// re-attaches it.
  Future<void> _deleteRelated(
    BuildContext context,
    NoteFile note,
    List<String> rel,
    String relatedTitle,
  ) async {
    final notifier = ref.read(noteIndexProvider.notifier);
    final relatedFilename = rel[1];
    final relatedNote = ref.read(noteIndexProvider).value?.entries[relatedFilename];
    final rels = note.stringPairList('rels').where((r) => r != rel).toList();
    await notifier.write(widget.filename, {...note, 'rels': rels});
    await notifier.delete(relatedFilename);
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: 'Deleted "$relatedTitle"',
      onUndo: () async {
        if (relatedNote != null) {
          await notifier.write(relatedFilename, relatedNote);
        }
        final current = ref.read(noteIndexProvider).value?.entries[widget.filename];
        if (current == null) return;
        await notifier.write(widget.filename, {
          ...current,
          'rels': [...current.stringPairList('rels'), rel],
        });
      },
    );
  }

  Future<void> _renameRelated(String relatedFilename, String newTitle) async {
    final notifier = ref.read(noteIndexProvider.notifier);
    final relatedNote = ref.read(noteIndexProvider).value?.entries[relatedFilename];
    if (relatedNote == null) return;
    await notifier.write(relatedFilename, {...relatedNote, 'title': newTitle});
  }

  void _jumpTo(BuildContext context, NoteIndex index, String relatedFilename) {
    final relatedNote = index.entries[relatedFilename];
    if (relatedNote == null) return;
    final relatedSpec =
        noteTypeSpecs.firstWhere((s) => s.primaryType == relatedNote['primaryType']);
    pushNoteEditor(context, spec: relatedSpec, filename: relatedFilename);
  }

  /// One relationship type's list + "Add" button, e.g. "Source Relationships"
  /// or "Evidence" — the two are identical apart from [relType], the section
  /// heading/button label, and which primaryTypes are searchable/creatable.
  Widget _relationshipSection({
    required BuildContext context,
    required NoteFile note,
    required NoteIndex index,
    required String relType,
    required String sectionLabel,
    required String buttonLabel,
    required List<String> allowedPrimaryTypes,
  }) {
    final rels = note.stringPairList('rels').where((rel) => rel[0] == relType).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sectionLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (rels.isEmpty) const Text('—'),
        for (final rel in rels)
          _RelationshipRow(
            title: index.entries[rel[1]]?['title'] as String? ?? rel[1],
            targetExists: index.entries.containsKey(rel[1]),
            onSaveTitle: (newTitle) => _renameRelated(rel[1], newTitle),
            onJumpTo: index.entries.containsKey(rel[1]) ? () => _jumpTo(context, index, rel[1]) : null,
            onDetach: () => _detachRel(
              context,
              note,
              rel,
              index.entries[rel[1]]?['title'] as String? ?? rel[1],
            ),
            onDelete: index.entries.containsKey(rel[1])
                ? () => _deleteRelated(
                      context,
                      note,
                      rel,
                      index.entries[rel[1]]?['title'] as String? ?? rel[1],
                    )
                : null,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_link),
          label: Text(buttonLabel),
          onPressed: () => showRelationshipDialog(
            context,
            ref,
            filename: widget.filename,
            relType: relType,
            allowedPrimaryTypes: allowedPrimaryTypes,
            dialogTitle: buttonLabel,
          ),
        ),
      ],
    );
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
                  _relationshipSection(
                    context: context,
                    note: note,
                    index: index,
                    relType: 'source',
                    sectionLabel: 'Source Relationships',
                    buttonLabel: 'Add Source Relationship',
                    allowedPrimaryTypes: const ['source'],
                  ),
                  const SizedBox(height: 16),
                  _relationshipSection(
                    context: context,
                    note: note,
                    index: index,
                    relType: 'evidence',
                    sectionLabel: 'Evidence',
                    buttonLabel: 'Add Evidence',
                    allowedPrimaryTypes: _evidencePrimaryTypes,
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

/// One relationship link: title with an inline rename (pencil → TextField
/// with confirm/cancel, mirroring [ArrayListSection]'s per-item edit), plus
/// jump-to/detach/delete actions. Jump-to, edit, and delete are disabled
/// when the related note no longer exists (a dangling rel) — detach stays
/// enabled so a dangling rel can still be cleaned up.
class _RelationshipRow extends StatefulWidget {
  final String title;
  final bool targetExists;
  final ValueChanged<String> onSaveTitle;
  final VoidCallback? onJumpTo;
  final VoidCallback onDetach;
  final VoidCallback? onDelete;

  const _RelationshipRow({
    required this.title,
    required this.targetExists,
    required this.onSaveTitle,
    required this.onJumpTo,
    required this.onDetach,
    required this.onDelete,
  });

  @override
  State<_RelationshipRow> createState() => _RelationshipRowState();
}

class _RelationshipRowState extends State<_RelationshipRow> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEdit() {
    _controller.text = widget.title;
    setState(() => _editing = true);
  }

  void _confirmEdit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) widget.onSaveTitle(text);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
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
              onPressed: () => setState(() => _editing = false),
            ),
          ],
        ),
      );
    }
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(widget.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Jump to',
            icon: const Icon(Icons.open_in_new),
            onPressed: widget.onJumpTo,
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: widget.targetExists ? _startEdit : null,
          ),
          IconButton(
            tooltip: 'Detach',
            icon: const Icon(Icons.link_off),
            onPressed: widget.onDetach,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
