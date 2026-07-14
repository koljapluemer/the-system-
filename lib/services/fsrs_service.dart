import 'package:fsrs/fsrs.dart' as fsrs;

import '../models/note_file.dart';

/// The only file that talks to `package:fsrs` directly — everything else
/// works with plain `NoteFile` maps. `fsrs.Card.toMap()`/`fromMap()` already
/// convert `due`/`lastReview` to/from ISO-8601 strings internally, so the
/// maps returned here are already JSON-safe for `NoteIndexNotifier.write`.
final _scheduler = fsrs.Scheduler();

/// Whether [note] (a `primaryType: "flashcard"` note) has never been
/// practiced — no fsrs card has been created for it yet.
bool isNewFlashcard(NoteFile note) => note['fsrs'] == null;

/// The next due date of [note]'s card, or null if it's never been practiced.
DateTime? dueDate(NoteFile note) {
  final data = note['fsrs'] as Map<String, dynamic>?;
  if (data == null) return null;
  return fsrs.Card.fromMap(data).due;
}

/// Stamps a freshly-created fsrs card onto [note], for the "I will
/// remember" action on a brand-new flashcard. [note] must be new (see
/// [isNewFlashcard]).
Future<NoteFile> initializeFlashcard(NoteFile note) async {
  final card = await fsrs.Card.create();
  return {...note, 'fsrs': card.toMap()};
}

/// Grades [note]'s existing card with [rating], returning the note with its
/// updated fsrs data. [note] must not be new (see [isNewFlashcard]).
NoteFile reviewFlashcard(NoteFile note, fsrs.Rating rating) {
  final card = fsrs.Card.fromMap(note['fsrs'] as Map<String, dynamic>);
  final review = _scheduler.reviewCard(card, rating);
  return {...note, 'fsrs': review.card.toMap()};
}
