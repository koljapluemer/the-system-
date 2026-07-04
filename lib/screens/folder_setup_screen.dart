import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// Shown both as the first-run flow (no folder set yet) and pushed as a
/// "change folder" screen from Home. Branches by platform: Linux gets a
/// native GTK folder picker (a real path, no SAF involved); Android skips
/// any picker entirely — it requests MANAGE_EXTERNAL_STORAGE, then asks for
/// a plain path via a text field, since Android has no picker that returns
/// a real filesystem path.
class FolderSetupScreen extends ConsumerStatefulWidget {
  const FolderSetupScreen({super.key});

  @override
  ConsumerState<FolderSetupScreen> createState() => _FolderSetupScreenState();
}

class _FolderSetupScreenState extends ConsumerState<FolderSetupScreen>
    with WidgetsBindingObserver {
  final _pathController = TextEditingController(
    text: '/storage/emulated/0/Documents/the-system',
  );
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pathController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user may be returning from Android's "All files access" settings
      // screen — re-check rather than trusting the request call alone, since
      // they could have backed out without toggling it.
      ref.read(storagePermissionProvider.notifier).refresh();
    }
  }

  Future<void> _pickLinuxFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose notes data folder',
    );
    if (path == null) return;
    await _saveFolder(path);
  }

  Future<void> _saveAndroidFolder() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    await Directory(path).create(recursive: true);
    await _saveFolder(path);
  }

  Future<void> _saveFolder(String path) async {
    setState(() => _saving = true);
    await ref.read(dataFolderProvider.notifier).setFolder(path);
    if (!mounted) return;
    setState(() => _saving = false);
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = ref.watch(storagePermissionProvider);

    return Scaffold(
      body: Center(
        child: permission.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Permission check failed: $error'),
          data: (granted) {
            if (!granted) return _buildPermissionRequest();
            return Platform.isAndroid ? _buildAndroidFolderField() : _buildLinuxPicker();
          },
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This app needs All Files Access to read and write notes in a '
            'folder you can sync with Syncthing.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(storagePermissionProvider.notifier).requestAccess(),
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinuxPicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Waiting for folder selection…'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _pickLinuxFolder,
          child: const Text('Choose Folder'),
        ),
      ],
    );
  }

  Widget _buildAndroidFolderField() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Notes folder (sync this with Syncthing):'),
          const SizedBox(height: 12),
          TextField(controller: _pathController),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _saveAndroidFolder,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
