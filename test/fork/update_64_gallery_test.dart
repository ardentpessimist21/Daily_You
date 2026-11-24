// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/gallery_filters.dart';
import 'package:daily_you/fork/jump_picker.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/gallery_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:easy_debounce/easy_debounce.dart';
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

/// Two entries a day from Sep 1 to Nov 18 2026: a Pleasant morning and an
/// evening with no mood.
void _fillEntries() {
  final entries = <Entry>[];
  var id = 1;
  for (var day = DateTime(2026, 9, 1);
      !day.isAfter(DateTime(2026, 11, 18));
      day = day.add(const Duration(days: 1))) {
    entries.add(_entry(id++, day.add(const Duration(hours: 9)),
        'Morning walk ${day.month}/${day.day}',
        mood: 1));
    entries.add(_entry(id++, day.add(const Duration(hours: 21)),
        'Evening ${day.month}/${day.day}'));
  }
  EntryStore.instance.entries = entries.reversed.toList();
  EntriesProvider.instance.searchText = 'x';
  EntriesProvider.instance.searchText = '';
}

Future<void> _openGallery(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  _fillEntries();
  TagsProvider.instance.tags = [];
  TagsProvider.instance.debugSetEntryTags([]);
  await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'list');
  await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
  await tester.pumpAndSettle();
}

Finder _pill(String id) => find.byKey(ValueKey('gallery-pill-$id'));

void main() {
  useTemporaryConfig();

  group('Keywords, moods and the date run', () {
    final t = DateTime(2026, 3, 1);
    final entries = [
      _entry(1, t, 'Walked to the Park'),
      _entry(2, t, 'park and lake'),
      _entry(3, t, '  '),
      _entry(4, t, 'Lake day', mood: 2),
    ];
    List<int?> ids(List<Entry> list) => list.map((e) => e.id).toList();

    test('all or any keyword, match case, No Text', () {
      expect(ids(const KeywordFilter(words: ['park', 'lake']).apply(entries)),
          [2]);
      expect(
          ids(const KeywordFilter(words: ['park', 'lake'], all: false)
              .apply(entries)),
          [1, 2, 4]);
      expect(
          ids(const KeywordFilter(words: ['Park'], matchCase: true)
              .apply(entries)),
          [1]);
      expect(ids(const KeywordFilter(noText: true).apply(entries)), [3]);
      expect(const KeywordFilter().isOn, isFalse);
    });

    test('moods: several at once, null for No mood', () {
      expect(ids(MoodFilter.apply(entries, {2})), [4]);
      expect(ids(MoodFilter.apply(entries, {2, null})), [1, 2, 3, 4]);
      expect(ids(MoodFilter.apply(entries, {null})), [1, 2, 3]);
    });

    test('a run of days and whole years', () {
      final days = JumpTarget.days(DateTime(2026, 4, 2), DateTime(2026, 3, 28));
      expect(days.fromDay, DateTime(2026, 3, 28));
      expect(days.toDay, DateTime(2026, 4, 2));
      final years = JumpTarget.years(2026, 2024);
      expect(years.fromDay, DateTime(2024));
      expect(years.toDay, DateTime(2026, 12, 31));
    });
  });

  group('Pill row', () {
    testWidgets('nine pills, no funnel; Favourite and Last Edited toggle',
        (tester) async {
      await _openGallery(tester);
      expect(find.byIcon(Icons.filter_alt_rounded), findsNothing);
      for (final id in [
        'favourite',
        'last-edited',
        'date',
        'mood',
        'media',
        'places',
        'trackers',
        'tags',
        'keywords',
      ]) {
        expect(_pill(id), findsOneWidget, reason: id);
      }

      await tester.tap(_pill('last-edited'));
      await tester.pumpAndSettle();
      // Nothing was edited on a later day
      expect(find.text('No Logs Match'), findsOneWidget);
      expect(find.text('0 logs'), findsOneWidget);
      // Clear all in the list clears it
      await tester.tap(find.byKey(const ValueKey('gallery-clear-all')));
      await tester.pumpAndSettle();
      expect(find.text('No Logs Match'), findsNothing);
    });

    testWidgets('Mood picker counts live and the pill moves to the front',
        (tester) async {
      await _openGallery(tester);
      await tester.ensureVisible(_pill('mood'));
      await tester.pumpAndSettle();
      await tester.tap(_pill('mood'));
      await tester.pumpAndSettle();
      expect(find.text('Show 158 Logs'), findsOneWidget);
      await tester.tap(find.text('Pleasant'));
      await tester.pumpAndSettle();
      expect(find.text('Show 79 Logs'), findsOneWidget);
      await tester.tap(find.text('Very Pleasant'));
      await tester.pumpAndSettle();
      expect(find.text('Show 79 Logs'), findsOneWidget);
      await tester.tap(find.text('Show 79 Logs'));
      await tester.pumpAndSettle();

      expect(
          find.descendant(of: _pill('mood'), matching: find.text('Mood · 2')),
          findsOneWidget);
      expect(find.text('79 logs'), findsOneWidget);
      // On pills lead the row
      final mood = tester.getTopLeft(_pill('mood')).dx;
      final favourite = tester.getTopLeft(_pill('favourite')).dx;
      expect(mood, lessThan(favourite));

      // The search bar's ✕ clears filters but keeps the search text
      await tester.enterText(find.byType(SearchBar), 'walk');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('Mood · 2'), findsNothing);
      expect(find.text('walk'), findsOneWidget);
    });

    testWidgets('Keywords: words with Enter, No Logs Match with Clear all',
        (tester) async {
      await _openGallery(tester);
      await tester.ensureVisible(_pill('keywords'));
      await tester.pumpAndSettle();
      await tester.tap(_pill('keywords'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(KeywordFilterBody),
              matching: find.byType(TextField)),
          'zebra');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      // In the picker's button, and in the list behind it
      expect(
          find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('No Logs Match')),
          findsOneWidget);
      expect(find.text('No Logs Match'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('filter-clear-all')));
      await tester.pumpAndSettle();
      expect(find.text('Show 158 Logs'), findsOneWidget);
    });

    testWidgets('folds to icons and remembers it', (tester) async {
      await _openGallery(tester);
      await tester.tap(find.byTooltip('Show icons only'));
      await tester.pumpAndSettle();
      expect(_pill('date'), findsNothing);
      expect(find.byKey(const ValueKey('gallery-icon-date')), findsOneWidget);
      expect(
          ConfigProvider.instance.get(Settings.galleryFilterIconsOnly), isTrue);
      // All nine fit on one line on a phone
      final first = tester
          .getTopLeft(find.byKey(const ValueKey('gallery-icon-favourite')));
      final last = tester
          .getTopRight(find.byKey(const ValueKey('gallery-icon-keywords')));
      expect(first.dy, last.dy);
      expect(last.dx, lessThanOrEqualTo(1080 / 2.6));
      await tester.tap(find.byTooltip('Show filter names'));
      await tester.pumpAndSettle();
      expect(_pill('date'), findsOneWidget);
      EasyDebounce.cancelAll();
    });

    testWidgets('Back in select mode clears the selection', (tester) async {
      await _openGallery(tester);
      await tester.longPress(find.text('Morning walk 11/18'));
      await tester.pumpAndSettle();
      expect(find.text('Favourite'), findsNothing); // pill row hides
      expect(GalleryPage.handleBack(), isTrue);
      await tester.pumpAndSettle();
      expect(_pill('favourite'), findsOneWidget);
      expect(GalleryPage.handleBack(), isFalse);
    });
  });
}
