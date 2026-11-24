// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/markdown_fences.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('MarkdownFences.labelBare', () {
    test('labels a bare opening fence, leaves the closing one', () {
      expect(MarkdownFences.labelBare('a\n```\ncode\n```\nb'),
          'a\n```plaintext\ncode\n```\nb');
    });

    test('keeps a language that is already there', () {
      const text = '```dart\nvar x = 1;\n```';
      expect(MarkdownFences.labelBare(text), same(text));
    });

    test('handles several blocks and tildes', () {
      expect(MarkdownFences.labelBare('```\none\n```\n\n~~~\ntwo\n~~~'),
          '```plaintext\none\n```\n\n~~~plaintext\ntwo\n~~~');
    });

    test('a shorter fence inside a longer block is just text', () {
      expect(MarkdownFences.labelBare('````\n```\n````'),
          '````plaintext\n```\n````');
    });

    test('text with no fences comes back untouched', () {
      const text = 'Just some writing with `inline` code.';
      expect(MarkdownFences.labelBare(text), same(text));
    });
  });

  group('ScaledMarkdown', () {
    Widget app(Widget child) =>
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

    const entry = 'Before\n\n```\nif (x) {\n  y();\n}\n```\n\nAfter';

    testWidgets('a bare code block draws without "get language error"',
        (tester) async {
      final printed = <String?>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message);
      try {
        await tester.pumpWidget(app(const ScaledMarkdown(data: entry)));
      } finally {
        debugPrint = original;
      }
      expect(find.textContaining('y();', findRichText: true), findsOneWidget);
      expect(
          printed.where((m) => m?.contains('get language') ?? false), isEmpty);
    });

    testWidgets('the same text is not rebuilt when the page rebuilds',
        (tester) async {
      final rebuild = ValueNotifier(0);
      addTearDown(rebuild.dispose);
      await tester.pumpWidget(app(ValueListenableBuilder<int>(
        valueListenable: rebuild,
        builder: (_, v, __) => Column(children: [
          Text('page $v'),
          ScaledMarkdown(data: entry),
        ]),
      )));
      final before = tester.widget(find.byType(SelectionArea));

      rebuild.value++;
      await tester.pump();
      expect(find.text('page 1'), findsOneWidget);
      expect(
          identical(tester.widget(find.byType(SelectionArea)), before), isTrue);
    });

    testWidgets('new text is drawn', (tester) async {
      await tester.pumpWidget(app(const ScaledMarkdown(data: 'first')));
      await tester.pumpWidget(app(const ScaledMarkdown(data: 'second')));
      expect(find.textContaining('second', findRichText: true), findsOneWidget);
    });
  });
}
