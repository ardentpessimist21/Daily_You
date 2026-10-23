// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/utils/markdown_preview_styles.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/config_provider_harness.dart';

const _styles = MarkdownPreviewStyles(
  marker: Color(0xff888888),
  link: Color(0xff0000ff),
  quote: Color(0xff666666),
  codeBackground: Color(0xffeeeeee),
  misspelling: Color(0xffff0000),
  highlightBackground: Color(0xffffff00),
);

/// The styling as it was built before Update L, to check the faster sweep
/// gives exactly the same result.
TextSpan _referenceSpan({
  required String text,
  required List<MarkdownSpan> spans,
  required TextStyle baseStyle,
  TextRange composing = TextRange.empty,
  List<TextRange> misspellings = const [],
}) {
  if (text.isEmpty) return TextSpan(style: baseStyle);
  TextStyle decorate(TextStyle style, TextDecoration decoration) {
    final existing = style.decoration;
    return style.copyWith(
      decoration: existing == null || existing == TextDecoration.none
          ? decoration
          : TextDecoration.combine([existing, decoration]),
    );
  }

  bool covers(List<TextRange> ranges, int start, int end) =>
      ranges.any((range) => start >= range.start && end <= range.end);

  final underlined = <TextRange>[
    if (composing.isValid && composing.end <= text.length) composing,
  ];
  final marked = [
    for (final range in misspellings)
      if (range.isValid && range.end <= text.length) range,
  ];
  final children = <TextSpan>[];
  final active = <MarkdownSpan>[];
  var cursor = 0;
  var next = 0;
  while (cursor < text.length) {
    while (next < spans.length && spans[next].start <= cursor) {
      active.add(spans[next++]);
    }
    var end = next < spans.length ? spans[next].start : text.length;
    for (final span in active) {
      end = min(end, span.end);
    }
    for (final range in underlined.followedBy(marked)) {
      if (range.start > cursor) end = min(end, range.start);
      if (range.end > cursor) end = min(end, range.end);
    }
    var style = baseStyle;
    for (final span in active) {
      style = _styles.apply(style, span);
    }
    if (covers(underlined, cursor, end)) {
      style = decorate(style, TextDecoration.underline);
    }
    if (covers(marked, cursor, end)) {
      style = decorate(style, TextDecoration.underline).copyWith(
        decorationColor: _styles.misspelling,
        decorationStyle: TextDecorationStyle.wavy,
      );
    }
    children.add(TextSpan(text: text.substring(cursor, end), style: style));
    cursor = end;
    active.removeWhere((span) => span.end <= cursor);
  }
  return TextSpan(style: baseStyle, children: children);
}

String _longEntry(int paragraphs) {
  final b = StringBuffer('# Big day\n\n');
  for (var i = 0; i < paragraphs; i++) {
    b.writeln('${1 + i % 12}:0${i % 10} AM');
    b.writeln('On shift I helped residents with **breakfast** and *notes*, '
        'then studied before a walk.');
    if (i % 5 == 0) b.writeln('- [ ] task $i\n> a quote $i');
    b.writeln();
  }
  return b.toString();
}

