import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks how many notes of each `primaryType` have been created via the Add
/// screen this app session, so it can surface quick-select buttons for the
/// types used most. Intentionally in-memory only — resets on app restart,
/// like every other provider in this app.
class AddTypeUsageNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  void recordAdd(String primaryType) {
    state = {...state, primaryType: (state[primaryType] ?? 0) + 1};
  }
}

final addTypeUsageProvider =
    NotifierProvider<AddTypeUsageNotifier, Map<String, int>>(AddTypeUsageNotifier.new);
