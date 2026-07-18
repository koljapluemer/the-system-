/// A note file is arbitrary JSON — different flows read/write different
/// shapes. Consumers narrow to the fields they care about.
typedef NoteFile = Map<String, dynamic>;

/// Defensive reads for array-valued fields, mirroring the `as String? ?? ''`
/// convention used for scalar fields elsewhere — a missing key, wrong type,
/// or mixed-type list (e.g. from a hand-edited file) degrades to `[]`/dropped
/// elements instead of throwing.
extension NoteFileArrays on NoteFile {
  List<String> stringList(String key) {
    final value = this[key];
    return value is List ? value.whereType<String>().toList() : [];
  }

  /// Defensive read of `rels`-shaped fields: a list of `[type, filename]`
  /// pairs. Malformed entries (wrong length/type) are dropped rather than
  /// thrown, matching [stringList]'s convention.
  List<List<String>> stringPairList(String key) {
    final value = this[key];
    if (value is! List) return [];
    return [
      for (final entry in value)
        if (entry is List && entry.length == 2 && entry.every((e) => e is String))
          entry.cast<String>(),
    ];
  }
}

/// Defensive read of `questions`-shaped fields: a map of question text to
/// either a free-text answer or `false` (marked not relevant). Non-object
/// values and entries with the wrong key/value type are dropped, matching
/// [NoteFileArrays]'s conventions.
extension NoteFileQuestions on NoteFile {
  Map<String, dynamic> get questionsMap {
    final raw = this['questions'];
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (e.key is String && (e.value is String || e.value == false)) e.key as String: e.value,
    };
  }
}
