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

  /// Whether the Lists screen for this type offers a "new note" action.
  /// False for types whose schema has required fields beyond what [fields]
  /// covers (e.g. hypothesis's `status`), since a generically-created note
  /// wouldn't validate.
  final bool creatable;

  /// relType keys (must exist in [relationshipTypeSpecs]) rendered as
  /// dedicated "quick add" buttons on this type's [NoteDetailScreen],
  /// alongside the always-present "Add Other" button. Empty by default — opt
  /// in per type as relationship conventions get established.
  final List<String> quickRelationshipTypes;

  /// Allowed values for this primaryType's optional `secondaryType` field,
  /// mirrored in this primaryType's `enum` in `note_schema.json`. Empty by
  /// default — this primaryType has no secondaryType concept, and
  /// [NoteDetailScreen] won't render a secondaryType picker for it.
  final List<String> secondaryTypes;

  const NoteTypeSpec({
    required this.primaryType,
    required this.label,
    required this.fields,
    this.creatable = false,
    this.quickRelationshipTypes = const [],
    this.secondaryTypes = const [],
  });
}

const noteTypeSpecs = [
  NoteTypeSpec(
    primaryType: 'unknown',
    label: 'Unknown',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'body', label: 'Body', multiline: true),
    ],
  ),
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
  // Only 'title' is exposed here: status and the context/experiment/notes/
  // findings arrays are managed by the dedicated Hypotheses flow, not the
  // generic edit form (which merges only the fields listed here, so those
  // keys are left untouched by it).
  NoteTypeSpec(
    primaryType: 'hypothesis',
    label: 'Hypothesis',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'gestalt',
    label: 'Gestalt',
    creatable: true,
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'context',
    label: 'Context',
    creatable: true,
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'ifThen',
    label: 'If/Then',
    creatable: true,
    quickRelationshipTypes: ['source', 'evidence'],
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'description',
    label: 'Description',
    creatable: true,
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'quote',
    label: 'Quote',
    creatable: true,
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'source',
    label: 'Source',
    creatable: true,
    secondaryTypes: ['book', 'article', 'blog', 'video', 'software', 'misc'],
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'entity',
    label: 'Entity',
    creatable: true,
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
  NoteTypeSpec(
    primaryType: 'story',
    label: 'Story',
    creatable: true,
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
      NoteFieldSpec(key: 'content', label: 'Content', multiline: true),
    ],
  ),
];
