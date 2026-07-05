import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notes_service.dart';
import 'triage_notifier.dart';

class ScratchpadTriageNotifier extends TriageNotifier {
  @override
  Future<List<String>> fetchQueue(NotesService notes, String folder) =>
      notes.listScratchpadUntriaged(folder);
}

final scratchpadTriageProvider =
    NotifierProvider<ScratchpadTriageNotifier, TriageState>(ScratchpadTriageNotifier.new);
