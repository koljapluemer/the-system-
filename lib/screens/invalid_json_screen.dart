import 'package:flutter/material.dart';

/// Lists the filenames flagged by [JsonSchemaService.findInvalid].
class InvalidJsonScreen extends StatelessWidget {
  final List<String> filenames;

  const InvalidJsonScreen({super.key, required this.filenames});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invalid JSON Files')),
      body: SelectionArea(
        child: ListView.separated(
          itemCount: filenames.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(filenames[index]),
          ),
        ),
      ),
    );
  }
}
