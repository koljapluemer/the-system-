/// One edge in a [NoteSubgraph]: an unordered pair of filenames plus the
/// label under which it was first encountered while walking outward from
/// the root note (see [NoteSubgraph]'s doc for why only one label survives
/// per pair even though a mirrored relationship carries two).
class NoteGraphEdge {
  final String a;
  final String b;
  final String label;

  const NoteGraphEdge({required this.a, required this.b, required this.label});
}

/// A depth-limited neighborhood of the note graph, rooted at one note: every
/// filename reachable from the root by following `rels` within [depth] hops,
/// plus every edge between two included filenames (not just the tree edges
/// discovered during the walk — two depth-1 notes related to each other are
/// still connected). Built by [NoteSubgraphExtension.subgraph] for the
/// read-only Graph View flow.
class NoteSubgraph {
  final List<String> filenames;
  final List<NoteGraphEdge> edges;

  const NoteSubgraph({required this.filenames, required this.edges});
}
