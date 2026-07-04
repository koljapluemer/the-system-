/// A note file is arbitrary JSON — different flows read/write different
/// shapes. Consumers narrow to the fields they care about.
typedef NoteFile = Map<String, dynamic>;
