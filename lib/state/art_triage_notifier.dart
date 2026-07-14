import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_index.dart';
import 'triage_notifier.dart';

class ArtTriageNotifier extends TriageNotifier {
  @override
  String get primaryType => 'art';

  /// Once every art note has been explicitly triaged, keep the flow going
  /// as idle browsing — pick from every art note (triaged or not) at
  /// random — rather than dead-ending on "all caught up".
  @override
  List<String> fallbackPool(NoteIndex index) =>
      [for (final s in index.summariesOfType('art')) s.filename];
}

final artTriageProvider =
    NotifierProvider<ArtTriageNotifier, TriageState>(ArtTriageNotifier.new);
