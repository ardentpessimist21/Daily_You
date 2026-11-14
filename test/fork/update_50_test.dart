// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/date_template_box.dart';
import 'package:daily_you/fork/jump_picker.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('date template box', () {
    late Map<String, String> parts;
    var submitted = false;

    Future<void> pumpBox(WidgetTester tester) async {
      parts = {};
      submitted = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DateTemplateBox(
            order: JumpDateFormat('M/d/y').order,
            separator: JumpDateFormat('M/d/y').separator,
            label: 'Enter date',
            onChanged: (value) => parts = value,
            onSubmitted: () => submitted = true,
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('mm / dd / yyyy stay shown while a part is filled',
        (tester) async {
      await pumpBox(tester);
      expect(find.text('mm'), findsOneWidget);
      expect(find.text('dd'), findsOneWidget);
      expect(find.text('yyyy'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('jump-date-M')), '11');
      await tester.pump();
      expect(find.text('11'), findsOneWidget);
      expect(find.text('dd'), findsOneWidget);
      expect(find.text('yyyy'), findsOneWidget);
    });

    testWidgets('a full part moves on to the next', (tester) async {
      await pumpBox(tester);
      await tester.enterText(find.byKey(const ValueKey('jump-date-M')), '11');
      await tester.pump();
      final day = tester.widget<TextField>(
          find.byKey(const ValueKey('jump-date-d')));
      expect(day.focusNode!.hasFocus, isTrue);
    });

    testWidgets('only digits, and no more than each part holds',
        (tester) async {
      await pumpBox(tester);
      await tester.enterText(
          find.byKey(const ValueKey('jump-date-y')), '20a2612');
      await tester.pump();
      expect(parts['y'], '2026');
    });

    testWidgets('parts join into a date the picker reads', (tester) async {
      await pumpBox(tester);
      await tester.enterText(find.byKey(const ValueKey('jump-date-M')), '11');
      await tester.enterText(find.byKey(const ValueKey('jump-date-d')), '3');
      await tester.enterText(
          find.byKey(const ValueKey('jump-date-y')), '2026');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final format = JumpDateFormat('M/d/y');
      expect(format.parse(format.join(parts)), DateTime(2026, 11, 3));
      expect(submitted, isTrue);
    });
  });

  group('JumpDateFormat separator', () {
    test('follows the pattern', () {
      expect(JumpDateFormat('dd/MM/y').separator, '/');
      expect(JumpDateFormat('y-MM-dd').separator, '-');
      expect(JumpDateFormat('d.M.y').separator, '.');
      expect(JumpDateFormat('y-MM-dd').order, ['y', 'M', 'd']);
    });
  });

  group('template place', () {
    final work = const Place('Work', 'geo:-27.47,153.02');
    final template = EntryLocations.join('Shift notes', [work]);

    test('a new entry from the template gets its place', () {
      final text = AddEditEntryPage.newEntryText(template, null);
      expect(EntryLocations.bodyOf(text), 'Shift notes');
      expect(EntryLocations.placesOf(text), [work]);
    });

    test('a place shared in is kept, not joined by the template one', () {
      final text = AddEditEntryPage.newEntryText(
          template, 'Jollibee https://maps.app.goo.gl/abc123');
      final places = EntryLocations.placesOf(text);
      expect(places, hasLength(1));
      expect(places.single, isNot(work));
    });

    test('shared text without a place still gets the template place', () {
      final text = AddEditEntryPage.newEntryText(template, 'hello');
      expect(EntryLocations.placesOf(text), [work]);
      expect(EntryLocations.bodyOf(text), 'Shift notes\n\nhello');
    });

    test('a template without a place changes nothing', () {
      expect(AddEditEntryPage.newEntryText('Plain', null), 'Plain');
    });
  });
}
