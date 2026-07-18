import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/netting_notifier.dart';
import '../widgets/netting_note_card.dart';

/// The Netting flow: repeatedly picks a random `ifThen`/`description` note
/// that still has an unanswered prompt question, shows the note and the
/// question, and lets the user answer it, defer it, or mark it not
/// relevant.
class NettingScreen extends ConsumerStatefulWidget {
  const NettingScreen({super.key});

  @override
  ConsumerState<NettingScreen> createState() => _NettingScreenState();
}

class _NettingScreenState extends ConsumerState<NettingScreen> {
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _answerController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NettingState>(nettingProvider, (previous, next) {
      if (next.currentFilename != previous?.currentFilename ||
          next.currentQuestion != previous?.currentQuestion) {
        _answerController.clear();
      }
    });

    final state = ref.watch(nettingProvider);
    final notifier = ref.read(nettingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Netting')),
      body: SafeArea(
        minimum: const EdgeInsets.only(bottom: 88),
        child: _buildBody(context, state, notifier),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NettingState state, NettingNotifier notifier) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.currentNote == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'All caught up — no more questions to ask.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NettingNoteCard(filename: state.currentFilename!, note: state.currentNote!),
                    const SizedBox(height: 20),
                    Text(
                      state.currentQuestion!,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _answerController,
                      minLines: 3,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Your answer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _buildActions(state, notifier),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(NettingState state, NettingNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: notifier.defer, child: const Text('Defer')),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: notifier.markNotRelevant,
            child: const Text('Question Not Relevant'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: _answerController.text.trim().isEmpty
                ? null
                : () => notifier.save(_answerController.text.trim()),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
