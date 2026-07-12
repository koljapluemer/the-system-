import 'relationship_type_spec.dart';

/// Describes one note primaryType's core editable fields, driving the Lists
/// overview, per-type list, and generic edit form. Keep in sync with
/// assets/note_schema.json.
class NoteFieldSpec {
  final String key;
  final String label;
  final bool multiline;
  final bool required;

  const NoteFieldSpec({
    required this.key,
    required this.label,
    this.multiline = false,
    this.required = false,
  });
}

class NoteTypeSpec {
  final String primaryType;
  final String label;
  final List<NoteFieldSpec> fields;

  /// relType keys (must exist in [relationshipTypeSpecs]) rendered as
  /// dedicated "quick add" buttons on this type's [NoteDetailScreen],
  /// alongside the always-present "Add Other" button. Empty by default — opt
  /// in per type as relationship conventions get established.
  final List<String> quickRelationshipTypes;

  /// Allowed values for this primaryType's optional `secondaryType` field,
  /// mirrored in this primaryType's `enum` in `note_schema.json`. Empty by
  /// default — this primaryType has no secondaryType concept, and
  /// [NoteDetailScreen] won't render a secondaryType picker for it. Order
  /// matters: the first entry is this type's default secondaryType, assigned
  /// to new notes unless the user picks otherwise.
  final List<String> secondaryTypes;

  /// The secondaryType values shown by default in this type's list-view
  /// filter, mirrored in the `defaultVisible` annotation beside this type's
  /// `secondaryType` property in `note_schema.json`. Empty by default —
  /// meaning "no restriction", i.e. every value in [secondaryTypes] is shown
  /// by default — matching the schema convention of omitting `defaultVisible`
  /// entirely rather than redundantly listing every value.
  final List<String> defaultVisibleSecondaryTypes;

  /// [defaultVisibleSecondaryTypes], resolved against the "empty means show
  /// all" convention above.
  List<String> get effectiveDefaultVisible =>
      defaultVisibleSecondaryTypes.isEmpty ? secondaryTypes : defaultVisibleSecondaryTypes;

  /// The secondaryType assigned to a new note of this type unless the user
  /// picks otherwise — the first entry in [secondaryTypes]. Only call this
  /// when [secondaryTypes] is non-empty.
  String get defaultSecondaryType => secondaryTypes.first;

  /// Whether this primaryType appears in the Lists section on the home
  /// screen, mirrored in this primaryType's `showInLists` in
  /// `note_schema.json`. True by default.
  final bool showInLists;

  const NoteTypeSpec({
    required this.primaryType,
    required this.label,
    required this.fields,
    this.quickRelationshipTypes = const [],
    this.secondaryTypes = const [],
    this.defaultVisibleSecondaryTypes = const [],
    this.showInLists = true,
  });
}

const noteTypeSpecs = [
  NoteTypeSpec(
    primaryType: 'scratchpad',
    label: 'Scratchpad',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'body', label: 'Body', multiline: true, required: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'art',
    label: 'Art',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true, required: true),
      NoteFieldSpec(key: 'image', label: 'Image (filename)'),
    ],
  ),
  // Only 'title' is exposed here: secondaryType and the context/experiment/
  // notes/findings arrays are managed by the dedicated Hypotheses flow, not
  // the generic edit form (which merges only the fields listed here, so
  // those keys are left untouched by it).
  NoteTypeSpec(
    primaryType: 'hypothesis',
    label: 'Hypothesis',
    secondaryTypes: ['active', 'supported', 'disproven'],
    defaultVisibleSecondaryTypes: ['active'],
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'milestone',
    label: 'Milestone',
    secondaryTypes: ['open', 'failed', 'soso'],
    defaultVisibleSecondaryTypes: ['open'],
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'gestalt',
    label: 'Gestalt',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'context',
    label: 'Context',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'ifThen',
    label: 'If/Then',
    quickRelationshipTypes: ['source', 'evidence'],
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'description',
    label: 'Description',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'quote',
    label: 'Quote',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'source',
    label: 'Source',
    secondaryTypes: ['book', 'article', 'blog', 'video', 'software', 'misc'],
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'entity',
    label: 'Entity',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'story',
    label: 'Story',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
];
