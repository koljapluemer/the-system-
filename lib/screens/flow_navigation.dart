import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/recent_history_notifier.dart';
import 'floating_notes_screen.dart';
import 'hypotheses_screen.dart';
import 'memorize_screen.dart';
import 'scratchpad_triage_screen.dart';

/// Describes one top-level flow, reachable from [HomeScreen]'s link list and
/// from the recent-history bar (see RecentBar). Data-driven on purpose: this
/// app is meant to grow into a suite of flows, so new ones just get added
/// here.
class FlowSpec {
  final String id;
  final String label;
  final IconData icon;
  final WidgetBuilder builder;

  const FlowSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });
}

final flowSpecs = [
  FlowSpec(
    id: 'scratchpad-triage',
    label: 'Scratchpad Triage',
    icon: Icons.inbox_outlined,
    builder: (_) => const ScratchpadTriageScreen(),
  ),
  FlowSpec(
    id: 'memorize',
    label: 'Memorize',
    icon: Icons.school_outlined,
    builder: (_) => const MemorizeScreen(),
  ),
  FlowSpec(
    id: 'floating-notes',
    label: 'Floating Notes',
    icon: Icons.bubble_chart_outlined,
    builder: (_) => const FloatingNotesScreen(),
  ),
  FlowSpec(
    id: 'hypotheses',
    label: 'Hypotheses',
    icon: Icons.science_outlined,
    builder: (_) => const HypothesesScreen(),
  ),
];

/// Pushes the flow identified by [id] and records it in [recentHistoryProvider]
/// — the single chokepoint for entering a flow, mirroring [pushNoteEditor]'s
/// role for notes, so the recent-history bar stays accurate no matter how a
/// flow is reached.
void pushFlow(BuildContext context, WidgetRef ref, String id) {
  final spec = flowSpecs.firstWhere((s) => s.id == id);
  ref
      .read(recentHistoryProvider.notifier)
      .record(RecentEntry(kind: RecentEntryKind.flow, id: spec.id, label: spec.label));
  Navigator.push(context, MaterialPageRoute(builder: spec.builder));
}
