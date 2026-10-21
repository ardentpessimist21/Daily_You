// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/checklists.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/search_highlight.dart';
import 'package:daily_you/widgets/markdown_highlight_syntax.dart';
import 'package:material_ui/material_ui.dart';
import 'package:markdown_widget/markdown_widget.dart';

// Fixes duplicate scaling issues with markdown_widget
// See: https://github.com/asjqkkkk/markdown_widget/issues/208
class ScaledMarkdown extends StatelessWidget {
  final String data;
  final int? maxCharacters;
  final double scaleFactor;
  final bool compact;
  final bool selectable;

  /// When set, checklist boxes can be tapped; called with the box's index
  /// (0 = first box in the text).
  final void Function(int index)? onCheckboxTap;

  /// Gallery search text to highlight, if any.
  final String? searchQuery;

  /// The match to highlight more strongly (0 = first).
  final int? currentMatch;

  /// When given, filled with one key per match: the text block holding it,
  /// so the page can scroll to a match.
  final List<GlobalKey>? matchKeys;

  /// Justifies ordinary paragraphs, for reading. Headings, lists,
  /// checklists and quotes stay left-aligned.
  final bool justify;

  const ScaledMarkdown({
    super.key,
    required this.data,
    this.maxCharacters,
    this.scaleFactor = 1,
    this.compact = false,
    this.selectable = true,
    this.onCheckboxTap,
    this.searchQuery,
    this.currentMatch,
    this.matchKeys,
    this.justify = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String text = data;

    if (maxCharacters != null && text.length > maxCharacters!) {
      text = "${text.substring(0, maxCharacters)}…";
    }

    // Get the device's current text scaling to respect user settings
    final deviceScaler = MediaQuery.textScalerOf(context);
    // Apply custom scaling to the user's text scale
    final customScaler = TextScaler.linear(deviceScaler.scale(scaleFactor));

    final baseConfig = theme.brightness == Brightness.light
        ? MarkdownConfig.defaultConfig
        : MarkdownConfig.darkConfig;
    final paragraphStyle = baseConfig.p.textStyle;
    final bulletOffset =
        (paragraphStyle.fontSize ?? 16.0) * (paragraphStyle.height ?? 1.2) / 2;
    // Boxes are built in document order, so counting them gives each one's
    // index. Wrapping around keeps it right if the block rebuilds.
    final boxCount = onCheckboxTap == null ? 0 : Checklists.count(text);
    var nextBox = 0;
    final config = baseConfig.copy(configs: [
      if (onCheckboxTap != null && boxCount > 0)
        CheckBoxConfig(builder: (checked) {
          final index = nextBox++ % boxCount;
          return _TappableCheckbox(
            checked: checked,
            onTap: () => onCheckboxTap!(index),
          );
        }),
      // Entry links open in the app; websites and places outside it.
      LinkConfig(
        style: TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: theme.colorScheme.primary,
        ),
        onTap: (url) => EntryLinks.open(context, url),
      ),
      ListConfig(
        marker: (isOrdered, depth, index) => isOrdered
            ? null
            : getDefaultMarker(false, depth, theme.colorScheme.onSurface, index,
                bulletOffset, baseConfig),
      ),
    ]);

    final query = searchQuery ?? '';
    matchKeys?.clear();
    final matchCounter = query.isEmpty
        ? null
        : SearchMatchCounter(query,
            current: currentMatch, blockKeys: matchKeys);

    // Top-level paragraphs, by identity, so they can be justified.
    final paragraphs = Set<InlineSpan>.identity();

    final markdown = MarkdownBlock(
      selectable: false,
      config: config,
      generator: MarkdownGenerator(
        inlineSyntaxList: [HighlightSyntax()],
        generators: [highlightGenerator(Colors.yellow.shade700)],
        spanNodeBuilder: justify
            ? (node) {
                final built = node.build();
                final span =
                    built is TextSpan ? built : TextSpan(children: [built]);
                // Each top-level block arrives wrapped in an empty node.
                if (node is ElementNode &&
                    node.children.length == 1 &&
                    node.children.first is ParagraphNode) {
                  paragraphs.add(span);
                }
                return span;
              }
            : null,
        richTextBuilder: (original) {
          final justified = paragraphs.contains(original);
          // Matches are numbered here, in the order blocks are built.
          var span = original;
          GlobalKey? blockKey;
          if (matchCounter != null) {
            final (marked, found) = matchCounter.mark(original);
            span = marked;
            if (found > 0 && matchKeys != null) {
              blockKey = GlobalKey();
              for (var i = 0; i < found; i++) {
                matchKeys!.add(blockKey);
              }
            }
          }
          final block = Builder(builder: (context) {
            final shouldIgnoreTextScaler =
                context.getInheritedWidgetOfExactType<_WithTextScalar>() !=
                    null;

            final child = Text.rich(
              span,
              textAlign: justified ? TextAlign.justify : null,
              textScaler:
                  shouldIgnoreTextScaler ? TextScaler.noScaling : customScaler,
            );

            return shouldIgnoreTextScaler
                ? child
                : _WithTextScalar(child: child);
          });
          return blockKey == null
              ? block
              : KeyedSubtree(key: blockKey, child: block);
        },
        linesMargin: compact
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: 8, top: 2),
      ),
      data: text,
    );

    return selectable ? SelectionArea(child: markdown) : markdown;
  }
}

class _TappableCheckbox extends StatelessWidget {
  const _TappableCheckbox({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      // A plain GestureDetector: ink effects need a Material ancestor, which
      // text spans don't provide
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Icon(
          checked
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 22,
          color: checked ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _WithTextScalar extends InheritedWidget {
  const _WithTextScalar({required super.child});

  @override
  bool updateShouldNotify(covariant _WithTextScalar oldWidget) {
    return false;
  }
}
