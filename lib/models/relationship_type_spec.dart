/// Describes one relationship type (the first element of a `rels` pair): its
/// display label and which primaryTypes are valid attach targets. Feeds
/// [NoteTypeSpec.quickRelationshipTypes] (per-primaryType "quick add"
/// buttons) in NoteDetailScreen.
class RelationshipTypeSpec {
  final String relType;
  final String label;
  final String buttonLabel;
  final List<String> allowedPrimaryTypes;

  /// The relType to write automatically on the *other* note whenever this
  /// relType is attached (or removed, when detaching) — see
  /// `NoteIndexNotifier.attachRelationship`/`detachRelationship`. `null`
  /// means this relType is never mirrored (currently only `log` and
  /// `seeAlso`, per docs/specs/type-improve.md).
  final String? mirrorRelType;

  const RelationshipTypeSpec({
    required this.relType,
    required this.label,
    required this.buttonLabel,
    required this.allowedPrimaryTypes,
    this.mirrorRelType,
  });
}

/// primaryTypes eligible as "Evidence" for a note, per docs/specs/type-improve.md.
const _evidencePrimaryTypes = ['source', 'quote', 'ifThen', 'description', 'story', 'gestalt'];

/// Every registered note primaryType, kept in sync with `noteTypeSpecs` in
/// `note_type_spec.dart` (that file imports this one, so this can't import
/// back) — `seeAlso` deliberately allows attaching any type to any type.
const _allPrimaryTypes = [
  'scratchpad',
  'art',
  'hypothesis',
  'milestone',
  'gestalt',
  'context',
  'ifThen',
  'description',
  'quote',
  'source',
  'entity',
  'story',
  'log',
  'flashcard',
  'link',
  'project',
  'do',
];

/// The relType of the universal "See Also" relationship, always offered as
/// its own button (see `NoteDetailScreen._relationshipsSection`) rather than
/// via [NoteTypeSpec.quickRelationshipTypes] or the "Add Other" picker, since
/// it applies to every primaryType.
const seeAlsoRelType = 'seeAlso';

const relationshipTypeSpecs = [
  RelationshipTypeSpec(
    relType: 'source',
    label: 'Source',
    buttonLabel: 'Add Source Relationship',
    allowedPrimaryTypes: ['source'],
    mirrorRelType: 'sourceOf',
  ),
  // Mirror-only: written automatically onto a source note when something
  // attaches it via `source`. Never offered as a quick button.
  RelationshipTypeSpec(
    relType: 'sourceOf',
    label: 'Source Of',
    buttonLabel: 'Add Source Of',
    allowedPrimaryTypes: _allPrimaryTypes,
    mirrorRelType: 'source',
  ),
  RelationshipTypeSpec(
    relType: 'evidence',
    label: 'Evidence',
    buttonLabel: 'Add Evidence',
    allowedPrimaryTypes: _evidencePrimaryTypes,
    mirrorRelType: 'evidenceFor',
  ),
  // Mirror-only: written automatically onto a note when something attaches
  // it as `evidence`. Never offered as a quick button.
  RelationshipTypeSpec(
    relType: 'evidenceFor',
    label: 'Evidence For',
    buttonLabel: 'Add Evidence For',
    allowedPrimaryTypes: _allPrimaryTypes,
    mirrorRelType: 'evidence',
  ),
  RelationshipTypeSpec(
    relType: 'entity',
    label: 'Entity',
    buttonLabel: 'Add Entity',
    allowedPrimaryTypes: ['entity'],
    mirrorRelType: 'entityOf',
  ),
  // Mirror-only: written automatically onto an entity note when something
  // attaches it via `entity`. Never offered as a quick button.
  RelationshipTypeSpec(
    relType: 'entityOf',
    label: 'Entity Of',
    buttonLabel: 'Add Entity Of',
    allowedPrimaryTypes: _allPrimaryTypes,
    mirrorRelType: 'entity',
  ),
  // gestalt <-> description: a natural symmetric pair, each side's
  // mirrorRelType pointing straight at the other's primaryType-named entry.
  RelationshipTypeSpec(
    relType: 'description',
    label: 'Description',
    buttonLabel: 'Add Description',
    allowedPrimaryTypes: ['description'],
    mirrorRelType: 'gestalt',
  ),
  RelationshipTypeSpec(
    relType: 'gestalt',
    label: 'Gestalt',
    buttonLabel: 'Add Gestalt',
    allowedPrimaryTypes: ['gestalt'],
    mirrorRelType: 'description',
  ),
  // context <-> ifThen: same symmetric-pair pattern as gestalt/description.
  RelationshipTypeSpec(
    relType: 'context',
    label: 'Context',
    buttonLabel: 'Add Context',
    allowedPrimaryTypes: ['context'],
    mirrorRelType: 'ifThen',
  ),
  RelationshipTypeSpec(
    relType: 'ifThen',
    label: 'If/Then',
    buttonLabel: 'Add If/Then',
    allowedPrimaryTypes: ['ifThen'],
    mirrorRelType: 'context',
  ),
  RelationshipTypeSpec(
    relType: seeAlsoRelType,
    label: 'See Also',
    buttonLabel: 'Add See Also',
    allowedPrimaryTypes: _allPrimaryTypes,
  ),
  RelationshipTypeSpec(
    relType: 'log',
    label: 'Log',
    buttonLabel: 'Add Log',
    allowedPrimaryTypes: ['log'],
  ),
  // Not reciprocal — no mirrorRelType, so attaching a link never writes
  // anything back onto the link note itself.
  RelationshipTypeSpec(
    relType: 'link',
    label: 'Link',
    buttonLabel: 'Add Link',
    allowedPrimaryTypes: ['link'],
  ),
];
