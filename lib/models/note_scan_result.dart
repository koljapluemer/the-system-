import 'note_file.dart';

/// One file's parsed state as yielded by [NotesService.scanNotes]: either the
/// decoded JSON object, or null if the file couldn't be parsed as one (still
/// yielded so callers can track it, e.g. for the invalid-JSON checker).
class NoteScanResult {
  final String filename;
  final NoteFile? data;

  const NoteScanResult({required this.filename, this.data});
}
