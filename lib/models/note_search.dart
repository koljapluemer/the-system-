import 'note_file.dart';

/// A note found to be similar to a typed query, for accidental-duplicate
/// warnings across every note-creation entry point (the Add screen).
class NoteMatch {
  final String filename;
  final String title;
  final String primaryType;

  const NoteMatch({required this.filename, required this.title, required this.primaryType});
}

/// Ranks [entries] by similarity of [query] to each note's title or any
/// alias, restricted to [allowedPrimaryTypes], and returns the top [limit].
/// No fuzzy-matching package is used — titles are short, so a small local
/// scorer (exact/substring/token-overlap/edit-distance) is enough to catch
/// both near-duplicates and typos without adding a dependency.
List<NoteMatch> findSimilarNotes(
  Map<String, NoteFile> entries, {
  required String query,
  required List<String> allowedPrimaryTypes,
  int limit = 3,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return [];

  final scored = <MapEntry<NoteMatch, double>>[];
  for (final entry in entries.entries) {
    final primaryType = entry.value['primaryType'] as String?;
    if (primaryType == null || !allowedPrimaryTypes.contains(primaryType)) continue;

    final title = entry.value['title'] as String? ?? '';
    var bestScore = _similarity(normalizedQuery, title.toLowerCase());
    for (final alias in entry.value.stringList('aliases')) {
      final aliasScore = _similarity(normalizedQuery, alias.toLowerCase());
      if (aliasScore > bestScore) bestScore = aliasScore;
    }

    if (bestScore > 0.3) {
      scored.add(MapEntry(
        NoteMatch(filename: entry.key, title: title, primaryType: primaryType),
        bestScore,
      ));
    }
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.take(limit).map((e) => e.key).toList();
}

double _similarity(String query, String candidate) {
  if (candidate.isEmpty) return 0;
  if (query == candidate) return 1;
  if (candidate.contains(query) || query.contains(candidate)) return 0.85;

  final queryTokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();
  final candidateTokens = candidate.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();
  final tokenOverlap = queryTokens.isEmpty || candidateTokens.isEmpty
      ? 0.0
      : queryTokens.intersection(candidateTokens).length /
          queryTokens.union(candidateTokens).length;

  final maxLen = query.length > candidate.length ? query.length : candidate.length;
  final editSimilarity = maxLen == 0 ? 0.0 : 1 - (_levenshtein(query, candidate) / maxLen);

  return tokenOverlap > editSimilarity ? tokenOverlap : editSimilarity;
}

int _levenshtein(String a, String b) {
  final rows = a.length + 1;
  final cols = b.length + 1;
  var previous = List<int>.generate(cols, (j) => j);
  var current = List<int>.filled(cols, 0);

  for (var i = 1; i < rows; i++) {
    current[0] = i;
    for (var j = 1; j < cols; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [
        current[j - 1] + 1,
        previous[j] + 1,
        previous[j - 1] + cost,
      ].reduce((v, e) => v < e ? v : e);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[cols - 1];
}
