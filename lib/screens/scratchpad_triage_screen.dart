import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/scratchpad_triage_notifier.dart';

class ScratchpadTriageScreen extends ConsumerWidget {
  const ScratchpadTriageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scratchpadTriageProvider);
    final notifier = ref.read(scratchpadTriageProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scratchpad Triage'),
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
      body: Center(child: _buildBody(context, state, notifier)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TriageState state,
    ScratchpadTriageNotifier notifier,
  ) {
    if (state.loading) {
      return const CircularProgressIndicator();
    }

    if (state.currentNote == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'All caught up — no more scratchpad notes to triage.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final note = state.currentNote!;
    final title = note['title'] as String? ?? '(untitled)';
    final body = note['body'] as String? ?? '';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(body, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
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
          ],
        ),
      ),
    );
  }
}
