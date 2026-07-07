import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'triage_notifier.dart';

class ScratchpadTriageNotifier extends TriageNotifier {
  @override
  String get primaryType => 'scratchpad';
}

final scratchpadTriageProvider =
    NotifierProvider<ScratchpadTriageNotifier, TriageState>(ScratchpadTriageNotifier.new);
