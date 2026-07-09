import 'package:flutter/material.dart';

import '../models/note_type_spec.dart';
import 'import_obs_create_screen.dart';
import 'import_obs_stub_screen.dart';

/// `primaryType` selection screen for the Import Obs Flow (see
/// docs/obs-import.md). Only `ifThen` has a dedicated form so far; the rest
/// route to a placeholder until their own doc sections get specced.
class ImportObsTypeScreen extends StatelessWidget {
  const ImportObsTypeScreen({super.key});

  static const _primaryTypes = [
    'gestalt',
    'context',
    'ifThen',
    'description',
    'quote',
    'source',
    'book',
    'entity',
    'story',
  ];

  void _select(BuildContext context, String primaryType) {
    final spec = noteTypeSpecs.firstWhere((s) => s.primaryType == primaryType);
    if (primaryType == 'ifThen') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImportObsCreateScreen(spec: spec)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImportObsStubScreen(label: spec.label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Obs Flow')),
      body: ListView.separated(
        itemCount: _primaryTypes.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final primaryType = _primaryTypes[index];
          final label = noteTypeSpecs.firstWhere((s) => s.primaryType == primaryType).label;
          return ListTile(
            title: Text(label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _select(context, primaryType),
          );
        },
      ),
    );
  }
}
