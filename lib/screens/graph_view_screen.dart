import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

import '../models/note_index.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import 'note_editor_navigation.dart';

final _specsByType = {for (final spec in noteTypeSpecs) spec.primaryType: spec};

/// An [ArrowEdgeRenderer] (arrowless, since a `rels` pair is a mutual
/// relationship rather than a strict direction) that also draws the rel's
/// label at the edge's midpoint, looked up by unordered filename pair —
/// [Edge] itself carries no label, and giving it one via [Edge.key] would
/// corrupt [Edge]'s equality (which falls back to hashing that key),
/// wrongly merging distinct edges that happen to share a label.
class _LabeledEdgeRenderer extends ArrowEdgeRenderer {
  _LabeledEdgeRenderer(this._labels) : super(noArrow: true);

  final Map<String, String> _labels;

  @override
  void renderEdge(Canvas canvas, Edge edge, Paint paint) {
    super.renderEdge(canvas, edge, paint);

    final a = edge.source.key!.value as String;
    final b = edge.destination.key!.value as String;
    final label = _labels[([a, b]..sort()).join(' ')];
    if (label == null || label.isEmpty) return;

    final mid = Offset.lerp(
      getNodeCenter(edge.source),
      getNodeCenter(edge.destination),
      0.5,
    )!;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromCenter(
      center: mid,
      width: painter.width + 8,
      height: painter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = const Color(0xE6FFFFFF),
    );
    painter.paint(canvas, mid - Offset(painter.width / 2, painter.height / 2));
  }
}

/// Read-only graph view: picks a random note, shows it and every note within
/// two `rels` hops of it as a force-directed graph, panned/zoomed via a
/// manually-wrapped [InteractiveViewer]. Deliberately uses the plain
/// [GraphView] widget rather than [GraphView.builder] — pairing the
/// `.builder` form's `autoZoomToFit`/node-fly-in animation with
/// [FruchtermanReingoldAlgorithm] sends its internal `AnimationController`s
/// into a permanent restart loop (verified via a throwaway widget test:
/// `pumpAndSettle` never settled, spamming "Cannot hit test a render box
/// with no size" the whole time) — matching how the package's own examples
/// only pair `.builder` with static tree/layered algorithms, never with
/// force-directed ones. Tapping a node opens the normal (editable) note
/// screen via [pushNoteEditor] — the same destination every other list in
/// the app uses — but this screen itself offers no way to add or change a
/// relationship; that's future work.
class GraphViewScreen extends ConsumerStatefulWidget {
  const GraphViewScreen({super.key});

  @override
  ConsumerState<GraphViewScreen> createState() => _GraphViewScreenState();
}

class _GraphViewScreenState extends ConsumerState<GraphViewScreen> {
  static const _depth = 2;

  final _random = Random();
  final _transformationController = TransformationController();
  String? _rootFilename;
  Graph? _graph;
  FruchtermanReingoldAlgorithm? _algorithm;
  bool _centered = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _ensureGraph(NoteIndex index) {
    if (_graph != null &&
        _rootFilename != null &&
        index.entries.containsKey(_rootFilename)) {
      return;
    }
    final filenames = index.entries.keys.toList();
    if (filenames.isEmpty) {
      _rootFilename = null;
      _graph = null;
      _algorithm = null;
      return;
    }
    _buildGraphFor(index, filenames[_random.nextInt(filenames.length)]);
  }

  void _shuffle(NoteIndex index) {
    final filenames = index.entries.keys.toList();
    if (filenames.isEmpty) return;
    setState(
      () => _buildGraphFor(index, filenames[_random.nextInt(filenames.length)]),
    );
  }

