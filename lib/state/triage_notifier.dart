import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../services/notes_service.dart';
import '../widgets/undo_snackbar.dart';
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
/// Subclasses only decide which notes belong in that queue.
abstract class TriageNotifier extends Notifier<TriageState> {
  final _random = Random();
  late final String _folder;

  Future<List<String>> fetchQueue(NotesService notes, String folder);

  @override
  TriageState build() {
    _folder = ref.watch(dataFolderProvider).value!;
    Future.microtask(_init);
    return const TriageState();
  }

  Future<void> _init() async {
    final notes = ref.read(notesServiceProvider);
    final queue = await fetchQueue(notes, _folder);
    if (!ref.mounted) return;
    state = state.copyWith(queue: queue);
    await _loadNext();
  }

  String? _popRandom(List<String> queue) {
    if (queue.isEmpty) return null;
    return queue.removeAt(_random.nextInt(queue.length));
  }

  Future<void> _loadNext() async {
    final queue = [...state.queue];
    final filename = _popRandom(queue);
    if (filename == null) {
      if (!ref.mounted) return;
      state = state.copyWith(queue: queue, loading: false, clearCurrent: true);
      return;
    }
    final notes = ref.read(notesServiceProvider);
    final note = await notes.readJsonFile(_folder, filename);
    if (!ref.mounted) return;
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
    final notes = ref.read(notesServiceProvider);
    await notes.writeJsonFile(_folder, filename, {...note, 'triaged': 'true'});
    await _loadNext();
  }

  /// Deletes the current note immediately (no confirmation), offers Undo via
  /// a snackbar, and advances regardless — deletion never blocks progress.
  Future<void> delete(BuildContext context) async {
    final filename = state.currentFilename;
    final note = state.currentNote;
    if (filename == null || note == null) return;
    final notes = ref.read(notesServiceProvider);
    await notes.deleteJsonFile(_folder, filename);
    final title = note['title'] as String? ?? filename;
    if (context.mounted) {
      showUndoSnackBar(
        context,
        message: 'Deleted "$title"',
        onUndo: () async {
          await notes.writeJsonFile(_folder, filename, note);
          if (ref.mounted) {
            state = state.copyWith(queue: [...state.queue, filename]);
          }
        },
      );
    }
    await _loadNext();
  }

  /// No-op on disk — the note stays untriaged and may reappear on a future
  /// launch, but won't repeat this session since it's already been popped.
  Future<void> defer() async {
    await _loadNext();
  }
}
