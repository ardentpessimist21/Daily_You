// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/stats/entry_stats.dart';
import 'package:daily_you/utils/imports/import_diarium.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

const _work = Place('Work', 'geo:-27.47,153.02');
const _uni = Place('Uni');
const _jollibee = Place('Jollibee Taipei', 'https://maps.app.goo.gl/x7Kq');

Entry _entry(int id, String text) => Entry(
    id: id,
    text: text,
    timeCreate: DateTime(2026, 10, 20, 12, 30),
    timeModified: DateTime(2026, 10, 20, 12, 41));

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

void main() {
  group('Location line', () {
    test('places go on a hidden last line, after a blank line', () {
      final text =
          EntryLocations.join('Lunch break.\n', [_work, _uni, _jollibee]);
      expect(
          text,
          'Lunch break.\n\n'
          '📍 [Work](geo:-27.47,153.02) · Uni · '
          '[Jollibee Taipei](https://maps.app.goo.gl/x7Kq)');
      final (body, places) = EntryLocations.split(text);
      expect(body, 'Lunch break.');
      expect(places, [_work, _uni, _jollibee]);
    });

    test('no places leaves the text alone', () {
      expect(EntryLocations.join('Hello  ', const []), 'Hello  ');
      expect(EntryLocations.split('Hello'), ('Hello', const <Place>[]));
    });

    test('an entry can be places only', () {
      final text = EntryLocations.join('', [_uni]);
      expect(text, '📍 Uni');
      expect(EntryLocations.bodyOf(text), '');
      expect(EntryLocations.placesOf(text), [_uni]);
    });

    test('order is kept, and places can be added', () {
      final text =
          EntryLocations.add(EntryLocations.join('Shift', [_work]), _jollibee);
      expect(EntryLocations.placesOf(text), [_work, _jollibee]);
      expect(EntryLocations.bodyOf(text), 'Shift');
    });

    test('ordinary writing is never taken for places', () {
      // Not after a blank line
      expect(EntryLocations.placesOf('Went out\n📍 Uni'), isEmpty);
      // Brackets that aren't links
      expect(EntryLocations.placesOf('Hi\n\n📍 see (later)'), isEmpty);
      // 📍 in the middle of the entry
      expect(EntryLocations.placesOf('Hi\n\n📍 Uni\n\nMore text'), isEmpty);
      // A 3B-style link in the text stays text
      expect(
          EntryLocations.placesOf('Lunch at [📍 Jollibee](geo:0,0?q=Jollibee)'),
          isEmpty);
    });

    test('names stay on one line and keep the separator working', () {
      final text = EntryLocations.join(
          'x', const [Place('A · B\n[C]', 'geo:1,2'), Place('📍 Home')]);
      expect(text, 'x\n\n📍 [A B C](geo:1,2) · Home');
      expect(EntryLocations.placesOf(text),
          const [Place('A B C', 'geo:1,2'), Place('Home')]);
    });

    test('trailing spaces and newlines after the line are fine', () {
      expect(EntryLocations.placesOf('Hi\n\n📍 Uni\n\n  '), [_uni]);
    });

    test('word counts and titles skip the places', () {
      final entry = _entry(1, EntryLocations.join('One two three', [_work]));
      expect(totalWordCount([entry]), 3);
      expect(
          EntryLinks.titleOf(_entry(2, EntryLocations.join('', [_uni]))), '');
    });

    test('shared places are words with a Maps link', () {
      expect(
          EntryLocations.shareLine([_uni, _work]),
          '📍 Uni\n📍 Work '
          'https://www.google.com/maps/search/?api=1&query=-27.47%2C153.02');
    });
  });

  group('Sharing into Daily You', () {
    test('a Maps place becomes one of the entry places', () {
      expect(
          AddEditEntryPage.mergeSharedText(
              '', "Mum's place\nhttps://maps.app.goo.gl/q1"),
          "📍 [Mum's place](https://maps.app.goo.gl/q1)");
      expect(
          AddEditEntryPage.mergeSharedText(
              EntryLocations.join('Dinner', [_uni]),
              'https://maps.app.goo.gl/q1'),
          'Dinner\n\n📍 Uni · [Google Maps](https://maps.app.goo.gl/q1)');
    });

    test('other text goes above the places', () {
      expect(
          AddEditEntryPage.mergeSharedText(
              EntryLocations.join('Dinner', [_uni]), 'A quote'),
          'Dinner\n\nA quote\n\n📍 Uni');
    });
  });

  group('Pasting in the editor', () {
    tearDown(() => Places.addToEditor = null);

    test('a pasted Maps place becomes a place row', () async {
      final added = <Place>[];
      Places.addToEditor = added.add;
      final formatter = LinkPasteFormatter();
      const old = TextEditingValue(
          text: 'Lunch ', selection: TextSelection.collapsed(offset: 6));
      const pasted = TextEditingValue(
          text: 'Lunch https://maps.app.goo.gl/q1',
          selection: TextSelection.collapsed(offset: 32));
      expect(formatter.formatEditUpdate(old, pasted), old);
      await Future<void>.delayed(Duration.zero);
      expect(added, [const Place('Google Maps', 'https://maps.app.goo.gl/q1')]);
    });
  });

  group('Diarium', () {
    test('coordinates become the place', () {
      expect(diariumPlace(16.221713, 120.459061),
          const Place('16.22171, 120.45906', 'geo:16.22171,120.45906'));
      expect(diariumPlace('16.2', '120.4'),
          const Place('16.20000, 120.40000', 'geo:16.20000,120.40000'));
    });

    test('no location gives nothing', () {
      expect(diariumPlace(0, 0), isNull);
      expect(diariumPlace(null, null), isNull);
      expect(diariumPlace(0.0, null), isNull);
      expect(diariumPlace(200, 10), isNull);
    });
  });

  group('Screens', () {
    useTemporaryConfig();

    testWidgets('entry view shows buttons, not the line', (tester) async {
      EntryStore.instance.entries = [
        _entry(1, EntryLocations.join('Lunch break', [_work, _jollibee])),
      ];
      await tester.pumpWidget(_app(EntriesListPage(
          index: 0, getEntries: () => EntriesProvider.instance.entries)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lunch break'), findsOneWidget);
      expect(find.textContaining('📍'), findsNothing);
      expect(find.byType(LocationButton), findsNWidgets(2));
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Jollibee Taipei'), findsOneWidget);
    });

    testWidgets('the setting hides the buttons', (tester) async {
      await tester.runAsync(() =>
          ConfigProvider.instance.set(Settings.showLocationButtons, false));
      EntryStore.instance.entries = [
        _entry(1, EntryLocations.join('Lunch break', [_work])),
      ];
      await tester.pumpWidget(_app(EntriesListPage(
          index: 0, getEntries: () => EntriesProvider.instance.entries)));
      await tester.pumpAndSettle();
      expect(find.byType(LocationButton), findsNothing);
      expect(find.textContaining('📍'), findsNothing);
      await tester.runAsync(() =>
          ConfigProvider.instance.set(Settings.showLocationButtons, true));
    });

    testWidgets('Timeline cards show the first place and a count',
        (tester) async {
      final entry = _entry(1, EntryLocations.join('Shift', [_work, _uni]));
      await tester.pumpWidget(_app(Scaffold(
        body: Column(children: [
          SizedBox(
            height: 180,
            child: LargeEntryCardWidget(
                entry: entry, attachments: const [], showLocations: true),
          ),
          FullEntryCardWidget(entry: entry, attachments: const []),
        ]),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Work  +1'), findsNWidgets(2));
      expect(find.textContaining('📍'), findsNothing);
    });

    testWidgets('the Gallery card has no button', (tester) async {
      final entry = _entry(1, EntryLocations.join('Shift', [_work]));
      await tester.pumpWidget(_app(Scaffold(
        body: SizedBox(
          height: 180,
          child: LargeEntryCardWidget(entry: entry, attachments: const []),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byType(LocationButton), findsNothing);
      expect(find.textContaining('📍'), findsNothing);
    });

    testWidgets('the editor shows place rows, not the line', (tester) async {
      final entry =
          _entry(1, EntryLocations.join('Lunch break', [_work, _uni]));
      EntryStore.instance.entries = [entry];
      await tester.pumpWidget(_app(AddEditEntryPage(entry: entry)));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, 'Lunch break');
      expect(find.byType(LocationRows), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Uni'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove location').first);
      await tester.pumpAndSettle();
      expect(find.text('Work'), findsNothing);
      expect(find.text('Uni'), findsOneWidget);

      // A place from the 📍 sheet or Maps goes into the rows.
      Places.addToEditor!(_jollibee);
      await tester.pumpAndSettle();
      expect(find.text('Jollibee Taipei'), findsOneWidget);
      expect(field.controller!.text, 'Lunch break');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
