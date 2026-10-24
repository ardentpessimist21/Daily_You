// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/utils/color_utils.dart';
import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:material_ui/material_ui.dart';

/// Maps style onto the Markdown constructs
class MarkdownPreviewStyles {
  const MarkdownPreviewStyles({
    required this.marker,
    required this.link,
    required this.quote,
    required this.codeBackground,
    required this.misspelling,
    required this.highlightBackground,
  });

  factory MarkdownPreviewStyles.fromTheme(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MarkdownPreviewStyles(
      marker: colors.outline,
      link: colors.primary,
      quote: colors.onSurfaceVariant,
      misspelling: colors.error,
      codeBackground: colors.surfaceContainerHighest,
      highlightBackground: Colors.yellow.shade700,
    );
  }

  static const double _quoteMarkerScale = 0.75;

  static double _headerScale(int level) => switch (level) {
        1 => 1.5,
        2 => 1.25,
        3 => 1.125,
        _ => 1,
      };

  final Color marker;
  final Color link;
  final Color quote;
  final Color codeBackground;
  final Color misspelling;
  final Color highlightBackground;

  @override
  bool operator ==(Object other) =>
      other is MarkdownPreviewStyles &&
      other.marker == marker &&
      other.link == link &&
      other.quote == quote &&
      other.codeBackground == codeBackground &&
      other.misspelling == misspelling &&
      other.highlightBackground == highlightBackground;

  @override
  int get hashCode => Object.hash(
      marker, link, quote, codeBackground, misspelling, highlightBackground);

  TextStyle apply(TextStyle style, MarkdownSpan span) {
    final sized = span.construct == MarkdownConstruct.header
        ? style.copyWith(
            fontSize: (style.fontSize ?? 16) * _headerScale(span.headerLevel))
        : style;

    if (span.role == MarkdownSpanRole.marker) {
      final muted = sized.copyWith(color: marker);
      return switch (span.construct) {
        MarkdownConstruct.blockquote => muted.copyWith(
            fontWeight: FontWeight.normal,
            fontSize: (sized.fontSize ?? 16) * _quoteMarkerScale,
          ),
        MarkdownConstruct.bulletList =>
          muted.copyWith(fontWeight: FontWeight.bold),
        _ => muted.copyWith(fontWeight: FontWeight.normal),
      };
    }

    switch (span.construct) {
      case MarkdownConstruct.bold:
        return sized.copyWith(fontWeight: FontWeight.bold);
      case MarkdownConstruct.italic:
        return sized.copyWith(fontStyle: FontStyle.italic);
      case MarkdownConstruct.strikethrough:
        return _decorate(sized, TextDecoration.lineThrough);
      case MarkdownConstruct.highlight:
        return sized.copyWith(
          backgroundColor: highlightBackground,
          color: contrastingTextColor(highlightBackground),
        );
      case MarkdownConstruct.header:
        return sized.copyWith(fontWeight: FontWeight.bold);
      case MarkdownConstruct.link:
        return _decorate(sized.copyWith(color: link), TextDecoration.underline);
      case MarkdownConstruct.inlineCode:
        return sized.copyWith(backgroundColor: codeBackground);
      case MarkdownConstruct.blockquote:
        return sized.copyWith(color: quote);
      case MarkdownConstruct.codeBlock:
      case MarkdownConstruct.bulletList:
      case MarkdownConstruct.numberedList:
      case MarkdownConstruct.horizontalRule:
        return sized;
    }
  }
}

/// Flattens the nested [spans] into one styled span per stretch of text
TextSpan buildMarkdownPreviewSpan({
  required String text,
  required List<MarkdownSpan> spans,
  required TextStyle baseStyle,
  required MarkdownPreviewStyles styles,
  TextRange composing = TextRange.empty,
  List<TextRange> misspellings = const [],
}) {
  if (text.isEmpty) return TextSpan(style: baseStyle);

  final underlined = <TextRange>[
    if (composing.isValid && composing.end <= text.length) composing,
  ];
  // Sorted and merged where they overlap, so the sweep below only ever needs
  // to look at the next one (long entries can have hundreds).
  final marked = _sortedUnion([
    for (final range in misspellings)
      if (range.isValid && range.end <= text.length) range,
  ]);

  final children = <TextSpan>[];
  final activeSpans = <MarkdownSpan>[];
  var cursor = 0;
  var nextSpan = 0;
  var nextMarked = 0;

  while (cursor < text.length) {
    while (nextSpan < spans.length && spans[nextSpan].start <= cursor) {
      activeSpans.add(spans[nextSpan++]);
    }
    while (nextMarked < marked.length && marked[nextMarked].end <= cursor) {
      nextMarked++;
    }

    var segmentEnd =
        nextSpan < spans.length ? spans[nextSpan].start : text.length;
    for (final span in activeSpans) {
      segmentEnd = min(segmentEnd, span.end);
    }
    for (final range in underlined) {
      if (range.start > cursor) segmentEnd = min(segmentEnd, range.start);
      if (range.end > cursor) segmentEnd = min(segmentEnd, range.end);
    }
    final mark = nextMarked < marked.length ? marked[nextMarked] : null;
    if (mark != null) {
      segmentEnd = min(segmentEnd, mark.start > cursor ? mark.start : mark.end);
    }

    var style = baseStyle;
    for (final span in activeSpans) {
      style = styles.apply(style, span);
    }
    if (_covers(underlined, cursor, segmentEnd)) {
      style = _decorate(style, TextDecoration.underline);
    }
    if (mark != null && mark.start <= cursor && mark.end >= segmentEnd) {
      style = _decorate(style, TextDecoration.underline).copyWith(
        decorationColor: styles.misspelling,
        decorationStyle: TextDecorationStyle.wavy,
      );
    }

    children
        .add(TextSpan(text: text.substring(cursor, segmentEnd), style: style));
    cursor = segmentEnd;
    activeSpans.removeWhere((span) => span.end <= cursor);
  }

  return TextSpan(style: baseStyle, children: children);
}

/// [ranges] in order, with overlapping ones joined
List<TextRange> _sortedUnion(List<TextRange> ranges) {
  if (ranges.length < 2) return ranges;
  final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
  final joined = <TextRange>[sorted.first];
  for (final range in sorted.skip(1)) {
    final last = joined.last;
    if (range.start < last.end) {
      if (range.end > last.end) {
        joined.last = TextRange(start: last.start, end: range.end);
      }
    } else {
      joined.add(range);
    }
  }
  return joined;
}

bool _covers(List<TextRange> ranges, int start, int end) {
  for (final range in ranges) {
    if (start >= range.start && end <= range.end) return true;
  }
  return false;
}

TextStyle _decorate(TextStyle style, TextDecoration decoration) {
  final existing = style.decoration;
  return style.copyWith(
    decoration: existing == null || existing == TextDecoration.none
        ? decoration
        : TextDecoration.combine([existing, decoration]),
  );
}
