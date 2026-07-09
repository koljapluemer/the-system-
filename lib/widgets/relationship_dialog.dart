import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';

/// Opens a smart-search modal (title + aliases, over notes whose
/// primaryType is in [allowedPrimaryTypes]) for attaching a
/// `[relType, filename]` relationship to the note at [filename]. If nothing
/// matches the query, offers to create a new note with that title instead —
/// when more than one primaryType is allowed, the user must pick which one
/// from a dropdown before creating. Handles the read-modify-write of `rels`
/// itself.
Future<void> showRelationshipDialog(
  BuildContext context,
  WidgetRef ref, {
  required String filename,
  required String relType,
  required List<String> allowedPrimaryTypes,
  required String dialogTitle,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _RelationshipDialog(
      filename: filename,
      relType: relType,
      allowedPrimaryTypes: allowedPrimaryTypes,
      dialogTitle: dialogTitle,
    ),
  );
}

class _RelationshipDialog extends ConsumerStatefulWidget {
  final String filename;
  final String relType;
  final List<String> allowedPrimaryTypes;
  final String dialogTitle;

  const _RelationshipDialog({
    required this.filename,
    required this.relType,
    required this.allowedPrimaryTypes,
    required this.dialogTitle,
  });

  @override
  ConsumerState<_RelationshipDialog> createState() => _RelationshipDialogState();
}

class _RelationshipDialogState extends ConsumerState<_RelationshipDialog> {
  final _queryController = TextEditingController();
  String _query = '';
  late String _newNoteType = widget.allowedPrimaryTypes.first;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  String _labelFor(String primaryType) =>
      noteTypeSpecs.firstWhere((s) => s.primaryType == primaryType).label;

  Future<void> _attach(BuildContext dialogContext, String relatedFilename) async {
    final notifier = ref.read(noteIndexProvider.notifier);
    final note = ref.read(noteIndexProvider).value?.entries[widget.filename];
    if (note == null) return;
    final rels = [
      for (final rel in note.stringPairList('rels')) rel,
      [widget.relType, relatedFilename],
    ];
    await notifier.write(widget.filename, {...note, 'rels': rels});
    if (dialogContext.mounted) Navigator.pop(dialogContext);
  }

  Future<void> _createAndAttach(BuildContext dialogContext, String title) async {
    final notifier = ref.read(noteIndexProvider.notifier);
    final relatedFilename = await notifier.createNoteWithFields(
      primaryType: _newNoteType,
      fields: {'title': title},
      slugSource: title,
    );
    if (!dialogContext.mounted) return;
    await _attach(dialogContext, relatedFilename);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(noteIndexProvider).value;
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? const <MapEntry<String, NoteFile>>[]
        : [
            for (final entry in (index?.entries.entries ?? const <MapEntry<String, NoteFile>>[]))
              if (widget.allowedPrimaryTypes.contains(entry.value['primaryType']) &&
                  (((entry.value['title'] as String? ?? '').toLowerCase().contains(query)) ||
                      entry.value.stringList('aliases').any((a) => a.toLowerCase().contains(query))))
                entry,
          ];
    final exactTitleMatch =
        matches.any((entry) => (entry.value['title'] as String? ?? '').toLowerCase() == query);
    final showMultiType = widget.allowedPrimaryTypes.length > 1;

    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search by title or alias',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in matches)
                    ListTile(
                      title: Text(entry.value['title'] as String? ?? entry.key),
                      subtitle:
                          showMultiType ? Text(_labelFor(entry.value['primaryType'] as String)) : null,
                      onTap: () => _attach(context, entry.key),
                    ),
                ],
              ),
            ),
            if (query.isNotEmpty && !exactTitleMatch) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (showMultiType)
                DropdownButtonFormField<String>(
                  initialValue: _newNoteType,
                  decoration: const InputDecoration(labelText: 'New note type'),
                  items: [
                    for (final type in widget.allowedPrimaryTypes)
                      DropdownMenuItem(value: type, child: Text(_labelFor(type))),
                  ],
                  onChanged: (value) => setState(() => _newNoteType = value!),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add),
                title: Text(
                  'Create new ${_labelFor(_newNoteType)} "${_queryController.text.trim()}"',
                ),
                onTap: () => _createAndAttach(context, _queryController.text.trim()),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
