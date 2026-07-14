import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../models/note_file.dart';
import '../services/fsrs_service.dart' as fsrs_service;
import '../widgets/undo_snackbar.dart';
import 'note_index_notifier.dart';
import 'providers.dart';

class MemorizeState {
  final bool loading;
  final String? currentFilename;
  final NoteFile? currentNote;

  /// True when [currentNote] has never been practiced (no fsrs data yet) —
  /// such a card opens already revealed, with only "I will remember"
  /// offered instead of the four grading buttons.
  final bool isNew;
  final bool revealed;

  /// True when this "turn" is an art-triage interstitial instead of a
  /// flashcard — [currentNote] is null in that case.
  final bool showArtTriage;

  const MemorizeState({
    this.loading = true,
    this.currentFilename,
    this.currentNote,
    this.isNew = false,
    this.revealed = false,
    this.showArtTriage = false,
  });

  MemorizeState copyWith({
    bool? loading,
    String? currentFilename,
    NoteFile? currentNote,
    bool? isNew,
    bool? revealed,
    bool? showArtTriage,
    bool clearCurrent = false,
  }) {
    return MemorizeState(
      loading: loading ?? this.loading,
      currentFilename: clearCurrent ? null : (currentFilename ?? this.currentFilename),
      currentNote: clearCurrent ? null : (currentNote ?? this.currentNote),
      isNew: isNew ?? this.isNew,
      revealed: revealed ?? this.revealed,
      showArtTriage: showArtTriage ?? this.showArtTriage,
    );
  }
}

/// Drives the Memorize flow: repeatedly picks a random due (or, failing
/// that, brand-new) `flashcard` note, tracks reveal state, and applies fsrs
/// grading on review. Unlike [TriageNotifier], pools are recomputed fresh
/// from the current index on every [_loadNext] rather than snapshotted into
/// a queue up front — a just-reviewed card naturally drops out of the due
/// pool once its new due date is in the future, so no manual bookkeeping is
/// needed.
class MemorizeNotifier extends Notifier<MemorizeState> {
  final _random = Random();
  int _generation = 0;

  /// The most recently shown flashcard's filename, excluded from the next
  /// pick (when another candidate exists) so the same card never comes up
  /// twice in a row.
  String? _lastShownFilename;

  @override
  MemorizeState build() {
    // Watched purely as a rebuild trigger, matching TriageNotifier: if the
    // data folder is switched mid-session, the flow must restart against
    // the new folder's index rather than keep showing stale notes.
    ref.watch(dataFolderProvider);
    final generation = ++_generation;
    Future.microtask(() => _loadNext(generation));
    return const MemorizeState();
  }

  List<MapEntry<String, NoteFile>> _flashcardEntries() {
    final index = ref.read(noteIndexProvider).value;
    if (index == null) return [];
    return [
      for (final e in index.entries.entries)
        if (e.value['primaryType'] == 'flashcard') e,
    ];
  }

  Future<void> _loadNext(int generation) async {
    // Await the index once so the very first load (before noteIndexProvider
    // has resolved) doesn't race an empty snapshot.
    await ref.read(noteIndexProvider.future);
    if (!ref.mounted || generation != _generation) return;

    if (_random.nextInt(6) == 0) {
      state = state.copyWith(loading: false, showArtTriage: true, clearCurrent: true);
      return;
    }

    final entries = _flashcardEntries();
    final now = DateTime.now().toUtc();
    final due = [
      for (final e in entries)
        if (!fsrs_service.isNewFlashcard(e.value) &&
            !fsrs_service.dueDate(e.value)!.isAfter(now))
          e,
    ];
    final fresh = [for (final e in entries) if (fsrs_service.isNewFlashcard(e.value)) e];

    final rawPool = due.isNotEmpty ? due : fresh;
    if (rawPool.isEmpty) {
      state = state.copyWith(loading: false, showArtTriage: false, clearCurrent: true);
      return;
    }

    // Avoid immediately repeating the card just shown, unless it's the only
    // candidate available.
    final withoutLast = [for (final e in rawPool) if (e.key != _lastShownFilename) e];
    final pool = withoutLast.isNotEmpty ? withoutLast : rawPool;

    final picked = pool[_random.nextInt(pool.length)];
    final isNew = due.isEmpty;
    _lastShownFilename = picked.key;
    state = state.copyWith(
      loading: false,
      showArtTriage: false,
      currentFilename: picked.key,
      currentNote: picked.value,
      isNew: isNew,
      revealed: isNew,
    );
  }

  void reveal() {
    if (state.currentNote == null) return;
    state = state.copyWith(revealed: true);
  }

  /// Creates the initial fsrs card for the current (new) flashcard. Only
  /// valid when [MemorizeState.isNew].
  Future<void> rememberNew() async {
    final filename = state.currentFilename;
    final note = state.currentNote;
    if (filename == null || note == null) return;
    final updated = await fsrs_service.initializeFlashcard(note);
    await ref.read(noteIndexProvider.notifier).write(filename, updated);
    await _loadNext(_generation);
  }

  /// Grades the current (already-practiced) flashcard. Only valid when
  /// `!MemorizeState.isNew`.
  Future<void> rate(fsrs.Rating rating) async {
    final filename = state.currentFilename;
    final note = state.currentNote;
    if (filename == null || note == null) return;
    final updated = fsrs_service.reviewFlashcard(note, rating);
    await ref.read(noteIndexProvider.notifier).write(filename, updated);
    await _loadNext(_generation);
  }

  /// Deletes the current flashcard immediately, offers Undo, and advances
  /// regardless — matching TriageNotifier.delete's convention.
  Future<void> deleteCurrent(BuildContext context) async {
    final filename = state.currentFilename;
    final note = state.currentNote;
    if (filename == null || note == null) return;
    final indexNotifier = ref.read(noteIndexProvider.notifier);
    await indexNotifier.delete(filename);
    final title = note['title'] as String? ?? filename;
    if (context.mounted) {
      showUndoSnackBar(
        context,
        message: 'Deleted "$title"',
        onUndo: () => indexNotifier.write(filename, note),
      );
    }
    await _loadNext(_generation);
  }

  /// Resumes the flow after the pushed art-triage interstitial is popped.
  Future<void> continueAfterArtTriage() async {
    await _loadNext(_generation);
  }
}

final memorizeProvider = NotifierProvider<MemorizeNotifier, MemorizeState>(MemorizeNotifier.new);
