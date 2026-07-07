import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/floating_note_entry.dart';
import 'note_index_notifier.dart';

class FloatingNotesState {
  final List<FloatingNoteEntry> notes;
  final bool loading;

  const FloatingNotesState({this.notes = const [], this.loading = true});
}

/// Derives the pool of notes eligible for the floating-notes canvas from the
/// shared note index — reactively recomputed whenever the index changes
/// (rare: only on user-driven writes/deletes elsewhere in the app).
class FloatingNotesNotifier extends Notifier<FloatingNotesState> {
  @override
  FloatingNotesState build() {
    final asyncIndex = ref.watch(noteIndexProvider);
    return FloatingNotesState(
      notes: asyncIndex.value?.floatingPool() ?? const [],
      loading: asyncIndex.isLoading,
    );
  }
}

final floatingNotesProvider =
    NotifierProvider<FloatingNotesNotifier, FloatingNotesState>(FloatingNotesNotifier.new);

/// Free text filter applied to note title/body; kept separate from the note
/// pool so typing doesn't re-trigger a disk read.
class FloatingNotesFilterNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final floatingNotesFilterProvider =
    NotifierProvider<FloatingNotesFilterNotifier, String>(FloatingNotesFilterNotifier.new);
