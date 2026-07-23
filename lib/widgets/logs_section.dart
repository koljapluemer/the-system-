import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/note_file.dart';
import '../models/note_index.dart';
import '../models/note_type_spec.dart';
import '../screens/note_editor_navigation.dart';
import 'relationship_dialog.dart';

final _logNoteTypeSpec = noteTypeSpecs.firstWhere((s) => s.primaryType == 'log');

/// Human-readable, minute-granularity formatting for a log's `createdAt`,
/// per Flutter's recommended `intl` `DateFormat` approach rather than
/// hand-rolled string formatting.
final _timestampFormat = DateFormat.yMMMd().add_Hm();

class _LogEntry {
  final String filename;
  final String title;
  final DateTime? createdAt;

  const _LogEntry({required this.filename, required this.title, required this.createdAt});
}

/// Expandable "Logs" section for note types that accumulate timestamped log
/// entries (see [NoteTypeSpec.showLogs] — currently milestone): every
/// related `log` note (relType `log`), newest first, plus an
/// "Add Log" button that reuses the generic relationship-attach flow. New
/// logs get their `createdAt` stamped automatically by
/// [NoteIndexNotifier.createLog] (via [AddScreen]'s `log` special-case), not
/// entered by hand.
class LogsSection extends ConsumerWidget {
  final String filename;
  final NoteFile note;
  final NoteIndex index;

  const LogsSection({super.key, required this.filename, required this.note, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = [
      for (final rel in note.relList('rels'))
        if (rel[0] == 'log' && index.entries[rel[1]] != null)
          _LogEntry(
            filename: rel[1],
            title: index.entries[rel[1]]!['title'] as String? ?? rel[1],
            createdAt: DateTime.tryParse(index.entries[rel[1]]!['createdAt'] as String? ?? ''),
          ),
    ]..sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Logs (${entries.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: [
              if (entries.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('—')),
              for (final entry in entries)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.title),
                  subtitle: Text(
                    entry.createdAt == null ? 'unknown time' : _timestampFormat.format(entry.createdAt!),
                  ),
                  onTap: () => pushNoteEditor(context, spec: _logNoteTypeSpec, filename: entry.filename),
                ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_link),
            label: const Text('Add Log'),
            onPressed: () => showRelationshipDialog(
              context,
              ref,
              filename: filename,
              fixedLabel: 'log',
              allowedPrimaryTypes: const ['log'],
              dialogTitle: 'Add Log',
            ),
          ),
        ),
      ],
    );
  }
}
