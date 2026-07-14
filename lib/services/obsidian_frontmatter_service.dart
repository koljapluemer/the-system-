import 'package:yaml/yaml.dart';

/// Parses Obsidian-style frontmatter — YAML, with or without the `---`
/// delimiters Obsidian wraps it in — into a JSON-compatible map, for merging
/// into a note's `extraData` (see the "Add props from Obsidian" action on a
/// note's view screen). Prop names and nesting are arbitrary; this service
/// doesn't interpret them, just converts YAML types to their JSON
/// equivalents (`YamlMap`/`YamlList` to `Map`/`List`).
class ObsidianFrontmatterService {
  const ObsidianFrontmatterService();

  /// Throws [FormatException] if [text] isn't valid YAML, or parses to
  /// something other than a mapping (or nothing) at the top level.
  Map<String, dynamic> parse(String text) {
    final stripped = _stripDelimiters(text);
    if (stripped.trim().isEmpty) return {};

    Object? doc;
    try {
      doc = loadYaml(stripped);
    } on YamlException catch (e) {
      throw FormatException(e.message);
    }
    if (doc == null) return {};
    if (doc is! YamlMap) {
      throw const FormatException('Frontmatter must be a set of "key: value" pairs.');
    }
    return _toJson(doc) as Map<String, dynamic>;
  }

  /// Obsidian frontmatter is conventionally wrapped in a leading and
  /// trailing `---` line; strip that if present so plain YAML also works.
  String _stripDelimiters(String text) {
    final lines = text.split('\n');
    var start = 0;
    var end = lines.length;
    while (start < end && lines[start].trim().isEmpty) {
      start++;
    }
    if (start < end && lines[start].trim() == '---') {
      start++;
      var closing = end;
      while (closing > start && lines[closing - 1].trim().isEmpty) {
        closing--;
      }
      if (closing > start && lines[closing - 1].trim() == '---') {
        end = closing - 1;
      }
    }
    return lines.sublist(start, end).join('\n');
  }

  dynamic _toJson(dynamic node) {
    if (node is YamlMap) {
      return {for (final entry in node.entries) entry.key.toString(): _toJson(entry.value)};
    }
    if (node is YamlList) {
      return [for (final item in node) _toJson(item)];
    }
    return node;
  }
}
