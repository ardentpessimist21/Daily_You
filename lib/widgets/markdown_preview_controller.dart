// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:math';

import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/utils/markdown_preview_styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A [TextEditingController] that styles Markdown syntax in place
class MarkdownPreviewController extends TextEditingController {
  MarkdownPreviewController({super.text});

  /// How long typing has to pause before the spell checker runs again.
  @visibleForTesting
  static Duration spellCheckPause = const Duration(milliseconds: 400);

  late final _PreviewSpellCheckService _spellCheck =
      _PreviewSpellCheckService(this);
  bool _spellCheckCreated = false;
  bool _disposed = false;

  SpellCheckService get spellCheckService {
    _spellCheckCreated = true;
    return _spellCheck;
  }

  String _scannedText = '';
  MarkdownScan _scan = MarkdownScan.empty;
  bool _hasChecked = false;
  String _checkedText = '';
  List<SuggestionSpan> _checkedMisspellings = const [];
  String? _movedText;
  List<SuggestionSpan> _movedMisspellings = const [];

  MarkdownScan get scan {
    if (_scannedText != text) {
      _scannedText = text;
      _scan = scanMarkdown(text);
    }
    return _scan;
  }

  /// The last spell check result, ranges moved past any edits made since
  List<SuggestionSpan> get misspellings {
    final current = text;
    if (identical(_checkedText, current) || _checkedText == current) {
      return _checkedMisspellings;
    }
    if (_movedText != null &&
        (identical(_movedText, current) || _movedText == current)) {
      return _movedMisspellings;
    }

    final previous = _checkedText;
    final (prefix, suffix) = _commonEnds(previous, current);
    final editEnd = previous.length - suffix;
    final shift = current.length - previous.length;
    final moved = <SuggestionSpan>[];
    for (final span in _checkedMisspellings) {
      if (span.range.end <= prefix) {
        moved.add(span);
      } else if (span.range.start >= editEnd) {
        moved.add(SuggestionSpan(
          TextRange(
              start: span.range.start + shift, end: span.range.end + shift),
          span.suggestions,
        ));
      }
    }
    _movedText = current;
    return _movedMisspellings = moved
        .where((span) => span.range.end <= current.length)
        .toList(growable: false);
  }

  List<ContextMenuButtonItem> spellCheckMenuItems(EditableTextState editor) {
    final offset = editor.textEditingValue.selection.baseOffset;
    final span = misspellings
        .where((span) => offset >= span.range.start && offset <= span.range.end)
        .firstOrNull;
    if (span == null) return const [];

    return [
      for (final suggestion in span.suggestions.take(3))
        ContextMenuButtonItem(
          label: suggestion,
          onPressed: () {
            editor.hideToolbar();
            editor.userUpdateTextEditingValue(
              TextEditingValue(
                text: text.replaceRange(
                    span.range.start, span.range.end, suggestion),
                selection: TextSelection.collapsed(
                    offset: span.range.start + suggestion.length),
              ),
              SelectionChangedCause.toolbar,
            );
          },
        ),
    ];
  }

  void receiveSpellCheck(String checkedText, List<SuggestionSpan> found) {
    _hasChecked = true;
    _checkedText = checkedText;
    _checkedMisspellings = found;
    _movedText = null;
    _movedMisspellings = const [];
  }

  /// The part of [current] the spell checker needs to look at again: the
  /// whole lines touched by the edits made since [previous] was checked.
  @visibleForTesting
  static (int, int) linesToRecheck(String previous, String current) {
    if (previous == current) return (0, 0);
    final (prefix, suffix) = _commonEnds(previous, current);
    final editEnd = current.length - suffix;
    final start = prefix == 0 ? 0 : current.lastIndexOf('\n', prefix - 1) + 1;
    final next = current.indexOf('\n', editEnd);
    return (start, next == -1 ? current.length : next);
  }

  /// Takes the spell check of [start]..[end] of [checkedText] and keeps the
  /// results already known for the rest. Returns whether the underlines
  /// changed.
  bool mergeSpellCheck(
      String checkedText, int start, int end, List<SuggestionSpan> found) {
    if (text != checkedText) return false;
    final before = misspellings;
    final merged = [
      for (final span in before)
        if (span.range.end <= start || span.range.start >= end) span,
      for (final span in found)
        SuggestionSpan(
          TextRange(start: span.range.start + start, end: span.range.end + start),
          span.suggestions,
        ),
    ]..sort((a, b) => a.range.start.compareTo(b.range.start));
    final changed = !listEquals(merged, before);
    receiveSpellCheck(checkedText, merged);
    return changed;
  }

