// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/editor_buttons.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/shared_entry_text.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/config_provider_harness.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('Toolbar: tap and long-press', () {
    useTemporaryConfig();

    test('Heading: tap is H1, long-press opens the H1–H6 menu', () {
      expect(
          EditorButtons.tapAction(EditorButton.heading), EditorAction.heading1);
      expect(EditorButtons.holdAction(EditorButton.heading),
          EditorAction.headingMenu);
    });

    test('tapping Heading inserts H1 straight away', () async {
      final controller = TextEditingController(text: 'Title')
        ..selection = const TextSelection.collapsed(offset: 0);
      await EditorButtons.run(
          EditorAction.heading1, _FakeContext(), controller);
      expect(controller.text, '# Title');
    });

    test('a button\'s tap and long-press can be changed and reset', () async {
      await EditorButtons.saveActions(
          EditorButton.bold, EditorAction.bold, EditorAction.italic);
      expect(EditorButtons.holdAction(EditorButton.bold), EditorAction.italic);
      expect(EditorButtons.holdLabel(l10n, EditorButton.bold), 'Italic');
      expect(EditorButtons.actionsChanged(EditorButton.bold), isTrue);

      await EditorButtons.saveActions(
          EditorButton.list, EditorAction.checkbox, EditorAction.none);
      expect(EditorButtons.tapAction(EditorButton.list), EditorAction.checkbox);
      expect(EditorButtons.holdLabel(l10n, EditorButton.list), isNull);

      await EditorButtons.resetAll();
      expect(EditorButtons.holdAction(EditorButton.bold), EditorAction.none);
      expect(
          EditorButtons.tapAction(EditorButton.list), EditorAction.bulletList);
    });

    test('saving the defaults stores nothing for that button', () async {
      await EditorButtons.saveActions(
          EditorButton.quote,
          EditorButtons.defaultTap(EditorButton.quote),
          EditorButtons.defaultHold(EditorButton.quote));
      expect(EditorButtons.actionsChanged(EditorButton.quote), isFalse);
    });

    test('every action has a name', () {
      for (final action in EditorAction.values) {
        expect(EditorButtons.actionLabel(l10n, action), isNotEmpty);
      }
    });
  });

  group('Toolbar: long-press 🔗 only pastes links', () {
    test('ordinary words are not a link', () {
      expect(EditorButtons.isCopiedLink('buy milk and eggs'), isFalse);
      expect(EditorButtons.isCopiedLink('hello'), isFalse);
      expect(EditorButtons.isCopiedLink(''), isFalse);
    });

    test('web, entry, Markdown and Maps links are', () {
      expect(EditorButtons.isCopiedLink('https://example.com/page'), isTrue);
      expect(EditorButtons.isCopiedLink('entry:42'), isTrue);
      expect(EditorButtons.isCopiedLink('[Trip](entry:42)'), isTrue);
      expect(
          EditorButtons.isCopiedLink(
              'Bacani\nhttps://maps.app.goo.gl/32N7abcdef'),
          isTrue);
    });
  });

  group('Toolbar: custom buttons with an icon', () {
    test('an icon button survives saving', () {
      const button = CustomEditorButton(
          id: 'a',
          name: 'Gratitude',
          symbol: 'favorite',
          text: '## Grateful',
          materialIcon: true);
      final back = CustomEditorButton.fromJson(button.toJson());
      expect(back, button);
      expect(back!.materialIcon, isTrue);
    });

    test('older emoji buttons load as emoji', () {
      final back = CustomEditorButton.fromJson(
          {'id': 'b', 'name': 'Pray', 'symbol': '🙏', 'text': 'x'});
      expect(back!.materialIcon, isFalse);
      expect(back.symbol, '🙏');
    });
  });

  group('Sharing an entry back into Daily You', () {
    setUpAll(() => initializeDateFormatting());
    // What Daily You shares for the entry in the screenshots
    const shared = 'Thu, Oct 22, 2026\n'
        'With text\n\nWith format\n\n**Bold**\n\n**Italic**\n\n'
        '📍 Bacani https://maps.app.goo.gl/32N7abcdef';

    test('is not treated as a single shared link', () {
      expect(EntryLinks.sharedWebLink(shared), isNull);
    });

    test('a page shared from a browser still is', () {
      final link = EntryLinks.sharedWebLink(
          'A good article\nhttps://example.com/article');
      expect(link, ('A good article', 'https://example.com/article'));
    });

    test('keeps its lines and formatting, drops the date, restores the place',
        () {
      final (text, places) = SharedEntryText.parse(shared);
      expect(text, 'With text\n\nWith format\n\n**Bold**\n\n**Italic**');
      expect(places.single.name, 'Bacani');
      expect(places.single.address, 'https://maps.app.goo.gl/32N7abcdef');
    });

    test('a mood emoji before the date is dropped too', () {
      final (text, _) = SharedEntryText.parse('😊 Thu, Oct 22, 2026\nHello');
      expect(text, 'Hello');
    });

    test('ordinary shared text keeps its first line', () {
      final (text, places) = SharedEntryText.parse('Shopping\n- milk');
      expect(text, 'Shopping\n- milk');
      expect(places, isEmpty);
    });

    test('a lone date is kept (nothing else to show)', () {
      expect(
          SharedEntryText.parse('Thu, Oct 22, 2026').$1, 'Thu, Oct 22, 2026');
    });

    test('the new entry gets the text and the place card', () {
      final merged = AddEditEntryPage.mergeSharedText('', shared);
      final (body, places) = EntryLocations.split(merged);
      expect(body, 'With text\n\nWith format\n\n**Bold**\n\n**Italic**');
      expect(places.single.name, 'Bacani');
    });
  });
}

class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
