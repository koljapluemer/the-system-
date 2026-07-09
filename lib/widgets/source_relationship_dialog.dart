import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../state/note_index_notifier.dart';

/// Opens a smart-search modal (title + aliases, over `primaryType: "source"`
/// notes) for attaching a `["source", filename]` relationship to the note at
/// [filename]. If nothing matches the query, offers to create a new source
/// with that title instead. Handles the read-modify-write of `rels` itself.
Future<void> showSourceRelationshipDialog(
  BuildContext context,
  WidgetRef ref, {
  required String filename,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SourceRelationshipDialog(filename: filename),
  );
}

class _SourceRelationshipDialog extends ConsumerStatefulWidget {
  final String filename;

  const _SourceRelationshipDialog({required this.filename});

  @override
  ConsumerState<_SourceRelationshipDialog> createState() => _SourceRelationshipDialogState();
}

class _SourceRelationshipDialogState extends ConsumerState<_SourceRelationshipDialog> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _attach(BuildContext dialogContext, String sourceFilename) async {
    final notifier = ref.read(noteIndexProvider.notifier);
    final note = ref.read(noteIndexProvider).value?.entries[widget.filename];
    if (note == null) return;
    final rels = [
      for (final rel in note.stringPairList('rels')) rel,
      ['source', sourceFilename],
    ];
    await notifier.write(widget.filename, {...note, 'rels': rels});
    if (dialogContext.mounted) Navigator.pop(dialogContext);
  }

  Future<void> _createAndAttach(BuildContext dialogContext, String title) async {
    final notifier = ref.read(noteIndexProvider.notifier);
    final sourceFilename = await notifier.createNoteWithFields(
      primaryType: 'source',
      fields: {'title': title},
      slugSource: title,
    );
    if (!dialogContext.mounted) return;
    await _attach(dialogContext, sourceFilename);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(noteIndexProvider).value;
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? const <MapEntry<String, NoteFile>>[]
        : [
            for (final entry in (index?.entries.entries ?? const <MapEntry<String, NoteFile>>[]))
              if (entry.value['primaryType'] == 'source' &&
                  (((entry.value['title'] as String? ?? '').toLowerCase().contains(query)) ||
                      entry.value.stringList('aliases').any((a) => a.toLowerCase().contains(query))))
                entry,
          ];
    final exactTitleMatch =
        matches.any((entry) => (entry.value['title'] as String? ?? '').toLowerCase() == query);

    return AlertDialog(
      title: const Text('Add Source Relationship'),
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
                labelText: 'Search sources by title or alias',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in matches)
                    ListTile(
                      title: Text(entry.value['title'] as String? ?? entry.key),
                      onTap: () => _attach(context, entry.key),
                    ),
                  if (query.isNotEmpty && !exactTitleMatch)
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text('Create new source "${_queryController.text.trim()}"'),
                      onTap: () => _createAndAttach(context, _queryController.text.trim()),
                    ),
                ],
              ),
            ),
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
