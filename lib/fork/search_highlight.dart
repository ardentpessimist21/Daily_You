// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/color_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// Marks Gallery search matches in entry text, matching the search itself:
/// plain, case-insensitive text.
class SearchHighlight {
  static final Color matchColor = Colors.orange.shade300;
  static final Color currentColor = Colors.deepOrange.shade600;

  /// How many times [query] appears in [text].
  static int count(String text, String query) {
    if (query.isEmpty) return 0;
    final haystack = text.toLowerCase();
    final needle = query.toLowerCase();
    var count = 0;
    var start = 0;
    while (true) {
      final index = haystack.indexOf(needle, start);
      if (index < 0) return count;
      count++;
      start = index + needle.length;
    }
  }

  /// Text for a card preview: the start of [text], or, when the first match
  /// sits further down than the card shows, a snippet starting near it.
  static String preview(String text, String query, {int visibleChars = 160}) {
    if (query.isEmpty) return text;
    final index = text.toLowerCase().indexOf(query.toLowerCase());
    if (index < visibleChars) return text;
    // Start at the beginning of the match's line, or a little before it.
    final lineStart = text.lastIndexOf('\n', index) + 1;
    var start = index - lineStart <= 60 ? lineStart : index - 40;
    final space = text.indexOf(' ', start);
    if (start != lineStart && space >= 0 && space < index) start = space + 1;
    return '…${text.substring(start)}';
  }
}

/// Numbers matches in the order a markdown block builds its text, and
/// remembers which built block holds each one so a view can scroll to it.
class SearchMatchCounter {
  SearchMatchCounter(this.query, {this.current, this.blockKeys});

  final String query;
  final int? current;

  /// Filled with one key per match: the block that holds it.
  final List<GlobalKey>? blockKeys;

  int _next = 0;

  /// [span] with each match wrapped in a highlight, and how many it found.
  (InlineSpan, int) mark(InlineSpan span) {
    final before = _next;
    final marked = _mark(span);
    return (marked, _next - before);
  }

  InlineSpan _mark(InlineSpan span) {
    if (span is! TextSpan) return span;
    final text = span.text;
    final children = span.children;
    final hasText = text != null && text.isNotEmpty;
    if (!hasText && (children == null || children.isEmpty)) return span;

    final before = _next;
    final pieces = hasText ? _split(text, span.recognizer) : <InlineSpan>[];
    final markedChildren = children?.map(_mark).toList();
    if (_next == before) return span;
    return TextSpan(
      style: span.style,
      semanticsLabel: span.semanticsLabel,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      locale: span.locale,
      spellOut: span.spellOut,
      children: [
        ...pieces,
        ...?markedChildren,
      ],
    );
  }

  List<InlineSpan> _split(String text, GestureRecognizer? recognizer) {
    final lower = text.toLowerCase();
    final needle = query.toLowerCase();
    final pieces = <InlineSpan>[];
    var start = 0;
    while (true) {
      final index = needle.isEmpty ? -1 : lower.indexOf(needle, start);
      if (index < 0) {
        if (start < text.length) {
          pieces.add(
              TextSpan(text: text.substring(start), recognizer: recognizer));
        }
        return pieces;
      }
      if (index > start) {
        pieces.add(TextSpan(
            text: text.substring(start, index), recognizer: recognizer));
      }
      final isCurrent = _next == current;
      final background =
          isCurrent ? SearchHighlight.currentColor : SearchHighlight.matchColor;
      pieces.add(TextSpan(
        text: text.substring(index, index + needle.length),
        recognizer: recognizer,
        style: TextStyle(
          backgroundColor: background,
          color: contrastingTextColor(background),
        ),
      ));
      _next++;
      start = index + needle.length;
    }
  }
}

/// A small "🔍 3" badge for cards whose matches aren't visible, such as
/// photo tiles in the Grid.
class SearchMatchBadge extends StatelessWidget {
  const SearchMatchBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AppLocalizations.of(context)!.searchMatchCount(count),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                size: 14, color: colorScheme.onInverseSurface),
            const SizedBox(width: 3),
            Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onInverseSurface)),
          ],
        ),
      ),
    );
  }
}

/// "2 of 5 ▲ ▼ ✕" bar for moving between matches in an opened entry.
class SearchMatchNavigator extends StatelessWidget {
  const SearchMatchNavigator({
    super.key,
    required this.current,
    required this.total,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  final int current;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: colorScheme.secondaryContainer,
      elevation: 2,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                size: 18, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Text(
              l10n.searchMatchPosition(current + 1, total),
              style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.searchPreviousMatch,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
              onPressed: total > 1 ? onPrevious : null,
            ),
            IconButton(
              tooltip: l10n.searchNextMatch,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: total > 1 ? onNext : null,
            ),
            IconButton(
              tooltip: l10n.searchClearHighlights,
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