  void _buildGraphFor(NoteIndex index, String root) {
    final subgraph = index.subgraph(root: root, depth: _depth);

    final graph = Graph()..isTree = false;
    final nodesByFilename = {for (final f in subgraph.filenames) f: Node.Id(f)};
    graph.addNodes(nodesByFilename.values.toList());

    final labels = <String, String>{};
    for (final edge in subgraph.edges) {
      graph.addEdge(nodesByFilename[edge.a]!, nodesByFilename[edge.b]!);
      labels[([edge.a, edge.b]..sort()).join(' ')] = edge.label;
    }

    _rootFilename = root;
    _graph = graph;
    _algorithm = FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(),
      renderer: _LabeledEdgeRenderer(labels),
    );
    _centered = false;
  }

  /// Centers the viewport on the graph's bounding box, once, right after the
  /// frame in which [GraphView] first laid the nodes out (node positions
  /// aren't known any earlier — [FruchtermanReingoldAlgorithm] runs inside
  /// that layout pass). A direct [TransformationController.value] write,
  /// deliberately without `setState` — [GraphView] forces a full recompute
  /// of its own layout whenever *its* parent (this widget) rebuilds (its
  /// `GraphChildDelegate` is reconstructed unconditionally on every
  /// [GraphView] build), so triggering a rebuild here would recompute the
  /// force-directed layout a second time for no reason. [TransformationController]
  /// is a [ValueNotifier] that [InteractiveViewer] already listens to
  /// directly, so the transform updates without one. Also deliberately not
  /// an animated transition — see [GraphViewScreen]'s doc for why animating
  /// this is what caused the restart loop.
  void _centerIfNeeded(Graph graph, Size viewportSize) {
    if (_centered || !mounted || graph.nodes.isEmpty) return;
    final bounds = graph.calculateGraphBounds();
    if (!bounds.isFinite) return;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(
        viewportSize.width / 2 - bounds.center.dx,
        viewportSize.height / 2 - bounds.center.dy,
        0,
        1,
      );
    _centered = true;
  }

  Widget _buildNode(BuildContext context, Node node, NoteIndex index) {
    final filename = node.key!.value as String;
    final note = index.entries[filename];
    final title = note?['title'] as String? ?? filename;
    final spec = _specsByType[note?['primaryType']];
    final isRoot = filename == _rootFilename;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: spec == null
          ? null
          : () => pushNoteEditor(context, spec: spec, filename: filename),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isRoot
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spec?.label ?? (note?['primaryType'] as String? ?? '?'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final indexAsync = ref.watch(noteIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph View'),
        actions: [
          IconButton(
            tooltip: 'Random note',
            icon: const Icon(Icons.shuffle),
            onPressed: indexAsync.value == null
                ? null
                : () => _shuffle(indexAsync.value!),
          ),
        ],
      ),
      body: indexAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load notes: $e')),
        data: (index) {
          if (index.entries.isEmpty) {
            return const Center(child: Text('No notes yet'));
          }
          _ensureGraph(index);
          final graph = _graph;
          final algorithm = _algorithm;
          if (graph == null || algorithm == null) {
            return const Center(child: Text('Nothing to show'));
          }

          final rootTitle =
              index.entries[_rootFilename]?['title'] as String? ??
              _rootFilename;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Centered on: $rootTitle',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              // A graph with exactly one node and no edges crashes
              // FruchtermanReingoldAlgorithm (see GraphViewScreen's doc) —
              // and there's nothing for a force-directed layout to do with
              // one node anyway, so skip GraphView entirely for this note
              // (no resolvable rels within the index).
              if (graph.nodes.length <= 1)
                Expanded(
                  child: Center(
                    child: graph.nodes.isEmpty
                        ? const Text('Nothing to show')
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNode(context, graph.nodes.first, index),
                              const SizedBox(height: 8),
                              Text(
                                'No relationships found',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                  ),
                )
              else
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _centerIfNeeded(graph, constraints.biggest),
                      );
                      return InteractiveViewer(
                        transformationController: _transformationController,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(2000),
                        minScale: 0.05,
                        maxScale: 4,
                        child: GraphView(
                          graph: graph,
                          algorithm: algorithm,
                          animated: false,
                          paint: Paint()
                            ..color = Theme.of(context).colorScheme.outline
                            ..strokeWidth = 1.5
                            ..style = PaintingStyle.stroke,
                          builder: (node) => _buildNode(context, node, index),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
