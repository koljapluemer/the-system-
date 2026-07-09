import 'package:flutter/material.dart';

import '../models/note_type_spec.dart';
import 'note_detail_screen.dart';
import 'note_edit_screen.dart';

/// Pushes the right editing UI for [spec] — [NoteDetailScreen] for richEdit
/// types, the plain [NoteEditScreen] form otherwise. Shared by the Lists
/// screen's edit/create actions and by "jump to" links from relationship
/// sections, so the destination is consistent no matter how a note is
/// reached.
void pushNoteEditor(BuildContext context, {required NoteTypeSpec spec, required String filename}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => spec.richEdit
          ? NoteDetailScreen(spec: spec, filename: filename)
          : NoteEditScreen(spec: spec, filename: filename),
    ),
  );
}
