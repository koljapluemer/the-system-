# Note storage & the shared index

Notes are flat JSON files in a single user-chosen data folder, one file per
note, validated against `assets/note_schema.json`. Reading/writing/deleting
individual files goes through `NotesService` (`lib/services/notes_service.dart`).

## Why there's an index

Early on, each flow (Scratchpad Triage, Art Triage, the floating-notes
canvas, the Lists screens, the invalid-JSON checker) independently scanned
the *entire* data folder from disk whenever it opened. At real vault sizes
(the folder can hold up to ~100k small JSON files) that meant every
navigation paid a full rescan for data that mostly hadn't changed since the
last visit.

The fix is `NoteIndexNotifier` (`lib/state/note_index_notifier.dart`): one
shared, app-wide, in-memory cache of every note, background-loaded once per
data folder, that all of the above now read from instead of duplicating the
scan.

**Assumption: this app is the only writer to the data folder.** There's no
file-watching and no rescan-on-external-change. If something outside the app
edits the folder while it's open, the in-memory index will disagree with
disk until the app restarts (or `NoteIndexNotifier.refresh()` is called
manually). This is a deliberate simplification, not an oversight — revisit it
if the app ever needs to tolerate concurrent external writers (e.g. a sync
client editing files live).

## The three layers

1. **`NotesService`** (`lib/services/notes_service.dart`) — pure single-file
   IO: `readJsonFile`/`writeJsonFile`/`deleteJsonFile`/`createQuickNote`, plus
   one generic, type-agnostic, concurrency-batched folder scan: `scanNotes()`,
   which yields a `NoteScanResult` (filename + decoded content, or `null` data
   if the file wasn't parsable as a JSON object) for every `.json` file. No
   caching, no primaryType filtering — just disk IO.
2. **`NoteIndex`** (`lib/models/note_index.dart`) — a plain, disk-free
   snapshot: `entries` (filename → decoded content) plus `unparsable`
   (filenames that failed to decode), with small query helpers
   (`untriagedOfType`, `summariesOfType`, `floatingPool`) that every consumer
   filters through instead of re-implementing folder scans. Kept as a plain
   model (not Riverpod state) so `JsonSchemaService` can depend on it without
   `services/` reaching into `state/`.
3. **`NoteIndexNotifier`** (`lib/state/note_index_notifier.dart`) — the live
   Riverpod cache, `AsyncNotifier<NoteIndex>`. `build()` runs `scanNotes()`
   once per data folder and returns the assembled `NoteIndex`. Every mutation
   the app performs — `write`, `delete`, `createQuickNote` — writes to disk
   *and* patches the in-memory `entries` map, so every other screen watching
   `noteIndexProvider` sees the change immediately, with no manual reload
   anywhere.

Consumers: `TriageNotifier` (shared base for Art/Scratchpad triage),
`FloatingNotesNotifier`, `NoteTypeListScreen`, `NoteEditScreen`,
`QuickAddScreen`, and `home_screen.dart`'s invalid-JSON check all read from
`noteIndexProvider` instead of calling `NotesService`'s scan methods
directly (those methods no longer exist — `scanNotes` is the only one left).

## The one real gotcha

The data folder can be changed mid-session from Home's "change data folder"
button, from *any* screen, including one with a Triage flow already open and
mid-flight. `TriageNotifier` keeps `ref.watch(dataFolderProvider)` in
`build()` purely as a rebuild trigger (it doesn't store the value — lookups
go through the index) so its queue rebuilds against the new folder rather
than silently keeping the old one. Because that rebuild can race an
in-flight async init/load chain from the *previous* folder, `TriageNotifier`
guards every `state = ...` assignment with a small instance-level generation
counter, so a stale chain from before the folder switch can never clobber a
fresher one. If you touch `TriageNotifier`, keep that guard — it's not
decorative.
