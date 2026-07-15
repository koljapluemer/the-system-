import 'dart:async';
import 'dart:isolate';

import '../models/note_search.dart';

class _UpdateNotes {
  final List<NormalizedNote> notes;
  const _UpdateNotes(this.notes);
}

class _SearchRequest {
  final int id;
  final String query;
  final List<String> allowedPrimaryTypes;
  const _SearchRequest(this.id, this.query, this.allowedPrimaryTypes);
}

class _SearchResponse {
  final int id;
  final List<NoteMatch> matches;
  const _SearchResponse(this.id, this.matches);
}

/// Runs [findSimilarNotes] on a long-lived worker isolate, so scoring the
/// note collection against a typed query never blocks the UI thread —
/// `add_screen.dart`'s title field used to call it synchronously inside
/// `build()` on every keystroke. The isolate is spawned lazily on first use
/// and kept alive for reuse (see `noteSearchWorkerProvider`'s
/// `keepAlive()`) rather than respawned per search, and it holds its own
/// copy of the normalized note list (pushed via [updateNotes] once per
/// note-index change) so a search request only has to send/receive the
/// query and results, not the whole note collection — re-copying that on
/// every debounced keystroke would itself be a non-trivial cost on a large
/// collection.
class NoteSearchWorker {
  Isolate? _isolate;
  SendPort? _toIsolate;
  Completer<void>? _ready;
  final _pending = <int, Completer<List<NoteMatch>>>{};
  var _nextId = 0;

  Future<void> _ensureStarted() {
    final ready = _ready;
    if (ready != null) return ready.future;

    final completer = Completer<void>();
    _ready = completer;
    final fromIsolate = ReceivePort();
    fromIsolate.listen((message) {
      if (message is SendPort) {
        _toIsolate = message;
        completer.complete();
      } else if (message is _SearchResponse) {
        _pending.remove(message.id)?.complete(message.matches);
      }
    });
    Isolate.spawn(_isolateMain, fromIsolate.sendPort).then((isolate) => _isolate = isolate);
    return completer.future;
  }

  /// Replaces the isolate's note snapshot. Fire-and-forget: a [search]
  /// racing this uses whichever snapshot the isolate has processed first,
  /// same race the old synchronous scan had against a mid-typing index
  /// update.
  Future<void> updateNotes(List<NormalizedNote> notes) async {
    await _ensureStarted();
    _toIsolate!.send(_UpdateNotes(notes));
  }

  Future<List<NoteMatch>> search(String query, List<String> allowedPrimaryTypes) async {
    await _ensureStarted();
    final id = _nextId++;
    final completer = Completer<List<NoteMatch>>();
    _pending[id] = completer;
    _toIsolate!.send(_SearchRequest(id, query, allowedPrimaryTypes));
    return completer.future;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _ready = null;
    _toIsolate = null;
  }

  static void _isolateMain(SendPort toMain) {
    final receivePort = ReceivePort();
    toMain.send(receivePort.sendPort);
    var notes = const <NormalizedNote>[];
    receivePort.listen((message) {
      if (message is _UpdateNotes) {
        notes = message.notes;
      } else if (message is _SearchRequest) {
        final matches = findSimilarNotes(
          notes,
          query: message.query,
          allowedPrimaryTypes: message.allowedPrimaryTypes,
        );
        toMain.send(_SearchResponse(message.id, matches));
      }
    });
  }
}
