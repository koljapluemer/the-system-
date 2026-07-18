import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import 'note_index_notifier.dart';
import 'providers.dart';

/// The hardcoded pool of prompt questions Netting asks about a note,
/// cleaned to plaintext from docs/questions.md (wikilinks, markdown, and
/// emoji glyphs stripped, near-duplicates merged).
const nettingQuestions = <String>[
  'What exactly is this?',
  'Why must this be true?',
  'Would I bet money on this being true?',
  'If you change one part of the concept, what happens?',
  'If you change one part of the problem, what happens?',
  'Which other solutions apply?',
  'How can this concept be broken?',
  'What if you delete this hypothesis?',
  'How can this be proven in a stronger way?',
  'How can this be confirmed in a different way?',
  'What is implied?',
  'What are we talking about?',
  'Why is this important?',
  'How important is this?',
  'What does this enable me to do?',
  'What does this not enable?',
  'Where can I find further knowledge on this?',
  'Who are the experts on this?',
  'Where does this come from?',
  "What's similar to this?",
  "What's opposed to this?",
  'Where does this lead?',
  'How does this fit into my broader understanding?',
  'How can this be explained by another theory?',
  "Isn't this similar to something else?",
  'Haven\'t I heard this before?',
  'What does this mean for something else?',
  'What if the opposite were true?',
  'What is interesting about this?',
  'Which questions does this help answer?',
  'How can this be reframed or expressed differently?',
  'How does this work with, or conflict with, another theory?',
];

class NettingState {
  final bool loading;
  final String? currentFilename;
  final NoteFile? currentNote;
  final String? currentQuestion;

  const NettingState({
    this.loading = true,
    this.currentFilename,
    this.currentNote,
    this.currentQuestion,
  });

  NettingState copyWith({
    bool? loading,
    String? currentFilename,
    NoteFile? currentNote,
    String? currentQuestion,
    bool clearCurrent = false,
  }) {
    return NettingState(
      loading: loading ?? this.loading,
      currentFilename: clearCurrent ? null : (currentFilename ?? this.currentFilename),
      currentNote: clearCurrent ? null : (currentNote ?? this.currentNote),
      currentQuestion: clearCurrent ? null : (currentQuestion ?? this.currentQuestion),
    );
  }
}

/// Drives the Netting flow: repeatedly picks a random `ifThen`/`description`
/// note that still has an unanswered [nettingQuestions] entry, asks one such
/// question, and records the answer (or "not relevant") onto the note's
/// `questions` field. Mirrors [MemorizeNotifier]'s pick-show-act-advance
/// shape, recomputing eligible pools fresh from the index on every
/// [_loadNext] rather than snapshotting a queue up front.
class NettingNotifier extends Notifier<NettingState> {
  final _random = Random();
  int _generation = 0;

  /// The most recently shown note's filename, excluded from the next pick
  /// (when another candidate exists) so the same note never comes up twice
  /// in a row.
  String? _lastShownFilename;

  @override
  NettingState build() {
    ref.watch(dataFolderProvider);
    final generation = ++_generation;
    Future.microtask(() => _loadNext(generation));
    return const NettingState();
  }

  List<String> _remainingQuestions(NoteFile note) {
    final answered = note.questionsMap.keys.toSet();
    return [for (final q in nettingQuestions) if (!answered.contains(q)) q];
  }

  List<MapEntry<String, NoteFile>> _eligibleEntries() {
    final index = ref.read(noteIndexProvider).value;
    if (index == null) return [];
    return [
      for (final e in index.entries.entries)
        if ((e.value['primaryType'] == 'ifThen' || e.value['primaryType'] == 'description') &&
            _remainingQuestions(e.value).isNotEmpty)
          e,
    ];
  }

  Future<void> _loadNext(int generation) async {
    // Await the index once so the very first load (before noteIndexProvider
    // has resolved) doesn't race an empty snapshot.
    await ref.read(noteIndexProvider.future);
    if (!ref.mounted || generation != _generation) return;

    final entries = _eligibleEntries();
    if (entries.isEmpty) {
      state = state.copyWith(loading: false, clearCurrent: true);
      return;
    }

    // Avoid immediately repeating the note just shown, unless it's the only
    // candidate available.
    final withoutLast = [for (final e in entries) if (e.key != _lastShownFilename) e];
    final pool = withoutLast.isNotEmpty ? withoutLast : entries;

    final picked = pool[_random.nextInt(pool.length)];
    final remaining = _remainingQuestions(picked.value);
    final question = remaining[_random.nextInt(remaining.length)];
    _lastShownFilename = picked.key;
    state = state.copyWith(
      loading: false,
      currentFilename: picked.key,
      currentNote: picked.value,
      currentQuestion: question,
    );
  }

  Future<void> _recordAnswer(Object value) async {
    final filename = state.currentFilename;
    final note = state.currentNote;
    final question = state.currentQuestion;
    if (filename == null || note == null || question == null) return;
    final updated = {
      ...note,
      'questions': {...note.questionsMap, question: value},
    };
    await ref.read(noteIndexProvider.notifier).write(filename, updated);
    await _loadNext(_generation);
  }

  Future<void> save(String answer) => _recordAnswer(answer);

  Future<void> markNotRelevant() => _recordAnswer(false);

  /// Loads a new random note/question without persisting anything for the
  /// current one.
  Future<void> defer() => _loadNext(_generation);
}

final nettingProvider = NotifierProvider<NettingNotifier, NettingState>(NettingNotifier.new);
