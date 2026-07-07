import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../widgets/undo_snackbar.dart';
import 'note_index_notifier.dart';
import 'providers.dart';

class TriageState {
  final bool loading;
  final List<String> queue;
  final String? currentFilename;
  final NoteFile? currentNote;

  const TriageState({
    this.loading = true,
    this.queue = const [],
    this.currentFilename,
    this.currentNote,
  });

  TriageState copyWith({
    bool? loading,
    List<String>? queue,
    String? currentFilename,
    NoteFile? currentNote,
    bool clearCurrent = false,
  }) {
    return TriageState(
      loading: loading ?? this.loading,
      queue: queue ?? this.queue,
      currentFilename: clearCurrent ? null : (currentFilename ?? this.currentFilename),
      currentNote: clearCurrent ? null : (currentNote ?? this.currentNote),
    );
  }
}

/// Shared triage flow ported from the old ScratchpadTriage.vue: load an
/// untriaged queue once, then repeatedly pop a random note and act on it.
/// Subclasses only decide which primaryType belongs in that queue.
abstract class TriageNotifier extends Notifier<TriageState> {
  final _random = Random();
  int _generation = 0;

  String get primaryType;

  @override
  TriageState build() {
    // Watched purely as a rebuild trigger: if the user switches the data
    // folder mid-session (reachable from any screen via Home's "change data
    // folder" button), the queue must be rebuilt against the new folder's
    // index rather than silently keep showing the old one.
    ref.watch(dataFolderProvider);
    final generation = ++_generation;
    Future.microtask(() => _init(generation));
    return const TriageState();
  }

  Future<void> _init(int generation) async {
    final index = await ref.read(noteIndexProvider.future);
    if (!ref.mounted || generation != _generation) return;
    state = state.copyWith(queue: index.untriagedOfType(primaryType));
    await _loadNext(generation);
  }

  String? _popRandom(List<String> queue) {
    if (queue.isEmpty) return null;
    return queue.removeAt(_random.nextInt(queue.length));
  }

  Future<void> _loadNext(int generation) async {
    if (generation != _generation) return;
    final queue = [...state.queue];
    final filename = _popRandom(queue);
    if (filename == null) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(queue: queue, loading: false, clearCurrent: true);
      return;
    }
    final note = ref.read(noteIndexProvider).value?.entries[filename];
    if (note == null) {
      // Gone (or never valid) by the time we got to it; skip it.
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(queue: queue);
      await _loadNext(generation);
      return;
    }
    if (!ref.mounted || generation != _generation) return;
    state = state.copyWith(
      queue: queue,
      loading: false,
      currentFilename: filename,
      currentNote: note,
    );
  }

  Future<void> keep() async {
    final filename = state.currentFilename;
    final note = state.currentNote;
    if (filename == null || note == null) return;
    await ref.read(noteIndexProvider.notifier).write(filename, {...note, 'triaged': 'true'});
    await _loadNext(_generation);
  }

  /// Deletes the current note immediately (no confirmation), offers Undo via
  /// a snackbar, and advances regardless — deletion never blocks progress.
  Future<void> delete(BuildContext context) async {
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
        onUndo: () async {
          await indexNotifier.write(filename, note);
          if (ref.mounted) {
            state = state.copyWith(queue: [...state.queue, filename]);
          }
        },
      );
    }
    await _loadNext(_generation);
  }

  /// No-op on disk — the note stays untriaged and may reappear on a future
  /// launch, but won't repeat this session since it's already been popped.
  Future<void> defer() async {
    await _loadNext(_generation);
  }
}
