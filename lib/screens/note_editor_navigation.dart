import 'package:flutter/material.dart';

import '../models/note_type_spec.dart';
import 'note_detail_screen.dart';

/// Pushes [NoteDetailScreen] for [spec]/[filename]. Shared by the Lists
/// screen's edit/create actions and by "jump to" links from relationship
/// rows, so the destination is consistent no matter how a note is reached.
void pushNoteEditor(BuildContext context, {required NoteTypeSpec spec, required String filename}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NoteDetailScreen(spec: spec, filename: filename)),
  );
}