  @override
  void dispose() {
    _disposed = true;
    if (_spellCheckCreated) _spellCheck.cancel();
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) =>
      buildMarkdownPreviewSpan(
        text: text,
        spans: scan.spans,
        baseStyle: style ?? const TextStyle(),
        styles: MarkdownPreviewStyles.fromTheme(context),
        composing: withComposing ? value.composing : TextRange.empty,
        misspellings: nearbyMisspellings(),
      );

  /// Size of the steps the underline window moves in, in characters.
  static const int _underlineStep = 1500;

  /// Spell check underlines to draw. Each one splits the text into more
  /// pieces, which makes every keystroke on a long entry slower to lay out,
  /// so long entries only show the ones within a few screens of the cursor.
  /// Underlines don't move any text, so leaving the far ones out doesn't
  /// shift anything. The window moves in steps, so ordinary cursor moves
  /// don't restyle the entry.
  @visibleForTesting
  List<TextRange> nearbyMisspellings() {
    final all = misspellings;
    if (text.length <= _underlineStep * 5) {
      return [for (final span in all) span.range];
    }
    final at = selection.isValid ? selection.extentOffset : 0;
    final step = at ~/ _underlineStep;
    final from = (step - 2) * _underlineStep;
    final to = (step + 3) * _underlineStep;
    return [
      for (final span in all)
        if (span.range.end > from && span.range.start < to) span.range,
    ];
  }
}

/// Lengths of the start and end that [previous] and [current] share
(int, int) _commonEnds(String previous, String current) {
  final shortest = min(previous.length, current.length);
  var prefix = 0;
  while (prefix < shortest &&
      previous.codeUnitAt(prefix) == current.codeUnitAt(prefix)) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < shortest - prefix &&
      previous.codeUnitAt(previous.length - 1 - suffix) ==
          current.codeUnitAt(current.length - 1 - suffix)) {
    suffix++;
  }
  return (prefix, suffix);
}

/// Takes the spell check results and does not pass them along to the framework, this would ruin styling.
///
/// Flutter asks for a spell check of the whole entry after every keystroke,
/// then restyles and lays out the whole entry again when it answers. On long
/// entries that doubles the work of each keystroke. Instead, this waits for
/// a pause in typing, checks only the lines that changed, and only asks for
/// the restyle when the underlines actually changed.
class _PreviewSpellCheckService implements SpellCheckService {
  _PreviewSpellCheckService(this.controller);

  final MarkdownPreviewController controller;
  final DefaultSpellCheckService _platform = DefaultSpellCheckService();
  Timer? _timer;
  Completer<bool>? _waiting;

  void cancel() {
    _timer?.cancel();
    _timer = null;
    final waiting = _waiting;
    _waiting = null;
    if (waiting != null && !waiting.isCompleted) waiting.complete(false);
  }

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
          Locale locale, String text) =>
      _check(locale, text, retry: true);

  Future<List<SuggestionSpan>?> _check(Locale locale, String text,
      {required bool retry}) async {
    // A newer request replaces this one, so only the last one after a pause
    // in typing goes ahead.
    cancel();
    final waiting = _waiting = Completer<bool>();
    _timer = Timer(MarkdownPreviewController.spellCheckPause, () {
      if (!waiting.isCompleted) waiting.complete(true);
    });
    if (!await waiting.future) return null;
    if (identical(_waiting, waiting)) {
      _waiting = null;
      _timer = null;
    }
    if (controller._disposed || controller.text != text) return null;

    final (start, end) = controller._hasChecked
        ? MarkdownPreviewController.linesToRecheck(controller._checkedText, text)
        : (0, text.length);
    final part = text.substring(start, end);
    final found = part.trim().isEmpty
        ? const <SuggestionSpan>[]
        : await _platform.fetchSpellCheckSuggestions(locale, part);
    if (controller._disposed) return null;
    if (found == null) {
      // The phone was still busy with an earlier check: try once more, so
      // the lines just typed still get checked if typing has stopped.
      return retry && controller.text == text
          ? _check(locale, text, retry: false)
          : null;
    }

    // Returning null tells Flutter there is nothing new to draw.
    return controller.mergeSpellCheck(text, start, end, found) ? const [] : null;
  }
}
