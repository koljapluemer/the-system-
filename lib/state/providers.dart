import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/json_schema_service.dart';
import '../services/notes_service.dart';
import '../services/settings_service.dart';
import '../services/storage_permission_service.dart';

final notesServiceProvider = Provider<NotesService>((ref) => const NotesService());

final jsonSchemaServiceProvider =
    Provider<JsonSchemaService>((ref) => const JsonSchemaService());

final settingsServiceProvider = Provider<SettingsService>((ref) => const SettingsService());

final storagePermissionServiceProvider =
    Provider<StoragePermissionService>((ref) => const StoragePermissionService());

class DataFolderNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() {
    return ref.watch(settingsServiceProvider).getDataFolder();
  }

  Future<void> setFolder(String path) async {
    await ref.read(settingsServiceProvider).setDataFolder(path);
    state = AsyncValue.data(path);
  }
}

final dataFolderProvider = AsyncNotifierProvider<DataFolderNotifier, String?>(DataFolderNotifier.new);

/// Android-only permission gate; always reports granted on other platforms
/// (see [StoragePermissionService]).
class StoragePermissionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(storagePermissionServiceProvider).isGranted();
  }

  Future<void> requestAccess() {
    return ref.read(storagePermissionServiceProvider).request();
  }

  /// Re-checks the grant, e.g. after the user returns from Android's
  /// settings screen — they may have backed out without toggling it.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final storagePermissionProvider =
    AsyncNotifierProvider<StoragePermissionNotifier, bool>(StoragePermissionNotifier.new);
