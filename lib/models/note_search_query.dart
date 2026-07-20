import 'note_file.dart';

/// A note whose title, content, aliases, or any other top-level
/// string/string-list field contains the search query (see [searchNotes]).
class NoteSearchResult {
  final String filename;
  final String title;
  final String primaryType;

  const NoteSearchResult({required this.filename, required this.title, required this.primaryType});
}

/// Case-insensitive substring search across every top-level string and
/// string-list field of each note in [entries] — title, content,
/// aliases, etc. Unlike [findSimilarNotes] (see `note_search.dart`), this is
/// plain `contains`, not fuzzy scoring, and scans every field rather than
/// just title/aliases, so it also matches content text. A synchronous
/// scan is fine: note collections here are personal-scale, and substring
/// `contains` is far cheaper than the Levenshtein scorer that justified
/// `NoteSearchWorker`'s isolate for the Add screen.
///
/// Known limitation: only scans top-level `String`/`List<String>` values, so it
/// won't match inside the nested `questions` map or `rels` pairs (see
/// `NoteFileQuestions`/`NoteFileArrays` in `note_file.dart`). Acceptable for
/// v1.
List<NoteSearchResult> searchNotes(Map<String, NoteFile> entries, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return [];

  final results = <NoteSearchResult>[];
  for (final entry in entries.entries) {
    if (_noteContains(entry.value, normalizedQuery)) {
      results.add(NoteSearchResult(
        filename: entry.key,
        title: entry.value['title'] as String? ?? entry.key,
        primaryType: entry.value['primaryType'] as String? ?? '',
      ));
    }
  }
  results.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  return results;
}

bool _noteContains(NoteFile note, String normalizedQuery) {
  for (final value in note.values) {
    if (value is String && value.toLowerCase().contains(normalizedQuery)) return true;
    if (value is List) {
      for (final item in value) {
        if (item is String && item.toLowerCase().contains(normalizedQuery)) return true;
      }
    }
  }
  return false;
}
