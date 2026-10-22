// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/editor_buttons.dart';
import 'package:daily_you/fork/formatted_copy.dart';
import 'package:daily_you/fork/selection_menu.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('B1: hold-B removed', () {
    test('Bold has no long-press any more', () {
      expect(EditorButtons.holdLabel(l10n, EditorButton.bold), isNull);
    });

    test('the other long-presses stay', () {
      for (final button in [
        EditorButton.timestamp,
        EditorButton.list,
        EditorButton.checklist,
        EditorButton.heading,
        EditorButton.highlight,
        EditorButton.quote,
        EditorButton.link,
      ]) {
        expect(EditorButtons.holdLabel(l10n, button), isNotNull,
            reason: button.name);
      }
    });

    test('long-pressing Bold inserts nothing', () async {
      final controller = TextEditingController(text: 'word')
        ..selection = const TextSelection(baseOffset: 0, extentOffset: 4);
      // hold() only touches the context for buttons that open dialogs
      await EditorButtons.hold(EditorButton.bold, _FakeContext(), controller);
      expect(controller.text, 'word');
    });
  });

  group('B2: selection popup stays on screen', () {
    const media = MediaQueryData(
      size: Size(400, 800),
      padding: EdgeInsets.only(top: 24),
      viewInsets: EdgeInsets.only(bottom: 300),
    );
    // Visible area: 24 + 56 (app bar) = 80 down to 800 - 300 - 72 = 428

    test('Select all on a long entry: popup moves to the top', () {
      final moved = SelectionMenu.keepOnScreen(
        media,
        const TextSelectionToolbarAnchors(
          primaryAnchor: Offset(200, -2400),
          secondaryAnchor: Offset(200, 470),
        ),
      );
      expect(moved.primaryAnchor.dy, 80 + SelectionMenu.popupRoom);
      expect(moved.secondaryAnchor!.dy, 428 - SelectionMenu.popupRoom);
    });

    test('a selection in plain view is left alone', () {
      const anchors = TextSelectionToolbarAnchors(
        primaryAnchor: Offset(120, 220),
        secondaryAnchor: Offset(160, 260),
      );
      final moved = SelectionMenu.keepOnScreen(media, anchors);
      expect(moved.primaryAnchor, anchors.primaryAnchor);
      expect(moved.secondaryAnchor, anchors.secondaryAnchor);
    });
  });

  group('B3: copying keeps line breaks and formatting', () {
    const entry = 'Shift today\n'
        'Very **tired** but _okay_.\n'
        '\n'
        '- Care plans\n'
        '- [x] Meds round\n'
        '1. ==Handover==\n'
        '> A quote\n'
        '## Evening\n'
        '_Si [batang](https://facebook.com/x) nagtawag._';

    test('what each line shows', () {
      expect(FormattedCopy.visibleLine('Very **tired** but _okay_.'),
          'Very tired but okay.');
      expect(FormattedCopy.visibleLine('- [x] Meds round'), 'Meds round');
      expect(FormattedCopy.visibleLine('1. ==Handover=='), 'Handover');
      expect(FormattedCopy.visibleLine('## Evening'), 'Evening');
      expect(
          FormattedCopy.visibleLine(
              '_Si [batang](https://facebook.com/x) nagtawag._'),
          'Si batang nagtawag.');
      expect(FormattedCopy.visibleLine('---'), '');
      expect(FormattedCopy.visibleLine('snake_case_name'), 'snake_case_name');
    });

    test('a whole selection comes back exactly as written', () {
      // Flutter's copy runs the blocks together with nothing between
      const selected = 'Shift todayVery tired but okay.Care plansMeds round'
          'HandoverA quoteEveningSi batang nagtawag.';
      expect(FormattedCopy.forSelection(entry, selected), entry);
    });

    test('whole lines keep their Markdown, part lines give the words', () {
      const selected = 'but okay.Care plansMeds rou';
      expect(FormattedCopy.forSelection(entry, selected),
          'but okay.\n\n- Care plans\nMeds rou');
    });

    test('a single whole line keeps its formatting', () {
      expect(FormattedCopy.forSelection(entry, 'Very tired but okay.'),
          'Very **tired** but _okay_.');
    });

    test('spaces and line breaks in the selection do not matter', () {
      expect(FormattedCopy.forSelection(entry, 'Care plans\nMeds round'),
          '- Care plans\n- [x] Meds round');
    });

    test('text from outside the entry falls back to a plain copy', () {
      expect(
          FormattedCopy.forSelection(entry, 'Thu, Oct 22 Shift today'), isNull);
      expect(FormattedCopy.forSelection(entry, '   '), isNull);
    });
  });

  group('B6: custom toolbar buttons', () {
    useTemporaryConfig();

    test('none to start with', () {
      expect(EditorButtons.customButtons(), isEmpty);
      expect(EditorButtons.toolbarOrder().every((item) => item.custom == null),
          isTrue);
    });

    test('a new button is saved and joins the end of the toolbar', () async {
      final button = EditorButtons.newCustomButton(
          name: 'Gratitude', symbol: '🙏', text: '## Grateful for\n- ');
      await EditorButtons.saveCustomButton(button);
      expect(EditorButtons.customButtons(), [button]);
      expect(EditorButtons.toolbarOrder().last, ToolbarItem.custom(button));
    });

    test('order and hiding are remembered', () async {
      final button = EditorButtons.newCustomButton(
          name: 'Divider', symbol: '—', text: '\n---\n');
      await EditorButtons.saveCustomButton(button);
      final order = EditorButtons.toolbarOrder();
      final item = order.removeLast();
      order.insert(0, item);
      await EditorButtons.saveToolbar(order, {item.token});

      expect(EditorButtons.toolbarOrder().first, ToolbarItem.custom(button));
      expect(EditorButtons.toolbarHidden(), {button.token});
    });

    test('editing keeps its place; deleting removes it everywhere', () async {
      final button = EditorButtons.newCustomButton(
          name: 'Mood', symbol: 'M', text: 'Mood: ');
      await EditorButtons.saveCustomButton(button);
      final order = EditorButtons.toolbarOrder();
      order.insert(1, order.removeLast());
      await EditorButtons.saveToolbar(order, {button.token});

      await EditorButtons.saveCustomButton(button.copyWith(text: 'Feeling: '));
      expect(EditorButtons.customButtons().single.text, 'Feeling: ');
      expect(EditorButtons.toolbarOrder()[1].custom?.id, button.id);

      await EditorButtons.deleteCustomButton(button);
      expect(EditorButtons.customButtons(), isEmpty);
      expect(EditorButtons.toolbarHidden(), isEmpty);
      expect(ConfigProvider.instance.get(Settings.editorToolbarOrder),
          isNot(contains(button.token)));
    });

    test('ids are never reused', () async {
      final first =
          EditorButtons.newCustomButton(name: 'A', symbol: 'A', text: 'a');
      await EditorButtons.saveCustomButton(first);
      final second =
          EditorButtons.newCustomButton(name: 'B', symbol: 'B', text: 'b');
      expect(second.id, isNot(first.id));
    });

    test('a tap inserts the text at the cursor, replacing a selection', () {
      const button = CustomEditorButton(
          id: 'x', name: 'Sig', symbol: 'S', text: '— Hanah');
      final controller = TextEditingController(text: 'Hello world')
        ..selection = const TextSelection(baseOffset: 6, extentOffset: 11);
      EditorButtons.insertCustom(controller, button);
      expect(controller.text, 'Hello — Hanah');
      expect(controller.selection.baseOffset, 'Hello — Hanah'.length);
    });

    test('damaged saved data is ignored, not a crash', () async {
      await ConfigProvider.instance
          .set(Settings.editorCustomButtons, 'not json');
      expect(EditorButtons.customButtons(), isEmpty);
      await ConfigProvider.instance.set(Settings.editorCustomButtons,
          '[{"id":"ok","name":"Ok","symbol":"O","text":"o"},{"bad":1}]');
      expect(EditorButtons.customButtons().single.id, 'ok');
    });

    test('custom buttons are saved with the other settings', () {
      expect(Settings.all, contains(Settings.editorCustomButtons));
    });
  });

  group('B5: 📍 leaves the formatting toolbar', () {
    useTemporaryConfig();

    test('not on the toolbar or offered for the popup', () {
      expect(EditorButtons.defaultToolbar, isNot(contains(EditorButton.place)));
      expect(
          EditorButtons.toolbarOrder()
              .any((item) => item.builtIn == EditorButton.place),
          isFalse);
    });

    test('an old popup choice with 📍 drops it', () async {
      await ConfigProvider.instance
          .set(Settings.editorPopupItems, 'bold,place,link');
      expect(
          EditorButtons.popupItems(), [EditorButton.bold, EditorButton.link]);
    });
  });

  group('B7: version label', () {
    test('pubspec says 3.7.0', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(RegExp(r'^version: 3\.7\.0\+', multiLine: true).hasMatch(pubspec),
          isTrue);
    });
  });

  group('B8: timestamps include the year', () {
    test('date part has the year', () {
      expect(EditorButtons.dateWithYear(DateTime(2026, 10, 18), 'en_US'),
          'Oct 18, 2026');
      expect(EditorButtons.dateWithYear(DateTime(2022, 3, 5), 'en_US'),
          'Mar 5, 2022');
    });
  });
}

class _FakeContext extends Fake implements BuildContext {}
