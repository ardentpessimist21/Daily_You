// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Copying from the entry view.
///
/// The reading view is made of separate blocks (one per paragraph, list
/// item or heading), and Flutter joins them with nothing in between when
/// copying, so line breaks, paragraph gaps and list items ran together and
/// the formatting was lost. Instead, the selected words are found in the
/// entry's own text, and the matching lines are copied as written: line
/// breaks, lists, checklists, bold, italic, highlight and links all kept.
class FormattedCopy {
  static final RegExp _blockPrefix = RegExp(
      r'^\s{0,3}(?:#{1,6}\s+|>\s?|[-*+]\s+\[[ xX]\]\s+|[-*+]\s+|\d{1,9}[.)]\s+)');
  static final RegExp _rule = RegExp(r'^\s{0,3}([-*_])(\s*\1){2,}\s*$');
  static final RegExp _image = RegExp(r'!\[([^\]]*)\]\([^)]*\)');
  static final RegExp _link = RegExp(r'\[([^\]]*)\]\([^)]*\)');
  static final RegExp _autoLink = RegExp(r'<((?:https?|mailto|geo):[^>\s]+)>');
  static final RegExp _escape = RegExp(r'\\([\\`*_{}\[\]()#+\-.!>~=|])');
  static final List<RegExp> _wrappers = [
    RegExp(r'\*\*(.+?)\*\*'),
    RegExp(r'__(.+?)__'),
    RegExp(r'~~(.+?)~~'),
    RegExp(r'==(.+?)=='),
    RegExp(r'`(.+?)`'),
    RegExp(r'(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])'),
    RegExp(r'(?<![\w_])_(?!\s)(.+?)(?<!\s)_(?![\w_])'),
  ];

  /// The words a line shows when read: no Markdown symbols, link names
  /// instead of links, and nothing for list bullets or checkboxes.
  static String visibleLine(String line) {
    if (_rule.hasMatch(line)) return '';
    var text = line;
    // A quote can hold a list item or heading, so peel a few layers
    for (var i = 0; i < 3; i++) {
      final stripped = text.replaceFirst(_blockPrefix, '');
      if (stripped == text) break;
      text = stripped;
    }
    text = text
        .replaceAllMapped(_image, (m) => m[1]!)
        .replaceAllMapped(_link, (m) => m[1]!)
        .replaceAllMapped(_autoLink, (m) => m[1]!);
    // Nested formatting (bold inside italics…) needs more than one pass
    for (var pass = 0; pass < 3; pass++) {
      final before = text;
      for (final wrapper in _wrappers) {
        text = text.replaceAllMapped(wrapper, (m) => m[1]!);
      }
      if (text == before) break;
    }
    return text.replaceAllMapped(_escape, (m) => m[1]!);
  }

  /// What to put on the clipboard when [selected] (the words picked in the
  /// reading view) is copied from an entry whose text is [body]. Lines
  /// fully inside the selection keep their Markdown; a line only partly
  /// selected gives just the picked words. Null when the selection can't be
  /// found in the entry, e.g. it also covers the date above the text.
  static String? forSelection(String body, String selected) {
    final wanted = selected.replaceAll(RegExp(r'\s+'), '');
    if (wanted.isEmpty) return null;

    final lines = body.split('\n');
    final visible = [for (final line in lines) visibleLine(line)];
    // Every shown character, without spaces, and where it came from
    final joined = StringBuffer();
    final fromLine = <int>[];
    final fromColumn = <int>[];
    for (var i = 0; i < visible.length; i++) {
      final line = visible[i];
      for (var c = 0; c < line.length; c++) {
        if (line[c].trim().isEmpty) continue;
        joined.write(line[c]);
        fromLine.add(i);
        fromColumn.add(c);
      }
    }
    final at = joined.toString().indexOf(wanted);
    if (at == -1) return null;

    final firstLine = fromLine[at];
    final firstColumn = fromColumn[at];
    final lastLine = fromLine[at + wanted.length - 1];
    final endColumn = fromColumn[at + wanted.length - 1] + 1;

    final out = <String>[];
    for (var i = firstLine; i <= lastLine; i++) {
      final shown = visible[i];
      final start = i == firstLine ? firstColumn : 0;
      final end = i == lastLine ? endColumn : shown.length;
      final whole = shown.substring(0, start).trim().isEmpty &&
          shown.substring(end).trim().isEmpty;
      out.add(whole ? lines[i] : shown.substring(start, end));
    }
    return out.join('\n');
  }

  /// The selection popup for the reading view, with Copy swapped for one
  /// that keeps the entry's line breaks and formatting. [selectedText] is
  /// the current selection's plain text and [body] the entry's text.
  static Widget contextMenu(
    BuildContext context,
    SelectableRegionState region, {
    required String? Function() selectedText,
    required String? Function() body,
  }) {
    final items = [
      for (final item in region.contextMenuButtonItems)
        if (item.type == ContextMenuButtonType.copy)
          item.copyWith(onPressed: () async {
            final selected = selectedText();
            final source = body();
            final formatted = selected == null || source == null
                ? null
                : forSelection(source, selected);
            if (formatted == null) {
              // Not found in the entry: Flutter's own copy
              item.onPressed?.call();
              return;
            }
            region.clearSelection();
            region.hideToolbar();
            await Clipboard.setData(ClipboardData(text: formatted));
          })
        else
          item,
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: region.contextMenuAnchors,
      buttonItems: items,
    );
  }
}
