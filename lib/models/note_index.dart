import 'floating_note_entry.dart';
import 'note_file.dart';
import 'note_summary.dart';

/// A snapshot of every note in the data folder, held in memory so the app's
/// various flows (triage queues, the Lists screens, the floating-notes
/// canvas, the invalid-JSON checker) can filter it locally instead of each
/// independently re-scanning disk. Built and kept in sync by
/// NoteIndexNotifier; this class itself is a plain, disk-free data holder.
class NoteIndex {
  /// filename -> decoded content, for files that parsed as a JSON object.
  final Map<String, NoteFile> entries;

  /// Filenames that failed to decode as a JSON object at all.
  final Set<String> unparsable;

  const NoteIndex({this.entries = const {}, this.unparsable = const {}});

  NoteIndex copyWith({Map<String, NoteFile>? entries, Set<String>? unparsable}) {
    return NoteIndex(
      entries: entries ?? this.entries,
      unparsable: unparsable ?? this.unparsable,
    );
  }

  /// Notes of [primaryType] that haven't been triaged yet (`triaged` isn't
  /// the literal string `"true"`).
  List<String> untriagedOfType(String primaryType) => [
        for (final e in entries.entries)
          if (e.value['primaryType'] == primaryType && e.value['triaged'] != 'true') e.key,
      ];

  /// Summaries (filename + title) of every note of [primaryType], regardless
  /// of triaged status.
  List<NoteSummary> summariesOfType(String primaryType) => [
        for (final e in entries.entries)
          if (e.value['primaryType'] == primaryType)
            NoteSummary(filename: e.key, title: e.value['title'] as String? ?? ''),
      ];

  /// Summaries of hypothesis notes currently in [status] (e.g. "ACTIVE"),
  /// for the dedicated Hypotheses screen.
  List<NoteSummary> hypothesesWithStatus(String status) => [
        for (final e in entries.entries)
          if (e.value['primaryType'] == 'hypothesis' && e.value['status'] == status)
            NoteSummary(filename: e.key, title: e.value['title'] as String? ?? ''),
      ];

  /// Notes eligible for the floating-notes canvas: `primaryType ==
  /// "scratchpad"` notes that have already been triaged.
  List<FloatingNoteEntry> floatingPool() => [
        for (final e in entries.entries)
          if (e.value['primaryType'] == 'scratchpad' && e.value['triaged'] == 'true')
            FloatingNoteEntry(
              filename: e.key,
              title: e.value['title'] as String? ?? '',
              body: e.value['body'] as String? ?? '',
            ),
      ];
}
