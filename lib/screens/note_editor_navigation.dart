import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import '../state/recent_history_notifier.dart';
import 'note_detail_screen.dart';

/// Pushes [NoteDetailScreen] for [spec]/[filename] and records it in
/// [recentHistoryProvider]. Shared by the Lists screen's edit/create
/// actions and by "jump to" links from relationship rows, so the
/// destination — and the recent-history bar — stays consistent no matter
/// how a note is reached. Reads the container directly (rather than taking
/// a `WidgetRef` param) so this stays callable from plain
/// `StatelessWidget`s like `FlashcardCard`.
void pushNoteEditor(BuildContext context, {required NoteTypeSpec spec, required String filename}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final note = container.read(noteIndexProvider).value?.entries[filename];
  final title = note?['title'] as String? ?? filename;
  container
      .read(recentHistoryProvider.notifier)
      .record(RecentEntry(kind: RecentEntryKind.note, id: filename, label: title));

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NoteDetailScreen(spec: spec, filename: filename)),
  );
}
