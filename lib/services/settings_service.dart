import 'package:shared_preferences/shared_preferences.dart';

/// Persists the single data-folder path setting.
class SettingsService {
  const SettingsService();

  static const _dataFolderKey = 'dataFolder';

  Future<String?> getDataFolder() async {
    final prefs = SharedPreferencesAsync();
    return prefs.getString(_dataFolderKey);
  }

  Future<void> setDataFolder(String path) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_dataFolderKey, path);
  }
}
