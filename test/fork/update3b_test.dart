// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/editor_buttons.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });

  group('3B fixes', () {
    test('📍 links open as Google Maps web links', () {
      expect(Places.mapsUrlFor('geo:0,0?q=Jollibee+Taipei'),
          'https://www.google.com/maps/search/?api=1&query=Jollibee+Taipei');
      expect(Places.mapsUrlFor('geo:-27.47,153.02'),
          'https://www.google.com/maps/search/?api=1&query=-27.47%2C153.02');
      expect(Places.mapsUrlFor('https://maps.app.goo.gl/abc'), isNull);
      expect(Places.mapsUrlFor('entry:4'), isNull);
    });

    test('Android 13+ shows its own Copied message', () {
      expect(EntryLinks.showsOwnCopiedMessage(33), isTrue);
      expect(EntryLinks.showsOwnCopiedMessage(34), isTrue);
      expect(EntryLinks.showsOwnCopiedMessage(32), isFalse);
      expect(EntryLinks.showsOwnCopiedMessage(null), isFalse);
    });

    test('picker snippet shows the words around the match', () {
      const text = '# Night shift\nBusy ward tonight. Felt **so tired** '
          'after the handover but we got through it together in the end.';
      final snippet = matchSnippet(text, 'tired', around: 20)!;
      expect(snippet, contains('so tired'));
      expect(snippet, isNot(contains('**')));
      expect(snippet.startsWith('…'), isTrue);
      expect(snippet.endsWith('…'), isTrue);
      expect(matchSnippet(text, ''), isNull);
      expect(matchSnippet(text, 'pharmacology'), isNull);
    });

    test('short entries show the whole line', () {
      expect(matchSnippet('Exam day', 'exam'), 'Exam day');
    });
  });

  group('Toolbar', () {
    useTemporaryConfig();

    // Update B moved 📍 to the + menu and the bottom bar
    test('📍 is not a formatting button any more', () {
      expect(
          EditorButtons.toolbarOrder()
              .contains(const ToolbarItem.builtIn(EditorButton.place)),
          isFalse);
    });

    test('a saved order that still has 📍 drops it', () async {
      await ConfigProvider.instance
          .set(Settings.editorToolbarOrder, 'bold,timestamp,place,italic');
      final order = EditorButtons.toolbarOrder();
      expect(order.take(3), const [
        ToolbarItem.builtIn(EditorButton.bold),
        ToolbarItem.builtIn(EditorButton.timestamp),
        ToolbarItem.builtIn(EditorButton.italic),
      ]);
      expect(order.toSet().length, order.length);
    });
  });
}