void main() {
  group('Update L: spell check only looks at changed lines', () {
    test('the edited line, whole', () {
      const before = 'first line\nsecond line\nthird line';
      const after = 'first line\nsecond liine\nthird line';
      final (start, end) =
          MarkdownPreviewController.linesToRecheck(before, after);
      expect(after.substring(start, end), 'second liine');
    });

    test('every line an edit touches, including a new one', () {
      const before = 'one\ntwo\nthree';
      const after = 'one\ntwo and\nmore\nthree';
      final (start, end) =
          MarkdownPreviewController.linesToRecheck(before, after);
      expect(after.substring(start, end), 'two and\nmore');
    });

    test('edits on the first and last lines', () {
      expect(MarkdownPreviewController.linesToRecheck('abc\ndef', 'xabc\ndef'),
          (0, 4));
      expect(MarkdownPreviewController.linesToRecheck('abc\ndef', 'abc\ndefg'),
          (4, 8));
      expect(MarkdownPreviewController.linesToRecheck('same', 'same'), (0, 0));
    });

    test('a deleted line leaves just one line to check', () {
      const before = 'one\ntwo\nfour';
      const after = 'one\nfour';
      final (start, end) =
          MarkdownPreviewController.linesToRecheck(before, after);
      expect(after.substring(start, end), 'four');
    });

    test('new results replace the checked lines and keep the rest', () {
      final controller = MarkdownPreviewController(text: 'aa bb\ncc dd\nee ff');
      addTearDown(controller.dispose);
      controller.receiveSpellCheck('aa bb\ncc dd\nee ff', const [
        SuggestionSpan(TextRange(start: 0, end: 2), ['a']),
        SuggestionSpan(TextRange(start: 9, end: 11), ['d']),
        SuggestionSpan(TextRange(start: 15, end: 17), ['f']),
      ]);
      controller.text = 'aa bb\ncc ddd\nee ff';

      final (start, end) = MarkdownPreviewController.linesToRecheck(
          'aa bb\ncc dd\nee ff', controller.text);
      final changed = controller.mergeSpellCheck(controller.text, start, end,
          const [SuggestionSpan(TextRange(start: 0, end: 2), ['c'])]);

      expect(changed, isTrue);
      expect(controller.misspellings.map((s) => s.range), const [
        TextRange(start: 0, end: 2),
        TextRange(start: 6, end: 8),
        TextRange(start: 16, end: 18),
      ]);
    });

    test('nothing new to draw when the results are the same', () {
      final controller = MarkdownPreviewController(text: 'aa bb');
      addTearDown(controller.dispose);
      controller.receiveSpellCheck('aa bb', const [
        SuggestionSpan(TextRange(start: 3, end: 5), ['b']),
      ]);
      expect(
          controller.mergeSpellCheck('aa bb', 0, 5, const [
            SuggestionSpan(TextRange(start: 3, end: 5), ['b']),
          ]),
          isFalse);
    });

    test('results for text that has since changed are dropped', () {
      final controller = MarkdownPreviewController(text: 'aa bb!');
      addTearDown(controller.dispose);
      expect(
          controller.mergeSpellCheck('aa bb', 0, 5, const [
            SuggestionSpan(TextRange(start: 3, end: 5), ['b']),
          ]),
          isFalse);
      expect(controller.misspellings, isEmpty);
    });
  });

  group('Update L: underlines near the cursor on long entries', () {
    List<SuggestionSpan> everyWord(String text) => [
          for (final m in RegExp('residents').allMatches(text))
            SuggestionSpan(TextRange(start: m.start, end: m.end), const ['x'])
        ];

    test('short entries show every underline', () {
      final text = _longEntry(20);
      expect(text.length, lessThan(7500));
      final controller = MarkdownPreviewController(text: text);
      addTearDown(controller.dispose);
      controller.receiveSpellCheck(text, everyWord(text));
      expect(controller.nearbyMisspellings().length,
          controller.misspellings.length);
    });

    test('long entries show the ones within a few screens of the cursor', () {
      final text = _longEntry(400);
      final controller = MarkdownPreviewController(text: text);
      addTearDown(controller.dispose);
      controller.receiveSpellCheck(text, everyWord(text));
      controller.selection = TextSelection.collapsed(offset: text.length ~/ 2);

      final shown = controller.nearbyMisspellings();
      expect(shown, isNotEmpty);
      expect(shown.length, lessThan(controller.misspellings.length));
      final cursor = text.length ~/ 2;
      for (final range in shown) {
        expect((range.start - cursor).abs(), lessThan(6000));
      }
      // The underline spell suggestions still know about every word.
      expect(controller.misspellings.length, everyWord(text).length);
    });

    test('small cursor moves keep the same underlines', () {
      final text = _longEntry(400);
      final controller = MarkdownPreviewController(text: text);
      addTearDown(controller.dispose);
      controller.receiveSpellCheck(text, everyWord(text));
      controller.selection = const TextSelection.collapsed(offset: 3000);
      final before = controller.nearbyMisspellings();
      controller.selection = const TextSelection.collapsed(offset: 3100);
      expect(controller.nearbyMisspellings(), before);
    });
  });

  group('Update L: faster styling gives the same result', () {
    test('matches the old styling on varied entries', () {
      final random = Random(7);
      const base = TextStyle(fontSize: 16);
      for (var round = 0; round < 40; round++) {
        final text = _longEntry(5 + random.nextInt(20));
        final scan = scanMarkdown(text);
        // Non-overlapping misspellings in random order.
        final words = RegExp(r'[a-z]{4,}').allMatches(text).toList();
        final marked = [
          for (final m in words)
            if (random.nextInt(4) == 0) TextRange(start: m.start, end: m.end)
        ]..shuffle(random);
        final at = random.nextInt(text.length - 5);
        final composing = random.nextBool()
            ? TextRange(start: at, end: at + 4)
            : TextRange.empty;

        final fast = buildMarkdownPreviewSpan(
            text: text,
            spans: scan.spans,
            baseStyle: base,
            styles: _styles,
            composing: composing,
            misspellings: marked);
        final reference = _referenceSpan(
            text: text,
            spans: scan.spans,
            baseStyle: base,
            composing: composing,
            misspellings: marked);
        expect(fast, reference, reason: 'round $round');
      }
    });

    test('overlapping underlines still cover every letter', () {
      const text = 'abcdefghij klmnop';
      final span = buildMarkdownPreviewSpan(
        text: text,
        spans: scanMarkdown(text).spans,
        baseStyle: const TextStyle(),
        styles: _styles,
        misspellings: const [
          TextRange(start: 0, end: 6),
          TextRange(start: 4, end: 10),
        ],
      );
      final wavy = StringBuffer();
      for (final child in span.children!.cast<TextSpan>()) {
        if (child.style?.decorationStyle == TextDecorationStyle.wavy) {
          wavy.write(child.text);
        }
      }
      expect(wavy.toString(), 'abcdefghij');
      expect(span.toPlainText(), text);
    });
  });

  group('Update L: typing in a long entry', () {
    useTemporaryConfig();

    testWidgets(
        'restyles once per key, and spell checks the changed line after a pause',
        (tester) async {
      final sent = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.spellCheck, (call) async {
        final text = (call.arguments as List)[1] as String;
        sent.add(text);
        return [
          for (final m in RegExp('residents').allMatches(text))
            {'startIndex': m.start, 'endIndex': m.end, 'suggestions': ['x']}
        ];
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.spellCheck, null));

      final text = _longEntry(200);
      final controller = _CountingController(text: text);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...appLocalizationsDelegates,
        ],
        home: Scaffold(
          body: EntryTextEditor(
            text: text,
            focusNode: focus,
            textEditingController: controller,
            undoHistoryController: UndoHistoryController(),
          ),
        ),
      ));
      focus.requestFocus();
      await tester.pumpAndSettle();

      var offset = text.length ~/ 2;
      Future<void> type(String letters) async {
        for (final letter in letters.split('')) {
          final next = controller.text.replaceRange(offset, offset, letter);
          offset++;
          tester.testTextInput.updateEditingValue(TextEditingValue(
              text: next, selection: TextSelection.collapsed(offset: offset)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      controller.builds = 0;
      await type('hello');
      expect(controller.builds, 5, reason: 'one restyle per key');
      expect(sent, isEmpty, reason: 'no spell check while typing');

      await tester.pump(const Duration(seconds: 1));
      expect(sent, hasLength(1));
      expect(sent.single, controller.text, reason: 'first check: everything');
      expect(controller.misspellings, isNotEmpty);

      sent.clear();
      await type('ab');
      await tester.pump(const Duration(seconds: 1));
      expect(sent, hasLength(1));
      expect(sent.single.contains('\n'), isFalse,
          reason: 'later checks: just the edited line');
      expect(sent.single.length, lessThan(200));

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  });
}

class _CountingController extends MarkdownPreviewController {
  _CountingController({super.text});

  int builds = 0;

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    builds++;
    return super.buildTextSpan(
        context: context, style: style, withComposing: withComposing);
  }
}
