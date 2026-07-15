import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/folder_setup_screen.dart';
import 'screens/home_screen.dart';
import 'state/providers.dart';
import 'widgets/recent_bar.dart';

class TheSystemApp extends ConsumerWidget {
  const TheSystemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataFolder = ref.watch(dataFolderProvider);

    return MaterialApp(
      title: 'The System',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      // Rendered here, outside the Navigator built by `home`, so it stays
      // mounted and visible across every pushed screen instead of only
      // whichever screen happens to embed it.
      builder: (context, child) => Material(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const RecentBar(),
              Expanded(child: child!),
            ],
          ),
        ),
      ),
      home: dataFolder.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Failed to load settings: $error')),
        ),
        data: (folder) => folder == null ? const FolderSetupScreen() : const HomeScreen(),
      ),
    );
  }
}
