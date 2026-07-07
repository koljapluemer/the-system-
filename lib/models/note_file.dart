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
}
