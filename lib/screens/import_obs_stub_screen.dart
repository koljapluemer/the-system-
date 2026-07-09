import 'package:flutter/material.dart';

/// Placeholder for Import Obs Flow primaryTypes not yet specced in
/// docs/obs-import.md.
class ImportObsStubScreen extends StatelessWidget {
  final String label;

  const ImportObsStubScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add $label')),
      body: const Center(child: Text('Not implemented yet.')),
    );
  }
}
