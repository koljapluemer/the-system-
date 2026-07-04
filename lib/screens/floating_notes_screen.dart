import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/floating_note_entry.dart';
import '../state/floating_notes_notifier.dart';

const _minDuration = Duration(seconds: 12);
const _maxDuration = Duration(seconds: 25);
const _spawnInterval = Duration(milliseconds: 1800);
const _maxCardWidth = 260.0;
const _offscreenBuffer = 200.0;
const _fadeFraction = 0.08;

class _FloatingCard {
  final int id;
  final FloatingNoteEntry note;
  final double leftFraction;
  final AnimationController controller;

  _FloatingCard({
    required this.id,
    required this.note,
    required this.leftFraction,
    required this.controller,
  });
}

class FloatingNotesScreen extends ConsumerStatefulWidget {
  const FloatingNotesScreen({super.key});

  @override
  ConsumerState<FloatingNotesScreen> createState() => _FloatingNotesScreenState();
}

class _FloatingNotesScreenState extends ConsumerState<FloatingNotesScreen>
    with TickerProviderStateMixin {
  final _random = Random();
  final List<_FloatingCard> _cards = [];
  Timer? _spawnTimer;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _spawnTimer = Timer.periodic(_spawnInterval, (_) => _spawnCard());
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    for (final card in _cards) {
      card.controller.dispose();
    }
    super.dispose();
  }

  int _maxConcurrentCards() {
    final area = _canvasSize.width * _canvasSize.height;
    if (area <= 0) return 0;
    return (area / 45000).clamp(3, 16).floor();
  }

  void _spawnCard() {
    if (_canvasSize == Size.zero) return;
    if (_cards.length >= _maxConcurrentCards()) return;

    final notes = ref.read(floatingNotesProvider).notes;
    final filter = ref.read(floatingNotesFilterProvider).trim().toLowerCase();
    final pool = filter.isEmpty
        ? notes
        : notes
            .where((n) =>
                n.title.toLowerCase().contains(filter) || n.body.toLowerCase().contains(filter))
            .toList();
    if (pool.isEmpty) return;

    final note = pool[_random.nextInt(pool.length)];
    final durationMs = _minDuration.inMilliseconds +
        _random.nextDouble() * (_maxDuration.inMilliseconds - _minDuration.inMilliseconds);
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs.round()),
    );

    late final _FloatingCard card;
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _cards.removeWhere((c) => c.id == card.id));
        controller.dispose();
      }
    });

    card = _FloatingCard(
      id: DateTime.now().microsecondsSinceEpoch,
      note: note,
      leftFraction: _random.nextDouble(),
      controller: controller,
    );
    setState(() => _cards.add(card));
    controller.forward();
  }

  void _showNoteDialog(FloatingNoteEntry note) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title.isEmpty ? '(untitled)' : note.title),
        content: SingleChildScrollView(child: Text(note.body)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildCard(_FloatingCard card, double cardWidth) {
    final height = _canvasSize.height;
    final maxLeft = max(0.0, _canvasSize.width - cardWidth);
    final left = card.leftFraction * maxLeft;
    final top0 = height + _offscreenBuffer;
    final top1 = -_offscreenBuffer;

    return AnimatedBuilder(
      animation: card.controller,
      builder: (context, child) {
        final t = card.controller.value;
        final top = top0 + (top1 - top0) * t;
        double opacity;
        if (t < _fadeFraction) {
          opacity = t / _fadeFraction;
        } else if (t > 1 - _fadeFraction) {
          opacity = (1 - t) / _fadeFraction;
        } else {
          opacity = 1;
        }
        return Positioned(
          left: left,
          top: top,
          width: cardWidth,
          child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _showNoteDialog(card.note),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.note.title.isNotEmpty) ...[
                  Text(
                    card.note.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  card.note.body,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Filter…',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => ref.read(floatingNotesFilterProvider.notifier).set(value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floatingNotes = ref.watch(floatingNotesProvider);
    final showSpinner = floatingNotes.loading && floatingNotes.notes.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Floating Notes')),
      body: showSpinner
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = constraints.biggest;
                final cardWidth = min(_maxCardWidth, constraints.maxWidth * 0.8);
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (final card in _cards) _buildCard(card, cardWidth),
                    _buildFilterBar(),
                  ],
                );
              },
            ),
    );
  }
}
