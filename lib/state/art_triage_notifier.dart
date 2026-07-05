import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notes_service.dart';
import 'triage_notifier.dart';

class ArtTriageNotifier extends TriageNotifier {
  @override
  Future<List<String>> fetchQueue(NotesService notes, String folder) =>
      notes.listArtUntriaged(folder);
}

final artTriageProvider =
    NotifierProvider<ArtTriageNotifier, TriageState>(ArtTriageNotifier.new);
