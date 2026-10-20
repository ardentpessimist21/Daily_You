// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/editor_buttons.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/utils/markdown_preview_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
// Rational isn't exported by the image package
// ignore: implementation_imports
import 'package:image/src/util/rational.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, String text) => Entry(
    id: id,
    text: text,
    timeCreate: DateTime(2026, 10, 15, 20),
    timeModified: DateTime(2026, 10, 15, 20));

TextEditingValue _value(String text, [int? start, int? end]) =>
    TextEditingValue(
      text: text,
      selection: TextSelection(
          baseOffset: start ?? text.length,
          extentOffset: end ?? start ?? text.length),
    );

void main() {
  group('EntryLinks', () {
    test('reads entry ids from entry: addresses only', () {
      expect(EntryLinks.idOf('entry:42'), 42);
      expect(EntryLinks.idOf('https://example.com'), isNull);
      expect(EntryLinks.idOf('entry:abc'), isNull);
    });

    test('titles come from the first heading or first words', () {
      expect(EntryLinks.titleOf(_entry(1, '# Night shift\n\nTired.')),
          'Night shift');
      expect(
          EntryLinks.titleOf(_entry(
              1, 'Felt **so tired** after the long meds round on ward three')),
          'Felt so tired after the long…');
      expect(EntryLinks.titleOf(_entry(1, '\n- [x] Care plans')), 'Care plans');
    });

    test('link text cannot break the link', () {
      expect(EntryLinks.markdown('A [weird] name', 'entry:3'),
          '[A weird name](entry:3)');
      expect(EntryLinks.markdownForEntry(_entry(7, '# Exam day')),
          '[Exam day](entry:7)');
      expect(EntryLinks.markdownForEntry(_entry(7, '# Exam day'), text: 'that'),
          '[that](entry:7)');
    });

    test('parses copied links', () {
      expect(EntryLinks.parseMarkdownLink('[Exam day](entry:7)'),
          ('Exam day', 'entry:7'));
      expect(EntryLinks.parseMarkdownLink('just words'), isNull);
    });
  });

  group('Pasting', () {
    final formatter = LinkPasteFormatter();

    test('a copied entry link wraps highlighted words', () {
      final old = _value('See this note', 4, 8);
      final pasted = _value('See [Exam day](entry:7) note', 23);
      final result = formatter.formatEditUpdate(old, pasted);
      expect(result.text, 'See [this](entry:7) note');
      expect(result.selection.baseOffset, 'See [this](entry:7)'.length);
    });

    test('a copied entry link pastes as it is with nothing highlighted', () {
      final old = _value('See ', 4);
      final pasted = _value('See [Exam day](entry:7)');
      expect(formatter.formatEditUpdate(old, pasted).text,
          'See [Exam day](entry:7)');
    });

    test('a web address wraps highlighted words', () {
      final old = _value('the rota', 4, 8);
      final pasted = _value('the https://example.com/rota');
      expect(formatter.formatEditUpdate(old, pasted).text,
          'the [rota](https://example.com/rota)');
    });

    test('a place shared from Google Maps becomes a pin link', () {
      final old = _value('Lunch at ', 9);
      final pasted = _value(
          'Lunch at Jollibee Taipei Main Station\nhttps://maps.app.goo.gl/x7Kq');
      expect(formatter.formatEditUpdate(old, pasted).text,
          'Lunch at [📍 Jollibee Taipei Main Station](https://maps.app.goo.gl/x7Kq)');
    });

    test('typing is never touched', () {
      final old = _value('Hello', 5);
      final typed = _value('Hello!');
      expect(identical(formatter.formatEditUpdate(old, typed), typed), isTrue);
    });
  });

  group('Places', () {
    test('typed places search the name in Maps', () {
      expect(Places.typed('Jollibee Taipei'),
          '[📍 Jollibee Taipei](geo:0,0?q=Jollibee+Taipei)');
    });

    test('coordinates are rounded and open the spot', () {
      expect(Places.coordinates(25.047812, 121.517034),
          '[📍 25.04781, 121.51703](geo:25.04781,121.51703)');
    });

    test('saved places without a map spot are plain text', () {
      expect(Places.saved(const SavedPlace('Uni')), '📍 Uni');
      expect(Places.saved(const SavedPlace('Work', 'geo:-27.47,153.02')),
          '[📍 Work](geo:-27.47,153.02)');
    });

    test('reads Google Maps shares and leaves other text alone', () {
      expect(Places.tidyShared('https://maps.app.goo.gl/abc'),
          '[📍 Google Maps](https://maps.app.goo.gl/abc)');
      expect(Places.tidyShared('Meeting notes for tomorrow'),
          'Meeting notes for tomorrow');
      expect(Places.fromShared('https://example.com/maps'), isNull);
    });

    test('Maps text shared from outside is tidied in a new entry', () {
      expect(
          AddEditEntryPage.mergeSharedText(
              '', 'Mum\'s place\nhttps://maps.app.goo.gl/q1'),
          "[📍 Mum's place](https://maps.app.goo.gl/q1)");
    });

    test('reads a photo location from EXIF', () {
      final exif = img.ExifData();
      final gps = exif['ifd0'].sub['gps'];
      gps[0x01] = img.IfdValueAscii('S');
      gps[0x02] = img.IfdValueRational.list([
        Rational(27, 1),
        Rational(28, 1),
        Rational(12, 1),
      ]);
      gps[0x03] = img.IfdValueAscii('E');
      gps[0x04] = img.IfdValueRational.list([
        Rational(153, 1),
        Rational(1, 1),
        Rational(30, 1),
      ]);
      final location = Places.locationFromExif(exif)!;
      expect(location.$1, closeTo(-27.47, 0.001));
      expect(location.$2, closeTo(153.025, 0.001));
    });

    test('photos without a location give nothing', () {
      expect(Places.locationFromExif(img.ExifData()), isNull);
      expect(Places.locationFromExif(null), isNull);
    });
  });

  group('Hiding formatting symbols', () {
    TextSpan build(String text, {int? cursor, bool hide = true}) {
      final selection = TextSelection.collapsed(offset: cursor ?? -1);
      return buildMarkdownPreviewSpan(
        text: text,
        spans: scanMarkdown(text).spans,
        baseStyle: const TextStyle(fontSize: 16),
        styles: const MarkdownPreviewStyles(
          marker: Colors.grey,
          link: Colors.blue,
          quote: Colors.grey,
          codeBackground: Colors.black12,
          misspelling: Colors.red,
          highlightBackground: Colors.yellow,
        ),
        hideMarkers: hide,
        revealed:
            cursor == null ? TextRange.empty : revealedLines(text, selection),
      );
    }

    String visible(TextSpan span) => [
          for (final child in span.children!.cast<TextSpan>())
            if ((child.style?.fontSize ?? 16) >= 1) child.text!
        ].join();

    test('symbols disappear but the text keeps every character', () {
      const text = '# Night shift\nFelt **so tired** but ==we got through==.';
      final span = build(text);
      expect(span.toPlainText(), text);
      expect(visible(span), 'Night shift\nFelt so tired but we got through.');
    });

    test('link code hides, leaving the words', () {
      final span = build('See [Exam day](entry:7) soon');
      expect(visible(span), 'See Exam day soon');
    });

    test('the line being edited shows its symbols', () {
      const text = 'Line **one**\nLine **two**';
      final span = build(text, cursor: text.length);
      expect(visible(span), 'Line one\nLine **two**');
    });

    test('list and checkbox marks stay', () {
      final span = build('- [ ] Meds round\n- Notes');
      expect(visible(span), '- [ ] Meds round\n- Notes');
    });

    test('nothing is hidden when the setting is off', () {
      const text = 'Felt **so tired**';
      expect(visible(build(text, hide: false)), text);
    });

    test('revealed lines cover the whole selection', () {
      const text = 'a\nbb\nccc';
      expect(
          revealedLines(
              text, const TextSelection(baseOffset: 3, extentOffset: 6)),
          const TextRange(start: 2, end: 8));
    });
  });

  group('Toolbar', () {
    useTemporaryConfig();

    test('📍 sits second by default', () {
      expect(EditorButtons.toolbarOrder().take(2),
          [EditorButton.timestamp, EditorButton.place]);
    });

    test('📍 joins a saved order after 🕒', () async {
      await ConfigProvider.instance
          .set(Settings.editorToolbarOrder, 'bold,timestamp,italic');
      final order = EditorButtons.toolbarOrder();
      expect(order.take(4), [
        EditorButton.bold,
        EditorButton.timestamp,
        EditorButton.place,
        EditorButton.italic,
      ]);
      expect(order.toSet().length, order.length);
    });
  });
}
