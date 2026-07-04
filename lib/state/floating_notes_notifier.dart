import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/floating_note_entry.dart';
import 'providers.dart';

/// How often accumulated matches are pushed into state while the scan is
/// still running. Flushing per-match would rebuild the screen once per file
/// in a huge folder; flushing on a timer bounds that to a handful of
/// rebuilds regardless of vault size.
const _flushInterval = Duration(milliseconds: 400);

class FloatingNotesState {
  final List<FloatingNoteEntry> notes;
  final bool loading;

  const FloatingNotesState({this.notes = const [], this.loading = true});

  FloatingNotesState copyWith({List<FloatingNoteEntry>? notes, bool? loading}) {
    return FloatingNotesState(
      notes: notes ?? this.notes,
      loading: loading ?? this.loading,
    );
  }
}

/// Streams the pool of notes eligible for the floating-notes canvas,
/// surfacing matches incrementally so the canvas can start spawning cards
/// long before a large vault finishes scanning.
class FloatingNotesNotifier extends Notifier<FloatingNotesState> {
  StreamSubscription<FloatingNoteEntry>? _subscription;
  Timer? _flushTimer;
  final List<FloatingNoteEntry> _pending = [];

  @override
  FloatingNotesState build() {
    final folder = ref.watch(dataFolderProvider).value!;
    final stream = ref.read(notesServiceProvider).streamFloatingNotes(folder);

    _subscription = stream.listen(
      _pending.add,
      onDone: () {
        _flush();
        state = state.copyWith(loading: false);
      },
    );
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flush());

    ref.onDispose(_stop);
    return const FloatingNotesState();
  }

  void _flush() {
    if (_pending.isEmpty) return;
    state = FloatingNotesState(notes: [...state.notes, ..._pending], loading: false);
    _pending.clear();
  }

  void _stop() {
    _subscription?.cancel();
    _flushTimer?.cancel();
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
