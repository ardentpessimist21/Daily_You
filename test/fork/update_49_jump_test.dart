// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/date_template_box.dart';
import 'package:daily_you/fork/jump_picker.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/vertical_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, DateTime time) =>
    Entry(id: id, text: 'entry $id', timeCreate: time, timeModified: time);

Widget _app(Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ConfigProvider.instance),
        ChangeNotifierProvider.value(value: EntriesProvider.instance),
        ChangeNotifierProvider.value(value: EntryAttachmentsProvider.instance),
        ChangeNotifierProvider.value(value: TagsProvider.instance),
      ],
      child: MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...appLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

/// Entries in Mar 2024 (2), Sep 2025 (3 on the 3rd, 1 on the 20th) and
/// May 2026 (1). 2023 and the rest are empty.
final _dates = [
  DateTime(2024, 3, 2, 9),
  DateTime(2024, 3, 9, 9),
  DateTime(2025, 9, 3, 8),
  DateTime(2025, 9, 3, 12),
  DateTime(2025, 9, 3, 20),
  DateTime(2025, 9, 20, 10),
  DateTime(2026, 5, 14, 7),
];

void main() {
  group('Typed date format', () {
    test('reads the numbers in the locale order', () {
      expect(JumpDateFormat('dd/MM/y').parse('14/05/2026'),
          DateTime(2026, 5, 14));
      expect(JumpDateFormat('M/d/y').parse('5/14/2026'), DateTime(2026, 5, 14));
      expect(
          JumpDateFormat('y-MM-dd').parse('2026-05-14'), DateTime(2026, 5, 14));
      // Any separator works
      expect(JumpDateFormat('dd/MM/y').parse('14.5.2026'),
          DateTime(2026, 5, 14));
      expect(JumpDateFormat('dd/MM/y').parse('14 5 2026'),
          DateTime(2026, 5, 14));
    });

    test('rejects dates that do not exist', () {
      final format = JumpDateFormat('dd/MM/y');
      expect(format.parse('31/02/2026'), isNull);
      expect(format.parse('14/13/2026'), isNull);
      expect(format.parse('14/05/26'), isNull);
      expect(format.parse('14/05'), isNull);
      expect(format.parse('soon'), isNull);
      expect(format.parse(''), isNull);
    });

    test('the hint spells the order out', () {
      expect(JumpDateFormat('dd/MM/y').hint, 'dd/mm/yyyy');
      expect(JumpDateFormat('M/d/y').hint, 'mm/dd/yyyy');
    });
  });

  group('Picker', () {
    JumpTarget? result;
    var closed = false;

    Future<void> open(
      WidgetTester tester, {
      DateTime? selected,
      bool allowEmpty = false,
      int? lastYear,
      DateTime? firstDate,
      DateTime? lastDate,
    }) async {
      result = null;
      closed = false;
      await tester.pumpWidget(_app(Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await JumpPicker.show(
                context,
                entryDates: _dates,
                selected: selected ?? DateTime(2025, 9),
                allowEmpty: allowEmpty,
                lastYear: lastYear,
                firstDate: firstDate,
                lastDate: lastDate,
                dateFormat: JumpDateFormat('dd/MM/y'),
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Finder month(int year, int m) => find.byKey(ValueKey('jump-month-$year-$m'));
    Finder year(int y) => find.byKey(ValueKey('jump-year-$y'));

    testWidgets('months show entry counts with the notes icon', (tester) async {
      await open(tester);
      expect(find.text('Jump to month'), findsOneWidget);
      expect(find.descendant(of: month(2025, 9), matching: find.text('4')),
          findsOneWidget);
      expect(
          find.descendant(
              of: month(2025, 9),
              matching: find.byIcon(Icons.description_outlined)),
          findsOneWidget);
      // Empty months show a dash and no icon
      expect(find.descendant(of: month(2025, 1), matching: find.text('–')),
          findsOneWidget);
      expect(
          find.descendant(
              of: month(2025, 1),
              matching: find.byIcon(Icons.description_outlined)),
          findsNothing);
      // No arrows any more
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('tapping a month with entries jumps there', (tester) async {
      await open(tester);
      await tester.tap(month(2025, 9));
      await tester.pumpAndSettle();
      expect(result!.month, DateTime(2025, 9));
      expect(result!.day, isNull);
    });

    testWidgets('an empty month cannot be tapped', (tester) async {
      await open(tester);
      await tester.tap(month(2025, 1));
      await tester.pumpAndSettle();
      expect(closed, isFalse);
      expect(find.text('Jump to month'), findsOneWidget);
    });

    testWidgets('sharing: an empty month can be picked', (tester) async {
      await open(tester, allowEmpty: true);
      await tester.tap(month(2025, 1));
      await tester.pumpAndSettle();
      expect(result!.month, DateTime(2025, 1));
    });

    testWidgets('faint neighbouring years step a year; none past the ends',
        (tester) async {
      await open(tester);
      expect(find.byKey(const ValueKey('jump-neighbour-2024')), findsOneWidget);
      expect(find.byKey(const ValueKey('jump-neighbour-2026')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('jump-neighbour-2026')));
      await tester.pumpAndSettle();
      expect(month(2026, 5), findsOneWidget);
      // 2026 is the last year: nothing on the right
      expect(find.byKey(const ValueKey('jump-neighbour-2027')), findsNothing);
      expect(find.byKey(const ValueKey('jump-neighbour-2025')), findsOneWidget);
    });

    testWidgets('swiping the months changes year', (tester) async {
      await open(tester);
      await tester.fling(find.byKey(const ValueKey('jump-months')),
          const Offset(300, 0), 1200);
      await tester.pumpAndSettle();
      expect(month(2024, 3), findsOneWidget);
      expect(find.descendant(of: month(2024, 3), matching: find.text('2')),
          findsOneWidget);
      await tester.fling(find.byKey(const ValueKey('jump-months')),
          const Offset(-300, 0), 1200);
      await tester.pumpAndSettle();
      expect(month(2025, 9), findsOneWidget);
    });

    testWidgets('tap the year: year grid, then back to that year',
        (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('jump-year')));
      await tester.pumpAndSettle();
      expect(find.text('Jump to year'), findsOneWidget);
      expect(find.text('Jump to month'), findsNothing);
      expect(find.descendant(of: year(2025), matching: find.text('4')),
          findsOneWidget);
      expect(find.descendant(of: year(2024), matching: find.text('2')),
          findsOneWidget);
      await tester.tap(year(2024));
      await tester.pumpAndSettle();
      expect(find.text('Jump to month'), findsOneWidget);
      expect(month(2024, 3), findsOneWidget);
      await tester.tap(month(2024, 3));
      await tester.pumpAndSettle();
      expect(result!.month, DateTime(2024, 3));
    });

    testWidgets('an empty year cannot be tapped', (tester) async {
      await open(tester, lastYear: 2027);
      await tester.tap(find.byKey(const ValueKey('jump-year')));
      await tester.pumpAndSettle();
      await tester.tap(year(2027));
      await tester.pumpAndSettle();
      expect(find.text('Jump to year'), findsOneWidget);
    });

    testWidgets('the pencil switches to typing and the calendar goes back',
        (tester) async {
      await open(tester);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Jump to date'), findsOneWidget);
      expect(find.byKey(const ValueKey('jump-date')), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Jump to month'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.text('OK'), findsNothing);
      expect(month(2025, 9), findsOneWidget);
    });

    Future<void> type(WidgetTester tester, String text) async {
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await enterJumpDate(tester, text);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets('a typed date in a month with entries is returned',
        (tester) async {
      await open(tester);
      await type(tester, '03/09/2025');
      expect(result!.day, DateTime(2025, 9, 3));
      expect(result!.month, DateTime(2025, 9));
    });

    testWidgets('an empty day in a month with entries is still returned',
        (tester) async {
      await open(tester);
      await type(tester, '04/09/2025');
      expect(result!.day, DateTime(2025, 9, 4));
    });

    testWidgets('a typed date in an empty month shows a message',
        (tester) async {
      await open(tester);
      await type(tester, '14/05/2025');
      expect(closed, isFalse);
      expect(find.text('No entries in May 2025. Pick another date.'),
          findsOneWidget);
    });

    testWidgets('a date that is not real asks for the format', (tester) async {
      await open(tester);
      await type(tester, '31/02/2025');
      expect(closed, isFalse);
      expect(find.text('Enter a date like dd/mm/yyyy'), findsOneWidget);
    });

    testWidgets('a date outside the journal says so', (tester) async {
      await open(tester);
      await type(tester, '14/05/2019');
      expect(closed, isFalse);
      expect(find.text('That date is outside your journal'), findsOneWidget);
    });

    testWidgets('sharing: any date in range is returned', (tester) async {
      await open(tester,
          allowEmpty: true,
          firstDate: DateTime(2000),
          lastDate: DateTime(2026, 12, 31));
      await type(tester, '14/05/2019');
      expect(result!.day, DateTime(2019, 5, 14));
    });

    testWidgets('Cancel closes without jumping, from typing too',
        (tester) async {
      await open(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(result, isNull);
    });
  });

  group('Home calendar', () {
    useTemporaryConfig();
    final now = DateTime.now();
    // Two entries on the 1st of this month, one on the 2nd
    final first = DateTime(now.year, now.month, 1);
    final second = DateTime(now.year, now.month, 2);

    setUp(() {
      EntryStore.instance.entries = [
        _entry(1, first.add(const Duration(hours: 8))),
        _entry(2, first.add(const Duration(hours: 20))),
        _entry(3, second.add(const Duration(hours: 9))),
      ];
    });

    Future<void> openPicker(WidgetTester tester,
        {void Function(BuildContext, DateTime)? onDay,
        bool wide = false}) async {
      tester.view.physicalSize = Size(wide ? 2400 : 1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(Scaffold(
        body: VerticalCalendar(
            scrollController: ScrollController(), onDaySelected: onDay),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_month_rounded).first);
      await tester.pumpAndSettle();
    }

    String two(int n) => n.toString().padLeft(2, '0');

    Future<void> type(WidgetTester tester, DateTime day) async {
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      final format = JumpDateFormat.of(
          tester.element(find.byKey(const ValueKey('jump-date'))));
      final text = format.hint
          .replaceAll('dd', two(day.day))
          .replaceAll('mm', two(day.month))
          .replaceAll('yyyy', '${day.year}');
      await enterJumpDate(tester, text);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets('one tap opens the picker; this month shows its count',
        (tester) async {
      await openPicker(tester);
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      expect(find.text('Jump to log'), findsNothing);
      expect(
          find.descendant(
              of: find
                  .byKey(ValueKey('jump-month-${now.year}-${now.month}')),
              matching: find.text('3')),
          findsOneWidget);
    });

    testWidgets('a typed day with one entry opens it', (tester) async {
      await openPicker(tester);
      await type(tester, second);
      expect(find.byType(EntriesListPage), findsOneWidget);
    });

    testWidgets('a typed day with several entries opens its Timeline',
        (tester) async {
      await openPicker(tester);
      await type(tester, first);
      expect(find.byType(EntryTimelinePage), findsOneWidget);
    });

    testWidgets('a typed empty day in this month only leaves a note',
        (tester) async {
      await openPicker(tester);
      final empty = DateTime(now.year, now.month, 3);
      await type(tester, empty);
      expect(find.byType(EntriesListPage), findsNothing);
      expect(find.byType(EntryTimelinePage), findsNothing);
      expect(find.textContaining('No entries on'), findsOneWidget);
    });

    testWidgets('sharing: a typed date picks that day', (tester) async {
      DateTime? picked;
      await openPicker(tester, onDay: (_, day) => picked = day);
      await type(tester, second);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(picked, second);
      expect(find.byType(EntriesListPage), findsNothing);
    });

    testWidgets('the Jalali calendar keeps the two-dropdown picker',
        (tester) async {
      await ConfigProvider.instance.set(Settings.calendarSystem, 'jalali');
      // Wide, so the old picker's month names fit in the test font
      await openPicker(tester, wide: true);
      expect(find.byKey(const ValueKey('jump-months')), findsNothing);
      expect(find.byType(DropdownButton<int>), findsNWidgets(2));
    });
  });
}

/// Types [text] (three numbers in the box's order) into the date template
/// box (3.7.0.50), one part at a time.
Future<void> enterJumpDate(WidgetTester tester, String text) async {
  final box =
      tester.widget<DateTemplateBox>(find.byKey(const ValueKey('jump-date')));
  final numbers =
      RegExp(r'\d+').allMatches(text).map((m) => m.group(0)!).toList();
  for (var i = 0; i < box.order.length; i++) {
    await tester.enterText(
        find.byKey(ValueKey('jump-date-${box.order[i]}')),
        i < numbers.length ? numbers[i] : '');
  }
  await tester.pump();
}
