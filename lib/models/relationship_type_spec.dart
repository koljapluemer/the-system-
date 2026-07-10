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
];
