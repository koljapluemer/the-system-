import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Android's "All files access" (MANAGE_EXTERNAL_STORAGE) is what lets us use
/// plain filesystem paths shared with other apps (e.g. Syncthing) instead of
/// SAF content:// URIs. Not applicable on Linux, where plain paths just work.
class StoragePermissionService {
  const StoragePermissionService();

  Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    return Permission.manageExternalStorage.isGranted;
  }

  /// Opens Android's "Allow access to manage all files" settings screen for
  /// this app. Does not itself confirm the grant — re-check [isGranted]
  /// after the user returns to the app.
  Future<void> request() async {
    if (!Platform.isAndroid) return;
    await Permission.manageExternalStorage.request();
  }
}
