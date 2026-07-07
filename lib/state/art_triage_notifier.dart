import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'triage_notifier.dart';

class ArtTriageNotifier extends TriageNotifier {
  @override
  String get primaryType => 'art';
}

final artTriageProvider =
    NotifierProvider<ArtTriageNotifier, TriageState>(ArtTriageNotifier.new);
