import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_type_spec.dart';

/// Per-primaryType secondaryType values currently visible in that type's list
/// view, and the secondaryType most recently chosen (at creation or via
/// edit) for that primaryType — both intentionally in-memory only, resetting
/// on app restart, like every other provider in this app (see
/// AddTypeUsageNotifier). Neither is written to disk.
class SecondaryTypeFilterNotifier extends Notifier<Map<String, Set<String>>> {
  @override
  Map<String, Set<String>> build() => {};

  Set<String> visibleFor(NoteTypeSpec spec) =>
      state[spec.primaryType] ?? spec.effectiveDefaultVisible.toSet();

  void setVisible(String primaryType, Set<String> visible) {
    state = {...state, primaryType: visible};
  }
}

final secondaryTypeFilterProvider =
    NotifierProvider<SecondaryTypeFilterNotifier, Map<String, Set<String>>>(
        SecondaryTypeFilterNotifier.new);

class LastSecondaryTypeNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  String defaultFor(NoteTypeSpec spec) => state[spec.primaryType] ?? spec.defaultSecondaryType;

  void record(String primaryType, String secondaryType) {
    state = {...state, primaryType: secondaryType};
  }
}

final lastSecondaryTypeProvider =
    NotifierProvider<LastSecondaryTypeNotifier, Map<String, String>>(LastSecondaryTypeNotifier.new);
