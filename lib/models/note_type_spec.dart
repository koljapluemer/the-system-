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

  const NoteTypeSpec({
    required this.primaryType,
    required this.label,
    required this.fields,
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
  NoteTypeSpec(
    primaryType: 'book',
    label: 'Book',
    fields: [
      NoteFieldSpec(key: 'title', label: 'Title', required: true),
    ],
  ),
];
