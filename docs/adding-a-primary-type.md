Internal checklist for adding a new note `primaryType`. Brief — for contributors, not end users.

## Must touch

- `assets/note_schema.json` — add a `oneOf` entry (properties + `required` +
  `additionalProperties: false`). This is the source of truth the app validates against;
  nothing else auto-derives from it.
- `lib/models/note_type_spec.dart` — add a `NoteTypeSpec` entry: `fields` (kept in sync
  with the schema properties above), `creatable`, `quickRelationshipTypes`.

## Must decide

- **`creatable`**: only set `true` if every required schema field beyond `title` is
  covered by `fields` (see the `hypothesis` entry's comment for why — a generically
  created note wouldn't validate otherwise, since `createFromSpec` only fills `title` +
  empty strings for the rest of `fields`).
- **Generic `NoteDetailScreen` vs. a bespoke screen**: `NoteDetailScreen` (inline
  pencil-edit per `fields` entry + unified relationship list) is the default for every
  type, reached via `pushNoteEditor`. Only build a bespoke screen (see
  `hypothesis_detail_screen.dart` for the pattern) if the type has state/logic
  `NoteDetailScreen` can't express — e.g. hypothesis's status transitions and
  context/experiment/notes/findings logs. A bespoke screen bypasses `pushNoteEditor`
  entirely (see how `hypotheses_screen.dart` hardcodes its own navigation) and any fields
  it manages itself should generally be left out of `NoteTypeSpec.fields`, since that list
  is what the generic form/detail screen merges on save.
- **`quickRelationshipTypes`**: does this type have a "commonly added" relationship? If
  so, add/reuse an entry in `lib/models/relationship_type_spec.dart`'s
  `relationshipTypeSpecs` (a new `RelationshipTypeSpec` if the relType or its
  `allowedPrimaryTypes` differ from an existing one — don't stretch an existing entry's
  `allowedPrimaryTypes` to cover an unrelated semantic just to reuse the key) and
  reference its `relType` key here. If not, leave it `[]` — the type still gets relations
  via the generic "Add Other" picker, which lists every registered relationship type.
- **Import Obs Flow**: should this type be selectable there? Add it to the option list in
  `import_obs_type_screen.dart` (see `docs/obs-import.md`) if so.

## Don't need to touch

- `note_editor_navigation.dart`, `relationship_dialog.dart` — both generic over any
  `NoteTypeSpec`/relType already.
- Any test file, unless the new type has validation edge cases worth covering in
  `test/json_schema_service_test.dart`.
