import 'package:flutter/material.dart';

import '../models/note_type_spec.dart';
import 'note_type_list_screen.dart';

/// Overview of the note types available for browsing/editing/deleting.
class NoteListsScreen extends StatelessWidget {
  const NoteListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lists')),
      body: ListView.separated(
        itemCount: noteTypeSpecs.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final spec = noteTypeSpecs[index];
          return ListTile(
            title: Text(spec.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteTypeListScreen(spec: spec)),
            ),
          );
        },
      ),
    );
  }
}
