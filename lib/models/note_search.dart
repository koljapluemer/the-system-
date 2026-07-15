import 'note_file.dart';

/// A note found to be similar to a typed query, for accidental-duplicate
/// warnings across every note-creation entry point (the Add screen).
class NoteMatch {
  final String filename;
  final String title;
  final String primaryType;

  const NoteMatch({required this.filename, required this.title, required this.primaryType});
}

/// A single title/alias string pre-lowered and pre-tokenized, so
/// [findSimilarNotes] never re-derives them per call.
class _Candidate {
  final String lower;
  final Set<String> tokens;
  const _Candidate(this.lower, this.tokens);
}

/// A note's title/aliases pre-lowered and pre-tokenized once per note-index
/// change (see `normalizedNotesProvider`) rather than on every keystroke of
/// a similar-notes search — on a large note collection, re-deriving these
/// per keystroke was the dominant cost of the old synchronous scan.
class NormalizedNote {
  final String filename;
  final String title;
  final String primaryType;
  final _Candidate _titleCandidate;
  final List<_Candidate> _aliasCandidates;

  NormalizedNote._(
    this.filename,
    this.title,
    this.primaryType,
    this._titleCandidate,
    this._aliasCandidates,
  );

  factory NormalizedNote.from(String filename, NoteFile note) {
    final title = note['title'] as String? ?? '';
    return NormalizedNote._(
      filename,
      title,
      note['primaryType'] as String? ?? '',
      _candidateFor(title),
      [for (final alias in note.stringList('aliases')) _candidateFor(alias)],
    );
  }
}

_Candidate _candidateFor(String value) {
  final lower = value.toLowerCase();
  return _Candidate(lower, _tokensOf(lower));
}

Set<String> _tokensOf(String lower) =>
    lower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();

/// Pre-lowers and pre-tokenizes every note in [entries] once, so repeated
/// [findSimilarNotes] calls (e.g. one per debounced keystroke) only pay for
/// scoring, not for re-deriving candidate strings.
List<NormalizedNote> normalizeNotes(Map<String, NoteFile> entries) => [
      for (final entry in entries.entries) NormalizedNote.from(entry.key, entry.value),
    ];

/// Ranks [notes] by similarity of [query] to each note's title or any
/// alias, restricted to [allowedPrimaryTypes], and returns the top [limit].
/// No fuzzy-matching package is used — titles are short, so a small local
/// scorer (exact/substring/token-overlap/edit-distance) is enough to catch
/// both near-duplicates and typos without adding a dependency. Pure and
/// isolate-safe (plain data in, plain data out) — see `NoteSearchWorker`,
/// which runs this on a worker isolate so a large [notes] list never blocks
/// the UI thread.
List<NoteMatch> findSimilarNotes(
  List<NormalizedNote> notes, {
  required String query,
  required List<String> allowedPrimaryTypes,
  int limit = 3,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return [];
  final queryTokens = _tokensOf(normalizedQuery);

  final scored = <MapEntry<NoteMatch, double>>[];
  for (final note in notes) {
    if (!allowedPrimaryTypes.contains(note.primaryType)) continue;

    var bestScore = _similarity(normalizedQuery, queryTokens, note._titleCandidate);
    for (final alias in note._aliasCandidates) {
      final aliasScore = _similarity(normalizedQuery, queryTokens, alias);
      if (aliasScore > bestScore) bestScore = aliasScore;
    }

    if (bestScore > 0.3) {
      scored.add(MapEntry(
        NoteMatch(filename: note.filename, title: note.title, primaryType: note.primaryType),
        bestScore,
      ));
    }
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.take(limit).map((e) => e.key).toList();
}

double _similarity(String query, Set<String> queryTokens, _Candidate candidate) {
  if (candidate.lower.isEmpty) return 0;
  if (query == candidate.lower) return 1;
  if (candidate.lower.contains(query) || query.contains(candidate.lower)) return 0.85;

  final tokenOverlap = queryTokens.isEmpty || candidate.tokens.isEmpty
      ? 0.0
      : queryTokens.intersection(candidate.tokens).length /
          queryTokens.union(candidate.tokens).length;

  final maxLen = query.length > candidate.lower.length ? query.length : candidate.lower.length;
  final editSimilarity = maxLen == 0 ? 0.0 : 1 - (_levenshtein(query, candidate.lower) / maxLen);

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
