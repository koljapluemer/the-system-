import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/folder_setup_screen.dart';
import 'screens/home_screen.dart';
import 'state/providers.dart';
import 'widgets/recent_bar.dart';

/// Key for the inner [Navigator] that [_AppShell] hosts for all real app
/// screens. [RecentBar] pushes/pops through this key's context rather than
/// its own — RecentBar is a sibling of that Navigator, not a descendant of
/// it, so its own context has no Navigator ancestor to find.
final navigatorKey = GlobalKey<NavigatorState>();

class TheSystemApp extends StatelessWidget {
  const TheSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The System',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      // `home` is this one permanent shell — MaterialApp's own (outer)
      // Navigator never sees another route. All real navigation happens on
      // the inner Navigator below, keyed by `navigatorKey`.
      home: const _AppShell(),
    );
  }
}

/// Persistent chrome ([RecentBar]) wrapping an inner [Navigator] that hosts
/// every real screen. Two Navigators rather than one so RecentBar — which
/// needs to survive every push/pop, and needs an Overlay ancestor for
/// widgets like Tooltip — sits inside the OUTER (MaterialApp-provided)
/// Navigator's Overlay instead of outside all navigation structure
/// entirely. (An earlier attempt used `MaterialApp.builder` to lay
/// RecentBar beside the routed `child`, and a hand-rolled `Overlay` to give
/// it an Overlay ancestor — but a raw `Overlay`'s `initialEntries` are only
/// read once at construction, so it silently froze on whatever `child` was
/// current at first build, e.g. the loading spinner. A nested Navigator
/// avoids that: it's real, managed navigation state, not a static entry
/// list.)
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const RecentBar(),
            Expanded(
              child: Navigator(
                key: navigatorKey,
                onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const _RootScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The inner Navigator's bottom route: switches between the loading /
/// error / folder-setup / home screens as [dataFolderProvider] resolves.
/// A plain [ConsumerWidget], so it reacts to provider changes in place —
/// unlike a route builder or an Overlay entry, it isn't a one-shot closure.
class _RootScreen extends ConsumerWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataFolder = ref.watch(dataFolderProvider);
    return dataFolder.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Failed to load settings: $error')),
      ),
      data: (folder) => folder == null ? const FolderSetupScreen() : const HomeScreen(),
    );
  }
}
