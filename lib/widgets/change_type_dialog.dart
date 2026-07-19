import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_type_spec.dart';
import '../screens/note_detail_screen.dart';
import '../state/note_index_notifier.dart';
import '../state/recent_history_notifier.dart';

/// Modal listing every primaryType other than [currentSpec]'s. Picking one
/// converts the note in place (see [NoteIndexNotifier.changePrimaryType]),
/// records it in [recentHistoryProvider] (the note may never have been
/// pushed as its own route before — e.g. when reached from a triage flow —
/// so the recent-history bar wouldn't otherwise know about it), calls
/// [onChanged] (for callers that need to react, e.g. a triage flow moving
/// on to its next note), then replaces the current [NoteDetailScreen] route
/// with one for the new type, since [currentSpec] is fixed for the lifetime
/// of the pushed screen and can't just be swapped in place.
Future<void> showChangeTypeDialog(
  BuildContext context,
  WidgetRef ref, {
  required String filename,
  required NoteTypeSpec currentSpec,
  VoidCallback? onChanged,
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
                  final title =
                      ref.read(noteIndexProvider).value?.entries[filename]?['title'] as String? ??
                      filename;
                  ref
                      .read(recentHistoryProvider.notifier)
                      .record(RecentEntry(kind: RecentEntryKind.note, id: filename, label: title));
                  onChanged?.call();
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
