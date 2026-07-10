import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_screen.dart';
import 'art_triage_screen.dart';
import 'floating_notes_screen.dart';
import 'folder_setup_screen.dart';
import 'hypotheses_screen.dart';
import 'invalid_json_screen.dart';
import 'note_lists_screen.dart';
import 'scratchpad_triage_screen.dart';
import '../state/note_index_notifier.dart';
import '../state/providers.dart';

class _NavLink {
  final String id;
  final String label;
  const _NavLink(this.id, this.label);
}

// Data-driven on purpose: this app is meant to grow into a suite of flows,
// so new links just get added here.
const _links = [
  _NavLink('scratchpad-triage', 'Scratchpad Triage'),
  _NavLink('art-triage', 'Art Triage'),
  _NavLink('floating-notes', 'Floating Notes'),
  _NavLink('hypotheses', 'Hypotheses'),
  _NavLink('lists', 'Lists'),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'scratchpad-triage':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScratchpadTriageScreen()),
        );
      case 'art-triage':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ArtTriageScreen()),
        );
      case 'floating-notes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FloatingNotesScreen()),
        );
      case 'hypotheses':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HypothesesScreen()),
        );
      case 'lists':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoteListsScreen()),
        );
    }
  }

  Future<void> _checkForInvalidJson(BuildContext context, WidgetRef ref) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final index = await ref.read(noteIndexProvider.future);
    final invalid = await ref.read(jsonSchemaServiceProvider).findInvalid(index);
    if (!context.mounted) return;
    Navigator.pop(context); // dismiss the progress dialog

    if (invalid.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Nothing found')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvalidJsonScreen(filenames: invalid)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Change data folder',
            icon: const Icon(Icons.folder_open),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FolderSetupScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddScreen()),
            ),
          ),
          const Divider(height: 1),
          for (final link in _links)
            ListTile(
              title: Text(link.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigate(context, link.id),
            ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Maintenance'),
          ),
          ListTile(
            leading: const Icon(Icons.rule_folder),
            title: const Text('Check for invalid JSON files'),
            onTap: () => _checkForInvalidJson(context, ref),
          ),
        ],
      ),
    );
  }
}
