import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_search_query.dart';
import '../models/note_type_spec.dart';
import '../state/note_index_notifier.dart';
import 'note_editor_navigation.dart';
import 'search_navigation.dart';

/// Global full-text search over every note (see [searchNotes]), reachable
/// from Home's "Search" flow tile and from `.search` chips in the
/// recent-history bar (see `search_navigation.dart`). Results update live as
/// the user types (debounced), but a query is only recorded into
/// [recentHistoryProvider] on explicit submit — not on every debounced
/// keystroke — so history isn't spammed with partial queries.
class SearchScreen extends ConsumerStatefulWidget {
  /// Prefilled query, e.g. when re-opened from a recent-search chip. Results
  /// for it are shown immediately on first frame, no retyping required.
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  List<NoteSearchResult> _results = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    if (widget.initialQuery.trim().isNotEmpty) _runSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  void _runSearch() {
    final entries = ref.read(noteIndexProvider).value?.entries ?? const {};
    final results = searchNotes(entries, _controller.text);
    if (!mounted) return;
    setState(() => _results = results);
  }

  void _openResult(NoteSearchResult result) {
    final spec = noteTypeSpecs.firstWhere((s) => s.primaryType == result.primaryType);
    pushNoteEditor(context, spec: spec, filename: result.filename);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(noteIndexProvider); // re-run search if notes change elsewhere

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery.isEmpty,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Search notes',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (query) => recordSearch(ref, query),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_controller.text.trim().isEmpty) {
      return const Center(child: Text('Type to search.'));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No matches.'));
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _results[index];
        return ListTile(
          title: Text(result.title.isEmpty ? result.filename : result.title),
          subtitle: Text(
            noteTypeSpecs.firstWhere((s) => s.primaryType == result.primaryType).label,
          ),
          onTap: () => _openResult(result),
        );
      },
    );
  }
}
