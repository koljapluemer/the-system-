/// A lightweight, read-only view of a note for the floating-notes canvas:
/// just enough to render a card, without the rest of the JSON payload.
class FloatingNoteEntry {
  final String filename;
  final String title;
  final String body;

  const FloatingNoteEntry({
    required this.filename,
    required this.title,
    required this.body,
  });
}
