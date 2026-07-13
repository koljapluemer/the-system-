Internal checklist for adding a new note `primaryType`. Brief — for contributors, not end users.

## Must touch

- `assets/note_schema.json` — add a `oneOf` entry (properties + `required` +
  `additionalProperties: false`). This is the source of truth the app validates against;
  nothing else auto-derives from it.
- `lib/models/note_type_spec.dart` — add a `NoteTypeSpec` entry: `fields` (kept in sync
  with the schema properties above), `quickRelationshipTypes`. Every type's Lists screen
  gets a "new note" FAB automatically (`NoteTypeListScreen` isn't gated by any flag) —
  if the type has state a title-only `createFromSpec` create can't set up (see the
  `hypothesis` branch in `_AddScreenState._createNote`), special-case creation there
  instead, the way `hypothesis` does.
- `lib/models/relationship_type_spec.dart`'s `_allPrimaryTypes` — a hand-maintained
  mirror of every `noteTypeSpecs` primaryType (can't import `note_type_spec.dart`
  directly; that file imports this one), used as `seeAlso`'s `allowedPrimaryTypes` so the
  universal "See Also" button on `NoteDetailScreen` can attach any type to any type. A
  new primaryType left out of this list simply can't be picked as a "See Also" target —
  no crash, just a silent gap, so don't forget it.

## Must decide

- **Generic `NoteDetailScreen` vs. a bespoke screen**: `NoteDetailScreen` (inline
  pencil-edit per `fields` entry + unified relationship list) is the default for every
  type, reached via `pushNoteEditor`. Only build a bespoke screen (see
  `hypothesis_detail_screen.dart` for the pattern) if the type has state/logic
  `NoteDetailScreen` can't express — e.g. hypothesis's status transitions and
  context/experiment/notes/findings logs. A bespoke screen bypasses `pushNoteEditor`
  entirely (see how `hypotheses_screen.dart` hardcodes its own navigation) and any fields
  it manages itself should generally be left out of `NoteTypeSpec.fields`, since that list
  is what the generic form/detail screen merges on save.
- **`secondaryTypes`**: does this type need a constrained sub-type (e.g. `source`'s
  `secondaryType` of `book`/`article`/`blog`/etc.)? If so, add the allowed values to both
  the schema (an `enum` on that type's `secondaryType` property in `note_schema.json`) and
  `NoteTypeSpec.secondaryTypes` here — `NoteDetailScreen` renders a dropdown automatically
  whenever `secondaryTypes` is non-empty. Leave it `[]` (the default) if this type has no
  such concept. Order matters: the **first entry is this type's default** — the value
  stamped onto a newly created note (via `AddScreen`'s secondaryType picker, or
  `NoteIndexNotifier.createFromSpec`'s `secondaryType` param) unless the user picks a
  different value, and unless a value was already chosen this session (see
  `LastSecondaryTypeNotifier` in `lib/state/secondary_type_session.dart`).
  Any type with a non-empty `secondaryTypes` automatically gets a `SecondaryTypeFilterBar`
  (`lib/widgets/secondary_type_filter_bar.dart`) on its list view (`NoteTypeListScreen`,
  or reuse the same widget/provider directly if the type has a bespoke list screen like
  Hypotheses does) for free — no per-type wiring needed beyond this declaration.
- **`defaultVisibleSecondaryTypes`**: which of this type's `secondaryTypes` should be
  visible by default in that filter bar (session-only — see
  `SecondaryTypeFilterNotifier`)? Mirror it in the schema as a `defaultVisible` array
  sibling next to that type's `secondaryType` `enum` (e.g. `hypothesis`'s
  `"defaultVisible": ["active"]`). Leave both the schema annotation and this Dart field
  omitted/`[]` (the default) if every value should be visible by default — that's the
  convention `source` uses, rather than redundantly listing every enum value.
- **`quickRelationshipTypes`**: does this type have a "commonly added" relationship? If
  so, add/reuse an entry in `lib/models/relationship_type_spec.dart`'s
  `relationshipTypeSpecs` (a new `RelationshipTypeSpec` if the relType or its
  `allowedPrimaryTypes` differ from an existing one — don't stretch an existing entry's
  `allowedPrimaryTypes` to cover an unrelated semantic just to reuse the key) and
  reference its `relType` key here. If not, leave it `[]` — the type still gets relations
  via the generic "Add Other" picker, which lists every registered relationship type
  except `seeAlso` (see below), plus the always-present "See Also" button, which every
  new primaryType gets automatically since it lists every registered primaryType in
  `_allPrimaryTypes`.
- **`showInLists`**: should this type appear in the Lists section on the home screen?
  Defaults to `true` in both `note_schema.json` (a `showInLists` sibling of that
  `oneOf` branch's `description`, annotation-only — not validated) and
  `NoteTypeSpec`. Only set `false` if this type shouldn't be browsable from that
  overview.

## Don't need to touch

- `add_screen.dart` — its type dropdown iterates `noteTypeSpecs` directly, so new types
  appear there automatically. Only special-case it (see the `hypothesis` branch in
  `_AddScreenState._createNote`) if a title-only `createFromSpec` create wouldn't validate.
- `note_editor_navigation.dart`, `relationship_dialog.dart` — both generic over any
  `NoteTypeSpec`/relType already.
- Any test file, unless the new type has validation edge cases worth covering in
  `test/json_schema_service_test.dart`.
