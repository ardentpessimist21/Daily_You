// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:material_ui/material_ui.dart';

/// Entry formatting in the app's own colours (3.7.0.41). The Markdown
/// package's dark style uses fixed greys and white: quotes look like body
/// text, heading underlines are bright, inline code looks like a selection
/// and code blocks are a light grey slab. These follow the theme instead,
/// and its accent (including Use System Accent Color).
class MarkdownTheme {
  MarkdownTheme._();

  /// The muted line used for `---` and heading underlines.
  static Color rule(ThemeData theme) => theme.colorScheme.outlineVariant;

  static Color quoteTint(ThemeData theme) => theme.colorScheme.primary
      .withValues(alpha: theme.brightness == Brightness.dark ? 0.08 : 0.07);

  /// Config overrides, added to the base dark/light config.
  static List<WidgetConfig> configs(ThemeData theme, MarkdownConfig base) {
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return [
      // Inline code: a soft accent tint, not a grey selection-like box
      CodeConfig(
        style: TextStyle(
          backgroundColor: scheme.primary.withValues(alpha: dark ? 0.16 : 0.12),
          color: dark ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
      ),
      // Code blocks sit on a surface that matches the entry card
      base.pre.copy(
        decoration: BoxDecoration(
          color: dark ? scheme.surfaceContainerLowest : scheme.surfaceBright,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: rule(theme)),
        ),
      ),
    ];
  }

  /// Node generators for headings (muted underline) and quotes (accent bar,
  /// tint, muted text).
  static List<SpanNodeGeneratorWithTag> generators(ThemeData theme) {
    final scheme = theme.colorScheme;
    SpanNodeGeneratorWithTag heading(
            MarkdownTag tag, HeadingConfig Function(MarkdownConfig) pick) =>
        SpanNodeGeneratorWithTag(
          tag: tag.name,
          generator: (m.Element e, MarkdownConfig config, WidgetVisitor v) =>
              _ThemedHeadingNode(pick(config), v, rule(theme)),
        );
    return [
      heading(MarkdownTag.h1, (c) => c.h1),
      heading(MarkdownTag.h2, (c) => c.h2),
      heading(MarkdownTag.h3, (c) => c.h3),
      SpanNodeGeneratorWithTag(
        tag: MarkdownTag.blockquote.name,
        generator: (m.Element e, MarkdownConfig config, WidgetVisitor v) =>
            _ThemedQuoteNode(
          v,
          bar: scheme.primary,
          tint: quoteTint(theme),
          text: scheme.onSurfaceVariant,
        ),
      ),
    ];
  }
}

/// A heading whose underline is the muted rule, not the heading's colour.
class _ThemedHeadingNode extends ElementNode {
  _ThemedHeadingNode(this.config, this.visitor, this.ruleColor);

  final HeadingConfig config;
  final WidgetVisitor visitor;
  final Color ruleColor;

  @override
  InlineSpan build() {
    final divider = config.divider;
    if (divider == null) return childrenSpan;
    return WidgetSpan(
      child: Padding(
        padding: config.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProxyRichText(childrenSpan,
                richTextBuilder: visitor.richTextBuilder),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: divider.space),
              child: Divider(height: 1, thickness: 1, color: ruleColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  TextStyle get style => config.style.merge(parentStyle);
}

/// A quote with an accent bar, a soft tint behind it and muted text.
class _ThemedQuoteNode extends ElementNode {
  _ThemedQuoteNode(this.visitor,
      {required this.bar, required this.tint, required this.text});

  final WidgetVisitor visitor;
  final Color bar;
  final Color tint;
  final Color text;

  @override
  InlineSpan build() {
    return WidgetSpan(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(10)),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: tint,
              border: Border(left: BorderSide(color: bar, width: 3)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: ProxyRichText(childrenSpan,
                richTextBuilder: visitor.richTextBuilder),
          ),
        ),
      ),
    );
  }

  // The muted colour wins over the paragraph's, so quotes read as set apart
  @override
  TextStyle? get style =>
      (parentStyle ?? const TextStyle()).merge(TextStyle(color: text));
}
