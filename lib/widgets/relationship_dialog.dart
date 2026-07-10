import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../screens/add_screen.dart';
import '../state/note_index_notifier.dart';

/// Pushes the shared Add form (see `add_screen.dart`) to attach a
/// `[relType, filename]` relationship to the note at [filename]: its
/// built-in similar-notes suggestions double as the search for an existing
/// note to attach, and typing a new title falls back to creating one —
/// restricted to [allowedPrimaryTypes], locked to a single type when only
/// one is allowed. Either path writes the relationship via [_attach] and
/// returns to the originating note.
Future<void> showRelationshipDialog(
  BuildContext context,
  WidgetRef ref, {
  required String filename,
  required String relType,
  required List<String> allowedPrimaryTypes,
  required String dialogTitle,
}) {
  Future<void> attach(String relatedFilename) async {
    final notifier = ref.read(noteIndexProvider.notifier);
    final note = ref.read(noteIndexProvider).value?.entries[filename];
    if (note == null) return;
    final rels = [
      for (final rel in note.stringPairList('rels')) rel,
      [relType, relatedFilename],
    ];
    await notifier.write(filename, {...note, 'rels': rels});
  }

  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddScreen(
        allowedTypes: allowedPrimaryTypes,
        appBarTitle: dialogTitle,
        showBackButton: true,
        onSuggestionSelected: (ctx, ref, relatedFilename) async {
          await attach(relatedFilename);
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onCreated: (ref, createdFilename) => attach(createdFilename),
      ),
    ),
  );
}
