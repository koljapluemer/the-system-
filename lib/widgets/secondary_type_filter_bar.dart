import 'package:flutter/material.dart';

/// Standardized "show/hide by secondary type" control for any list view of a
/// primaryType that has [NoteTypeSpec.secondaryTypes]: one FilterChip per
/// value, toggling whether notes of that secondaryType are shown. Callers own
/// the current [visible] set (typically backed by a session-only provider)
/// and receive the updated set via [onChanged].
class SecondaryTypeFilterBar extends StatelessWidget {
  final List<String> secondaryTypes;
  final Set<String> visible;
  final ValueChanged<Set<String>> onChanged;

  const SecondaryTypeFilterBar({
    super.key,
    required this.secondaryTypes,
    required this.visible,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final type in secondaryTypes)
            FilterChip(
              label: Text(type),
              selected: visible.contains(type),
              onSelected: (selected) => onChanged(
                selected ? {...visible, type} : visible.difference({type}),
              ),
            ),
        ],
      ),
    );
  }
}
