// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/jump_picker.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/gallery_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, DateTime time, String text, {int? mood}) =>
    Entry(id: id, text: text, timeCreate: time, timeModified: time, mood: mood);

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

/// Two entries a day from Sep 1 to Nov 18 2026, newest first.
void _fillEntries() {
  final entries = <Entry>[];
  var id = 1;
  for (var day = DateTime(2026, 9, 1);
      !day.isAfter(DateTime(2026, 11, 18));
      day = day.add(const Duration(days: 1))) {
    entries.add(_entry(id++, day.add(const Duration(hours: 9)),
        'Morning ${day.month}/${day.day}',
        mood: 1));
    entries.add(_entry(id++, day.add(const Duration(hours: 21)),
        'Evening ${day.month}/${day.day}'));
  }
  EntryStore.instance.entries = entries.reversed.toList();
  EntriesProvider.instance.searchText = 'x';
  EntriesProvider.instance.searchText = '';
}

void main() {
  useTemporaryConfig();

  group('Timeline view', () {
    testWidgets('day pills, month labels and the stuck pill adds the month',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      _fillEntries();
      await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'list');
      await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
      await tester.pumpAndSettle();

      expect(find.text('NOVEMBER 2026'), findsOneWidget);
      expect(find.text('Wednesday 18'), findsOneWidget);
      expect(find.text('2 entries'), findsWidgets);
      // At rest the pill shows only the day
      expect(find.text(' · Nov 2026'), findsNothing);
      // No ↑ button any more
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);

      // Scroll down a little: the search bar slides away and the day under
      // the top sticks, now with its month
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text(' · Nov 2026'), findsOneWidget);
      expect(find.byType(SearchBar).hitTestable(), findsNothing);

      // A small pull down brings the search bar back
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 60));
      await tester.pumpAndSettle();
      expect(find.byType(SearchBar).hitTestable(), findsOneWidget);
      // The stuck pill sits under the search bar, not under it hidden
      final searchBottom = tester.getBottomLeft(find.byType(SearchBar)).dy;
      final stuck = find.ancestor(
          of: find.text(' · Nov 2026'), matching: find.byType(InkWell));
      expect(tester.getTopLeft(stuck.first).dy,
          greaterThanOrEqualTo(searchBottom));

      // Re-tapping the Gallery tab goes back to the top
      GalleryPage.tabRetapped.value++;
      await tester.pumpAndSettle();
      expect(find.text('NOVEMBER 2026'), findsOneWidget);
      expect(find.text(' · Nov 2026'), findsNothing);
    });

    testWidgets('picking a month shows only that month, with a chip',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      _fillEntries();
      await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'list');
      await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wednesday 18'));
      await tester.pumpAndSettle();
      expect(find.byType(JumpPickerDialog), findsOneWidget);
      // No month filter yet, so no Show all
      expect(find.byKey(const ValueKey('jump-show-all')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('jump-month-2026-10')));
      await tester.pumpAndSettle();

      // The Date pill (3.7.0.64) shows the month
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('gallery-pill-date')),
              matching: find.text('Oct 2026')),
          findsOneWidget);
      expect(find.text('OCTOBER 2026'), findsOneWidget);
      expect(find.text('NOVEMBER 2026'), findsNothing);
      expect(find.text('62 logs'), findsOneWidget);

      // The search bar's ✕ clears the filters: every month again
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('gallery-pill-date')),
              matching: find.text('Oct 2026')),
          findsNothing);
      expect(find.text('NOVEMBER 2026'), findsOneWidget);
    });

    testWidgets('a range of months, across the Range switch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      _fillEntries();
      await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'list');
      await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wednesday 18'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('jump-range-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('jump-month-2026-9')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('jump-month-2026-10')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('jump-range-done')));
      await tester.pumpAndSettle();

      expect(find.text('Sep – Oct 2026'), findsOneWidget);
      expect(find.text('122 logs'), findsOneWidget);

      // Reopened: the range is still on, and Show all clears it
      await tester.tap(find.text('Sep – Oct 2026'));
      await tester.pumpAndSettle();
      final rangeSwitch = tester
          .widget<Switch>(find.byKey(const ValueKey('jump-range-switch')));
      expect(rangeSwitch.value, isTrue);
      await tester.tap(find.byKey(const ValueKey('jump-show-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chip-month')), findsNothing);
    });

    testWidgets('the search ✕ clears the month filter too', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      _fillEntries();
      await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'list');
      await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wednesday 18'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('jump-month-2026-10')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearButton')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clearButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chip-month')), findsNothing);
      expect(find.text('NOVEMBER 2026'), findsOneWidget);
    });
  });

  testWidgets('only the cards on screen are built, however many days',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final entries = <Entry>[];
    for (var i = 0; i < 1500; i++) {
      entries.add(_entry(i + 1,
          DateTime(2026, 11, 18, 9).subtract(Duration(days: i)), 'Day $i'));
    }
    EntryStore.instance.entries = entries;
    EntriesProvider.instance.searchText = 'x';
    EntriesProvider.instance.searchText = '';
    await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'list');
    await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
    await tester.pumpAndSettle();
    expect(find.byType(LargeEntryCardWidget).evaluate().length, lessThan(15));
    await tester.pump(const Duration(seconds: 2));
  });

  group('Grid view', () {
    testWidgets('one sticky pill per month, with its count', (tester) async {
      // The test font is much wider than the app's, so tile headers
      // overflow here; that's not what this test checks
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        onError?.call(details);
      };
      addTearDown(() => FlutterError.onError = onError);
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      _fillEntries();
      await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'grid');
      await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('36 entries'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);

      // Partway down November: its pill is stuck at the top
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text('November 2026').hitTestable(), findsOneWidget);

      // Scrolled into October: its pill takes over
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(find.text('October 2026').hitTestable(), findsOneWidget);
      expect(find.text('62 entries').hitTestable(), findsOneWidget);
      await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'list');
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Media Quick filters', () {
    test('Any media and No media stand alone; kinds combine', () {
      var media = <MediaFilter>{};
      media = MediaFilter.toggle(media, MediaFilter.photos);
      media = MediaFilter.toggle(media, MediaFilter.video);
      expect(media, {MediaFilter.photos, MediaFilter.video});
      media = MediaFilter.toggle(media, MediaFilter.none);
      expect(media, {MediaFilter.none});
      media = MediaFilter.toggle(media, MediaFilter.audio);
      expect(media, {MediaFilter.audio});
      media = MediaFilter.toggle(media, MediaFilter.audio);
      expect(media, isEmpty);
    });

    test('a range is ordered and the same month twice is one month', () {
      final range = JumpTarget.range(DateTime(2026, 11), DateTime(2025, 12));
      expect(range.month, DateTime(2025, 12));
      expect(range.endMonth, DateTime(2026, 11));
      final single = JumpTarget.range(DateTime(2026, 3), DateTime(2026, 3));
      expect(single.endMonth, isNull);
    });
  });
}
