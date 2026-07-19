import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_type_spec.dart';
import '../state/scratchpad_triage_notifier.dart';
import '../state/triage_notifier.dart';
import '../widgets/change_type_dialog.dart';

final _scratchpadSpec = noteTypeSpecs.firstWhere((s) => s.primaryType == 'scratchpad');

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
      body: SafeArea(
        minimum: const EdgeInsets.only(bottom: 88),
        child: _buildBody(context, ref, state, notifier),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TriageState state,
    ScratchpadTriageNotifier notifier,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.currentNote == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'All caught up — no more scratchpad notes to triage.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final note = state.currentNote!;
    final title = note['title'] as String? ?? '(untitled)';
    final body = note['body'] as String? ?? '';

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
                        const SizedBox(height: 12),
                        Text(body, style: Theme.of(context).textTheme.bodyMedium),
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
                    onPressed: () => showChangeTypeDialog(
                      context,
                      ref,
                      filename: state.currentFilename!,
                      currentSpec: _scratchpadSpec,
                      onChanged: notifier.refreshAfterExternalChange,
                    ),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Change Type'),
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
