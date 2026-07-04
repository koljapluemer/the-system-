import 'package:flutter/material.dart';

import 'floating_notes_screen.dart';
import 'folder_setup_screen.dart';
import 'scratchpad_triage_screen.dart';

class _NavLink {
  final String id;
  final String label;
  const _NavLink(this.id, this.label);
}

// Data-driven on purpose: this app is meant to grow into a suite of flows,
// so new links just get added here.
const _links = [
  _NavLink('scratchpad-triage', 'Scratchpad Triage'),
  _NavLink('floating-notes', 'Floating Notes'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'scratchpad-triage':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScratchpadTriageScreen()),
        );
      case 'floating-notes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FloatingNotesScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          for (final link in _links)
            ListTile(
              title: Text(link.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigate(context, link.id),
            ),
        ],
      ),
    );
  }
}
