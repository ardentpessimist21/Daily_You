// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/hyphenation_en_us.dart';
import 'package:material_ui/material_ui.dart';

/// Reading-view text layout: justified like a book, with long words split
/// by a hyphen so the gaps between words stay small. Off is left-aligned.
class JustifyText {
  static bool get enabled => ConfigProvider.instance.get(Settings.justifyText);
}

/// Liang's hyphenation algorithm (the one TeX uses) with US English
/// patterns. Words are only split where a hyphen reads naturally.
class Hyphenation {
  Hyphenation._(String patterns, List<String> exceptions) {
    for (final pattern in patterns.split(' ')) {
      if (pattern.isEmpty) continue;
      final letters = StringBuffer();
      final levels = <int>[];
      var pending = 0;
      for (final unit in pattern.split('')) {
        final digit = int.tryParse(unit);
        if (digit != null) {
          pending = digit;
        } else {
          levels.add(pending);
          pending = 0;
          letters.write(unit);
        }
      }
      levels.add(pending);
      final key = letters.toString();
      _patterns[key] = levels;
      if (key.length > _maxLength) _maxLength = key.length;
    }
    for (final exception in exceptions) {
      final breaks = <int>[];
      var letters = 0;
      for (final unit in exception.split('')) {
        if (unit == '-') {
          breaks.add(letters);
        } else {
          letters++;
        }
      }
      _exceptions[exception.replaceAll('-', '')] = breaks;
    }
  }

  static final Hyphenation enUs =
      Hyphenation._(enUsHyphenationPatterns, enUsHyphenationExceptions);

  static const String softHyphen = '­';
  static const int minWordLength = 6;
  static const int leftMin = 2;
  static const int rightMin = 3;

  final Map<String, List<int>> _patterns = {};
  final Map<String, List<int>> _exceptions = {};
  final Map<String, List<int>> _cache = {};
  int _maxLength = 0;

  static final RegExp _word = RegExp(r"[A-Za-z]+");

  /// Where [word] can be split: the number of letters before each break.
  List<int> breaks(String word) {
    if (word.length < minWordLength) return const [];
    final lower = word.toLowerCase();
    final cached = _cache[lower];
    if (cached != null) return cached;
    final exception = _exceptions[lower];
    if (exception != null) return _cache[lower] = exception;

    final work = '.$lower.';
    final points = List<int>.filled(work.length + 1, 0);
    for (var i = 0; i < work.length; i++) {
      final last = (i + _maxLength).clamp(0, work.length);
      for (var j = i + 1; j <= last; j++) {
        final levels = _patterns[work.substring(i, j)];
        if (levels == null) continue;
        for (var k = 0; k < levels.length; k++) {
          if (levels[k] > points[i + k]) points[i + k] = levels[k];
        }
      }
    }
    final result = <int>[];
    for (var before = leftMin; before <= lower.length - rightMin; before++) {
      // A break after `before` letters sits before work[before + 1].
      if (points[before + 1].isOdd) result.add(before);
    }
    if (_cache.length > 5000) _cache.clear();
    return _cache[lower] = result;
  }

  /// [text] with invisible soft hyphens where words may be split.
  String softHyphenate(String text) => text.replaceAllMapped(_word, (match) {
        final word = match[0]!;
        final points = breaks(word);
        if (points.isEmpty) return word;
        final out = StringBuffer();
        var from = 0;
        for (final point in points) {
          out
            ..write(word.substring(from, point))
            ..write(softHyphen);
          from = point;
        }
        out.write(word.substring(from));
        return out.toString();
      });
}

/// Lays out a justified paragraph with hyphenation. Flutter splits words at
/// soft hyphens but doesn't draw the hyphen, so this finds the splits that
/// really land at a line end, turns only those into "-", and keeps every
/// other word whole.
class HyphenatedLayout {
  static const int _maxPasses = 4;

  static InlineSpan apply(
    InlineSpan span, {
    required double maxWidth,
    required TextStyle style,
    required TextScaler textScaler,
    TextDirection textDirection = TextDirection.ltr,
    Locale? locale,
  }) {
    if (!maxWidth.isFinite || maxWidth <= 0) return span;
    final soft = _mapText(
        span, (text, _) => Hyphenation.enUs.softHyphenate(text), _Counter());
    final plain = soft.toPlainText(includeSemanticsLabels: false);
    if (!plain.contains(Hyphenation.softHyphen)) return span;

    TextPainter layout(InlineSpan content, double width) => TextPainter(
          text: TextSpan(style: style, children: [content]),
          textDirection: textDirection,
          textScaler: textScaler,
          locale: locale,
        )..layout(maxWidth: width);

    // Measure with room for the "-" each split will add.
    final hyphenWidth =
        layout(const TextSpan(text: '-'), double.infinity).width;
    final first = layout(soft, (maxWidth - hyphenWidth).clamp(1, maxWidth));
    final chosen = <int>{};
    for (var i = 0; i < plain.length; i++) {
      if (plain[i] == Hyphenation.softHyphen && _endsLine(first, i)) {
        chosen.add(i);
      }
    }
    first.dispose();

    for (var pass = 0; pass < _maxPasses; pass++) {
      final result = _build(soft, plain, chosen);
      if (chosen.isEmpty) return result.$1;
      final painter = layout(result.$1, maxWidth);
      final misplaced = [
        for (final index in chosen)
          if (!_endsLine(painter, result.$2[index]!)) index
      ];
      painter.dispose();
      if (misplaced.isEmpty) return result.$1;
      chosen.removeAll(misplaced);
    }
    return _build(soft, plain, const {}).$1;
  }

  /// Whether a line ends right after the character at [index].
  static bool _endsLine(TextPainter painter, int index) {
    final line = painter.getLineBoundary(TextPosition(offset: index));
    return line.end == index + 1 &&
        index + 1 < painter.plainText.length &&
        painter.getLineBoundary(TextPosition(offset: index + 1)).start ==
            index + 1;
  }

  /// [soft] with the chosen soft hyphens as "-" and the rest removed, plus
  /// where each chosen hyphen ends up.
  static (InlineSpan, Map<int, int>) _build(
      InlineSpan soft, String plain, Set<int> chosen) {
    final finalIndex = <int, int>{};
    var removed = 0;
    for (var i = 0; i < plain.length; i++) {
      if (plain[i] != Hyphenation.softHyphen) continue;
      if (chosen.contains(i)) {
        finalIndex[i] = i - removed;
      } else {
        removed++;
      }
    }
    final span = _mapText(soft, (text, start) {
      if (!text.contains(Hyphenation.softHyphen)) return text;
      final out = StringBuffer();
      for (var i = 0; i < text.length; i++) {
        final unit = text[i];
        if (unit != Hyphenation.softHyphen) {
          out.write(unit);
        } else if (chosen.contains(start + i)) {
          out.write('-');
        }
      }
      return out.toString();
    }, _Counter());
    return (span, finalIndex);
  }

  /// Rewrites every text run in [span], keeping styles, links and widgets.
  /// [transform] gets each run and where it starts in the whole text.
  static InlineSpan _mapText(InlineSpan span,
      String Function(String text, int start) transform, _Counter at) {
    if (span is! TextSpan) {
      at.value += 1; // a placeholder, e.g. a checkbox
      return span;
    }
    String? text;
    if (span.text != null) {
      text = transform(span.text!, at.value);
      at.value += span.text!.length;
    }
    final children =
        span.children?.map((child) => _mapText(child, transform, at)).toList();
    return TextSpan(
      text: text,
      children: children,
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}

class _Counter {
  int value = 0;
}
