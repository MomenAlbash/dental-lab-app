/// How a laboratory is told apart at a glance: a colour that is always the
/// same for the same laboratory, and its initials.
///
/// Derived from the id rather than stored anywhere, so every device and every
/// session agrees without asking the server. Pure functions — the palette's
/// actual colours live with the badge that draws them.
abstract final class LaboratoryIdentity {
  /// How many distinct colours the badge palette has.
  static const paletteSize = 8;

  /// A stable slot in the palette for [laboratoryId].
  ///
  /// FNV-1a over the id's code units, not [String.hashCode]: Dart does not
  /// promise that one stays the same between runs, and a laboratory whose
  /// colour changes on every launch is worse than no colour at all.
  static int colorIndexFor(String laboratoryId) {
    var hash = 0x811c9dc5;
    for (final unit in laboratoryId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash % paletteSize;
  }

  /// Up to two letters: the first of the first two words, or the first two
  /// letters of a single word. Arabic and Latin alike.
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '؟';
    if (words.length == 1) {
      final runes = _withoutArticle(words.single).runes.take(2);
      return String.fromCharCodes(runes);
    }
    return String.fromCharCodes([
      _withoutArticle(words[0]).runes.first,
      _withoutArticle(words[1]).runes.first,
    ]);
  }

  /// "النور" → "نور": nearly every Arabic laboratory name has the definite
  /// article somewhere, and initials that all read "ا" tell nothing apart.
  static String _withoutArticle(String word) =>
      word.startsWith('ال') && word.length > 2 ? word.substring(2) : word;
}
