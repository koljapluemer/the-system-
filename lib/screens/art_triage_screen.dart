import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../state/art_triage_notifier.dart';
import '../state/providers.dart';
import '../state/triage_notifier.dart';

class ArtTriageScreen extends ConsumerWidget {
  const ArtTriageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(artTriageProvider);
    final notifier = ref.read(artTriageProvider.notifier);
    final folder = ref.watch(dataFolderProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Triage'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${state.queue.length} remaining',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.only(bottom: 88),
        child: _buildBody(context, state, notifier, folder),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TriageState state,
    ArtTriageNotifier notifier,
    String? folder,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.currentNote == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'All caught up — no more art to triage.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final note = state.currentNote!;
    final title = note['title'] as String? ?? '(untitled)';
    final content = note['content'] as String? ?? '';
    final image = note['image'] as String?;
    // Cap extreme-portrait images so they can't push the action buttons
    // off-screen; the surrounding scroll view is a safety net for anything
    // still too tall (e.g. very long markdown).
    final maxImageHeight = MediaQuery.sizeOf(context).height * 0.5;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        if (image != null && folder != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: maxImageHeight),
                              child: Image.file(
                                File(p.join(folder, 'media', image)),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        MarkdownBody(data: content),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: notifier.keep,
                    icon: const Icon(Icons.check),
                    label: const Text('Keep'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
                    onPressed: () => notifier.delete(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: notifier.defer,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Defer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
