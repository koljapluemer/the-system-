/// Describes one relationship type (the first element of a `rels` pair): its
/// display label and which primaryTypes are valid attach targets. Feeds
/// [NoteTypeSpec.quickRelationshipTypes] (per-primaryType "quick add"
/// buttons) and the "Add Other" picker (every entry not already offered as a
/// quick button) in NoteDetailScreen.
class RelationshipTypeSpec {
  final String relType;
  final String label;
  final String buttonLabel;
  final List<String> allowedPrimaryTypes;

  const RelationshipTypeSpec({
    required this.relType,
    required this.label,
    required this.buttonLabel,
    required this.allowedPrimaryTypes,
  });
}

/// primaryTypes eligible as "Evidence" for a note, per docs/obs-import.md —
/// deliberately excludes `source`, which has its own dedicated relationship.
const _evidencePrimaryTypes = ['gestalt', 'context', 'ifThen', 'description', 'quote', 'story'];

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
  ),
  RelationshipTypeSpec(
    relType: 'evidence',
    label: 'Evidence',
    buttonLabel: 'Add Evidence',
    allowedPrimaryTypes: _evidencePrimaryTypes,
  ),
  RelationshipTypeSpec(
    relType: seeAlsoRelType,
    label: 'See Also',
    buttonLabel: 'Add See Also',
    allowedPrimaryTypes: _allPrimaryTypes,
  ),
];
