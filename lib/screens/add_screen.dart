import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_search.dart';
import '../models/note_type_spec.dart';
import '../state/add_type_usage_notifier.dart';
import '../state/note_index_notifier.dart';
import '../state/providers.dart';
import '../state/recent_history_notifier.dart';
import '../state/secondary_type_session.dart';
import 'note_detail_screen.dart';
import 'note_editor_navigation.dart';

/// Single note-creation form covering every `primaryType`, configurable
/// enough to back every place notes get created: the standalone Add flow
/// (from Home), the Lists screen's "new note" action, and the relationship
/// dialog's "create new related note" fallback — see `note_type_list_screen.dart`
/// and `relationship_dialog.dart`. A type picker, a title field that doubles
/// as a live fuzzy search over existing notes (to catch accidental
/// duplicates), and up to three actions.
class AddScreen extends ConsumerStatefulWidget {
  /// Types selectable in the dropdown. A single entry locks the type
  /// (dropdown disabled, no quick-select chips) — used by Lists (locked to
  /// that list's type) and single-type relationship adds. More than one
  /// entry leaves it open with [initialType] pre-selected. Defaults to every
  /// [NoteTypeSpec.showInLists] `primaryType` (`null` — resolved at build
  /// time from [noteTypeSpecs], so new types need no change here), excluding
  /// relationship-only types like `log` that would otherwise be creatable
  /// with nothing to attach to — those are only reachable by explicitly
  /// passing `allowedTypes`, as the relationship dialog does.
  final List<String>? allowedTypes;

  /// Pre-selected type; must be in [allowedTypes]. Defaults to 'scratchpad'
  /// if allowed, else the first allowed type.
  final String? initialType;

  /// Prefills the title field, e.g. carrying over a search query typed
  /// before the relationship dialog fell back to "create new".
  final String? initialTitle;

  final String appBarTitle;

  /// Adds a third "Add & Back" action that creates the note (running
  /// [onCreated]) then pops the route, for callers embedding this as a step
  /// within another flow (Lists, relationship dialog) rather than a
  /// standalone destination.
  final bool showBackButton;

  /// Called when the user taps a similar-note suggestion instead of typing
  /// a new title. Defaults to jumping to that note's detail view; the
  /// relationship dialog overrides this to attach the note as a
  /// relationship and close instead.
  final FutureOr<void> Function(BuildContext context, WidgetRef ref, String filename)?
      onSuggestionSelected;

  /// Side effect run right after a new note is created, before whichever
  /// action's navigation happens — the relationship dialog uses this to
  /// attach the freshly created note as a relationship.
  final FutureOr<void> Function(WidgetRef ref, String filename)? onCreated;

  const AddScreen({
    super.key,
    this.allowedTypes,
    this.initialType,
    this.initialTitle,
    this.appBarTitle = 'Add',
    this.showBackButton = false,
    this.onSuggestionSelected,
    this.onCreated,
  });

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  late final _titleController = TextEditingController(text: widget.initialTitle ?? '');
  final _titleFocusNode = FocusNode();
  // Preserves the TextField's Element (and its focus) across the narrow/wide
  // layout swap in build(), which changes the widget tree's shape whenever
  // _suggestions flips between empty and non-empty.
  final _titleFieldKey = GlobalKey();
  late final List<String> _allowedTypes = widget.allowedTypes ??
      [for (final spec in noteTypeSpecs) if (spec.showInLists) spec.primaryType];
  late String _primaryType = widget.initialType ??
      (_allowedTypes.contains('scratchpad') ? 'scratchpad' : _allowedTypes.first);

  /// The secondaryType picker's current value, when [_spec] has one to
  /// offer (see [_showSecondaryTypePicker]). Reset to that type's session
  /// last-chosen-or-default value whenever [_primaryType] changes.
  String? _secondaryType;
  bool _saving = false;

  /// Debounced similar-notes results for the current title text (see
  /// [_onTitleChanged]) — searched off the UI thread via
  /// [noteSearchWorkerProvider], since a synchronous per-keystroke scan
  /// over a large note collection would block the frame.
  List<NoteMatch> _suggestions = const [];
  Timer? _searchDebounce;
  var _searchGeneration = 0;
  late final ProviderSubscription<List<NormalizedNote>> _notesSubscription;

