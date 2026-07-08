import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../models/note_index.dart';
import '../models/note_type_spec.dart';
import 'providers.dart';

/// The app-wide cache of every note in the data folder. Built once per
/// folder by scanning disk (see [NotesService.scanNotes]), then kept in sync
/// in memory as the app itself writes/deletes/creates notes — this app is
/// the only writer to the folder, so no external-change staleness handling
/// is needed. All triage/list/floating-notes flows read from this instead of
/// each re-scanning disk independently.
class NoteIndexNotifier extends AsyncNotifier<NoteIndex> {
  @override
  Future<NoteIndex> build() async {
    // Await rather than read-and-bang: if dataFolderProvider hasn't resolved
    // yet, watching its raw AsyncValue and racing a null .value would throw,
    // and the resulting rebuild-on-settle would abandon this build's Future
    // — orphaning anyone already awaiting it. Awaiting .future here instead
    // suspends properly until it settles.
    final folder = (await ref.watch(dataFolderProvider.future))!;
    final entries = <String, NoteFile>{};
    final unparsable = <String>{};
    await for (final result in ref.read(notesServiceProvider).scanNotes(folder)) {
      if (result.data != null) {
        entries[result.filename] = result.data!;
      } else {
        unparsable.add(result.filename);
      }
    }
    return NoteIndex(entries: entries, unparsable: unparsable);
  }

  Future<void> write(String filename, NoteFile content) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    await ref.read(notesServiceProvider).writeJsonFile(folder, filename, content);
    await update((index) => index.copyWith(entries: {...index.entries, filename: content}));
  }

  Future<void> delete(String filename) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    await ref.read(notesServiceProvider).deleteJsonFile(folder, filename);
    await update((index) => index.copyWith(entries: {...index.entries}..remove(filename)));
  }

  /// Creates a new `primaryType: "unknown"` note from the Quick Add flow.
  Future<String> createQuickNote({required String title, String body = ''}) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    final filename =
        await ref.read(notesServiceProvider).createQuickNote(folder, title: title, body: body);
    await update((index) => index.copyWith(entries: {
          ...index.entries,
          filename: {'primaryType': 'unknown', 'title': title, 'body': body},
        }));
    return filename;
  }

  /// Creates a new `primaryType: "hypothesis"` note, ACTIVE with empty
  /// context/experiment/notes/findings sections, from the inline add field on
  /// the Hypotheses screen.
  Future<String> createHypothesis({required String title}) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    final content = <String, dynamic>{
      'primaryType': 'hypothesis',
      'title': title,
      'status': 'ACTIVE',
      'context': <String>[],
      'experiment': <String>[],
      'notes': <String>[],
      'findings': <String>[],
    };
    final filename =
        await ref.read(notesServiceProvider).createNote(folder, content, slugSource: title);
    await update((index) => index.copyWith(entries: {...index.entries, filename: content}));
    return filename;
  }

  /// Creates a new note of [spec]'s primaryType with [title] and an empty
  /// string for every other field in [spec.fields] (e.g. `content`), for the
  /// "new note" action on a type's Lists screen — see NoteTypeSpec.creatable.
  Future<String> createFromSpec(NoteTypeSpec spec, {required String title}) async {
    final folder = (await ref.read(dataFolderProvider.future))!;
    final content = <String, dynamic>{'primaryType': spec.primaryType, 'title': title};
    for (final field in spec.fields) {
      if (field.key != 'title') content[field.key] = '';
    }
    final filename =
        await ref.read(notesServiceProvider).createNote(folder, content, slugSource: title);
    await update((index) => index.copyWith(entries: {...index.entries, filename: content}));
    return filename;
  }

  /// Forces a fresh full-folder rescan, e.g. as a manual escape hatch if the
  /// in-memory index is ever suspected to have drifted from disk.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final noteIndexProvider = AsyncNotifierProvider<NoteIndexNotifier, NoteIndex>(NoteIndexNotifier.new);
