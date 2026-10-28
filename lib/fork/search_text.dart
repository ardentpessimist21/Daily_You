// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/locations.dart';

/// What Gallery search looks through: the words you see in an entry, not
/// its Markdown. Link text counts (also inside italics or bold), link
/// addresses and the hidden places line don't, and invisible characters
/// pasted in from other apps (such as the direction marks Messenger and
/// Facebook add around names) are ignored on both sides.
class SearchText {
  /// Invisible format characters: zero-width spaces and joiners, direction
  /// marks and isolates, word joiners, soft hyphens and the BOM.
  static final RegExp _invisible = RegExp(
      r'[\u00AD\u061C\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069\uFEFF]');

  /// The same characters as [_invisible], checked without a RegExp.
  static bool isInvisible(int u) =>
      u == 0x00AD ||
      u == 0x061C ||
      u == 0x180E ||
      (u >= 0x200B && u <= 0x200F) ||
      (u >= 0x202A && u <= 0x202E) ||
      (u >= 0x2060 && u <= 0x2064) ||
      (u >= 0x2066 && u <= 0x2069) ||
      u == 0xFEFF;

  static final RegExp _image = RegExp(r'!\[([^\]\n]*)\]\([^)\n]*\)');
  static final RegExp _link = RegExp(r'\[([^\]\n]*)\]\([^)\n]*\)');
  static final RegExp _autolink =
      RegExp(r'<[a-z][a-z0-9+.-]*:[^>\s]*>', caseSensitive: false);
  static final RegExp _lineMarks = RegExp(
      r'^[ \t]{0,3}(?:#{1,6}[ \t]+|>+[ \t]?|[-*+][ \t]+(?:\[[ xX]\][ \t]+)?|\d+[.)][ \t]+)',
      multiLine: true);
  static final RegExp _inlineMarks = RegExp(r'\*\*|__|==|~~|`|\*|_');

  /// [raw] entry text as plain visible words: Markdown marks and link
  /// addresses removed, invisible characters dropped, lower case.
  static String visible(String raw) {
    var text = EntryLocations.bodyOf(raw);
    // Links first, so marks inside the address (often `_` in Facebook or
    // Maps links) can't pair up with the italics around the link
    text = text
        .replaceAllMapped(_image, (m) => m[1]!)
        .replaceAllMapped(_link, (m) => m[1]!)
        .replaceAll(_autolink, '')
        .replaceAll(_lineMarks, '')
        .replaceAll(_inlineMarks, '');
    return fold(text);
  }

  /// [text] in lower case with invisible characters removed.
  static String fold(String text) =>
      text.replaceAll(_invisible, '').toLowerCase();

  static final Map<String, String> _cache = {};

  static String _visibleCached(String raw) {
    final cached = _cache[raw];
    if (cached != null) return cached;
    if (_cache.length > 20000) _cache.clear();
    return _cache[raw] = visible(raw);
  }

  /// Whether [raw] entry text contains [query] as visible words.
  static bool matches(String raw, String query) {
    final needle = fold(query);
    if (needle.isEmpty) return true;
    return _visibleCached(raw).contains(needle);
  }

  /// How many times [query] appears in [raw]'s visible words.
  static int count(String raw, String query) {
    final needle = fold(query);
    if (needle.isEmpty) return 0;
    final haystack = _visibleCached(raw);
    var count = 0;
    var start = 0;
    while (true) {
      final index = haystack.indexOf(needle, start);
      if (index < 0) return count;
      count++;
      start = index + needle.length;
    }
  }
}

/// [text] folded for matching (lower case, invisible characters dropped),
/// remembering where each folded character came from, so a match found in
/// the folded text can be marked in the original.
class FoldedText {
  FoldedText(this.original) {
    final buffer = StringBuffer();
    for (var i = 0; i < original.length; i++) {
      final unit = original.codeUnitAt(i);
      if (SearchText.isInvisible(unit)) continue;
      final lower = String.fromCharCode(unit).toLowerCase();
      for (var j = 0; j < lower.length; j++) {
        buffer.writeCharCode(lower.codeUnitAt(j));
        _starts.add(i);
      }
    }
    folded = buffer.toString();
  }

  final String original;
  late final String folded;
  final List<int> _starts = [];

  /// Position in [original] of the folded character at [index].
  int startOf(int index) => _starts[index];

  /// Position in [original] just after the folded range ending at [end].
  int endOf(int end) => end <= 0 ? 0 : _starts[end - 1] + 1;

  /// Original ranges of every match of [needle] (already folded).
  List<(int, int)> matches(String needle) {
    final ranges = <(int, int)>[];
    if (needle.isEmpty) return ranges;
    var start = 0;
    while (true) {
      final index = folded.indexOf(needle, start);
      if (index < 0) return ranges;
      ranges.add((startOf(index), endOf(index + needle.length)));
      start = index + needle.length;
    }
  }
}
