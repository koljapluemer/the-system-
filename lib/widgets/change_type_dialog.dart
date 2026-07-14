import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_type_spec.dart';
import '../screens/note_detail_screen.dart';
import '../state/note_index_notifier.dart';

/// Modal listing every primaryType other than [currentSpec]'s. Picking one
/// converts the note in place (see [NoteIndexNotifier.changePrimaryType])
/// then replaces the current [NoteDetailScreen] route with one for the new
/// type, since [currentSpec] is fixed for the lifetime of the pushed screen
/// and can't just be swapped in place.
Future<void> showChangeTypeDialog(
  BuildContext context,
  WidgetRef ref, {
  required String filename,
  required NoteTypeSpec currentSpec,
}) {
  final otherSpecs = noteTypeSpecs.where((s) => s.primaryType != currentSpec.primaryType).toList();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Change Note Type'),
      content: SizedBox(
        width: 360,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final spec in otherSpecs)
              ListTile(
                title: Text(spec.label),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await ref
                      .read(noteIndexProvider.notifier)
                      .changePrimaryType(filename: filename, newSpec: spec);
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteDetailScreen(spec: spec, filename: filename),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
      ],
    ),
  );
}