  @override
  void initState() {
    super.initState();
    _resetSecondaryType();
    _titleController.addListener(_onTitleChanged);
    _notesSubscription = ref.listenManual(normalizedNotesProvider, (_, next) {
      ref.read(noteSearchWorkerProvider).updateNotes(next);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _titleController.removeListener(_onTitleChanged);
    _notesSubscription.close();
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = _titleController.text;
    final generation = ++_searchGeneration;
    final matches = query.trim().isEmpty
        ? const <NoteMatch>[]
        : await ref.read(noteSearchWorkerProvider).search(query, _allowedTypes);
    if (!mounted || generation != _searchGeneration) return;
    setState(() => _suggestions = matches);
  }

  NoteTypeSpec get _spec => noteTypeSpecs.firstWhere((s) => s.primaryType == _primaryType);

  /// hypothesis is excluded from this even though it has `secondaryTypes` —
  /// there's no "create a pre-resolved hypothesis" affordance, so it always
  /// starts at its default (see [_resetSecondaryType]) with no picker shown.
  bool get _showSecondaryTypePicker => _spec.secondaryTypes.isNotEmpty && _primaryType != 'hypothesis';

  void _resetSecondaryType() {
    if (_showSecondaryTypePicker) {
      _secondaryType = ref.read(lastSecondaryTypeProvider.notifier).defaultFor(_spec);
    } else if (_spec.secondaryTypes.isNotEmpty) {
      _secondaryType = _spec.defaultSecondaryType;
    } else {
      _secondaryType = null;
    }
  }

  void _setPrimaryType(String type) {
    setState(() {
      _primaryType = type;
      _resetSecondaryType();
    });
  }

  /// log needs an automatic `createdAt`, beyond what a generic title-only
  /// create covers, so it goes through a dedicated method instead of
  /// [NoteIndexNotifier.createFromSpec].
  Future<String> _createNote(String title) {
    final notifier = ref.read(noteIndexProvider.notifier);
    if (_primaryType == 'log') {
      return notifier.createLog(title: title);
    }
    return notifier.createFromSpec(_spec, title: title, secondaryType: _secondaryType);
  }

  Future<String?> _commit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return null;

    setState(() => _saving = true);
    final filename = await _createNote(title);
    await widget.onCreated?.call(ref, filename);
    ref.read(addTypeUsageProvider.notifier).recordAdd(_primaryType);
    if (_showSecondaryTypePicker && _secondaryType != null) {
      ref.read(lastSecondaryTypeProvider.notifier).record(_primaryType, _secondaryType!);
    }
    return filename;
  }

  Future<void> _addAndShow() async {
    final spec = _spec;
    final title = _titleController.text.trim();
    final filename = await _commit();
    if (filename == null || !mounted) return;
    ref
        .read(recentHistoryProvider.notifier)
        .record(RecentEntry(kind: RecentEntryKind.note, id: filename, label: title));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailScreen(spec: spec, filename: filename)),
    );
  }

  Future<void> _addAndNext() async {
    final label = _spec.label;
    final filename = await _commit();
    if (filename == null || !mounted) return;
    _titleController.clear();
    setState(() => _saving = false);
    _titleFocusNode.requestFocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Added ${label.toLowerCase()}')));
  }

  Future<void> _addAndBack() async {
    final filename = await _commit();
    if (filename == null || !mounted) return;
    Navigator.pop(context);
  }

  Future<void> _selectSuggestion(NoteMatch match) async {
    if (widget.onSuggestionSelected != null) {
      await widget.onSuggestionSelected!(context, ref, match.filename);
      return;
    }
    final spec = noteTypeSpecs.firstWhere((s) => s.primaryType == match.primaryType);
    pushNoteEditor(context, spec: spec, filename: match.filename);
  }

  /// Below this body width, similar-notes suggestions are inlined under the
  /// title field (capped height, own scroll — see [_buildInlineSuggestions]).
  /// At or above it, there's enough spare horizontal space to give them a
  /// dedicated sidebar instead of pushing the action buttons down.
  static const double _wideLayoutBreakpoint = 720;
  static const double _inlineSuggestionsMaxHeight = 240;

  @override
  Widget build(BuildContext context) {
    final usageCounts = ref.watch(addTypeUsageProvider);
    final topTypes = (usageCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => e.key)
        .where(_allowedTypes.contains)
        .take(3)
        .toList();

    final formFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topTypes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in topTypes)
                ActionChip(
                  label: Text(
                    noteTypeSpecs.firstWhere((s) => s.primaryType == type).label,
                  ),
                  onPressed: _saving ? null : () => _setPrimaryType(type),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<String>(
          initialValue: _primaryType,
          decoration: const InputDecoration(
            labelText: 'Note type',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final type in _allowedTypes)
              DropdownMenuItem(
                value: type,
                child: Text(noteTypeSpecs.firstWhere((s) => s.primaryType == type).label),
              ),
          ],
          onChanged: (_saving || _allowedTypes.length == 1)
              ? null
              : (value) => _setPrimaryType(value!),
        ),
        if (_showSecondaryTypePicker) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(_primaryType),
            initialValue: _secondaryType,
            decoration: const InputDecoration(
              labelText: 'Secondary Type',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final type in _spec.secondaryTypes)
                DropdownMenuItem(value: type, child: Text(type)),
            ],
            onChanged: _saving ? null : (value) => setState(() => _secondaryType = value),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          key: _titleFieldKey,
          controller: _titleController,
          focusNode: _titleFocusNode,
          autofocus: true,
          minLines: 4,
          maxLines: 12,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _addAndNext,
                child: const Text('Add & Next'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _addAndShow,
                child: const Text('Add & Show'),
              ),
            ),
          ],
        ),
        if (widget.showBackButton) ...[
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _saving ? null : _addAndBack,
            child: const Text('Add & Back'),
          ),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              constraints.maxWidth >= _wideLayoutBreakpoint && _suggestions.isNotEmpty;

          if (!isWide) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    formFields,
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInlineSuggestions(context),
                    ],
                    actions,
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [formFields, actions],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Similar notes', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) =>
                                  _buildSuggestionTile(_suggestions[index]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Suggestions block for the narrow (single-column) layout: capped height
  /// with its own internal scroll, so a long match list can never push the
  /// action buttons below it off-screen.
  Widget _buildInlineSuggestions(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: _inlineSuggestionsMaxHeight),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text('Similar notes', style: Theme.of(context).textTheme.labelMedium),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) => _buildSuggestionTile(_suggestions[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(NoteMatch match) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.search),
      title: Text(match.title.isEmpty ? match.filename : match.title),
      subtitle: Text(
        noteTypeSpecs.firstWhere((s) => s.primaryType == match.primaryType).label,
      ),
      onTap: _saving ? null : () => _selectSuggestion(match),
    );
  }
}
