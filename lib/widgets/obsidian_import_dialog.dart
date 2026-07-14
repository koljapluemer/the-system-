import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/obsidian_frontmatter_service.dart';
import '../state/note_index_notifier.dart';

/// Modal for pasting Obsidian frontmatter (YAML, with or without the `---`
/// delimiters, arbitrary prop names and nesting allowed) and shallow-merging
/// it into the note at [filename]'s `extraData` (new keys overwrite existing
/// ones with the same name; other existing `extraData` keys are kept). Reads
/// the note fresh from the index at save time rather than a value captured
/// when the dialog opened, since the textbox can stay open a while.
Future<void> showObsidianImportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String filename,
}) {
  final controller = TextEditingController();
  const service = ObsidianFrontmatterService();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      String? error;
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Add props from Obsidian'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paste Obsidian frontmatter (YAML):'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 10,
                    maxLines: 16,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'aliases:\ncreated-at: 2025-06-08\nzk-id: "263"',
                    ),
                  ),
                  if (error case final message?) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Map<String, dynamic> parsed;
                  try {
                    parsed = service.parse(controller.text);
                  } on FormatException catch (e) {
                    setState(() => error = e.message);
                    return;
                  }
                  if (parsed.isEmpty) {
                    setState(() => error = 'Nothing to add.');
                    return;
                  }

                  final notifier = ref.read(noteIndexProvider.notifier);
                  final current = ref.read(noteIndexProvider).value?.entries[filename];
                  if (current == null) {
                    Navigator.pop(dialogContext);
                    return;
                  }
                  final existingExtraData = current['extraData'];
                  final mergedExtraData = {
                    if (existingExtraData is Map) ...Map<String, dynamic>.from(existingExtraData),
                    ...parsed,
                  };
                  await notifier.write(filename, {...current, 'extraData': mergedExtraData});
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}
