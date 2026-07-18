import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../models/note_file.dart';
import '../models/note_type_spec.dart';
import '../screens/note_editor_navigation.dart';

/// Read-only preview of the note under question in the Netting flow: title
/// and content as markdown, with a top-right icon button to jump to its own
/// view screen — mirroring `flashcard_card.dart`'s Card layout/max-width
/// convention.
class NettingNoteCard extends StatelessWidget {
  final String filename;
  final NoteFile note;

  const NettingNoteCard({super.key, required this.filename, required this.note});

  @override
  Widget build(BuildContext context) {
    final title = note['title'] as String? ?? '';
    final content = note['content'] as String? ?? '';
    final spec = noteTypeSpecs.firstWhere((s) => s.primaryType == note['primaryType']);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton(
                    tooltip: 'Open note',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => pushNoteEditor(context, spec: spec, filename: filename),
                  ),
                ],
              ),
              const Divider(),
              MarkdownBody(data: content),
            ],
          ),
        ),
      ),
    );
  }
}
