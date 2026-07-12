/// A lightweight, read-only view of a note for the Lists management screens:
/// just enough to render a row, without the rest of the JSON payload.
class NoteSummary {
  final String filename;
  final String title;
  final String? secondaryType;

  const NoteSummary({required this.filename, required this.title, this.secondaryType});
}
