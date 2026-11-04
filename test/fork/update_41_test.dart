// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/place_filter.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/fork/share_return.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/action_pill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, DateTime time, [List<Place> places = const []]) => Entry(
    id: id,
    text: EntryLocations.join('entry $id', places),
    timeCreate: time,
    timeModified: time);

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
  useTemporaryConfig();

  group('New-entry back path', () {
    final morning = _entry(1, DateTime(2021, 5, 5, 8));
    final evening = _entry(2, DateTime(2021, 5, 5, 20));

    Future<NavigatorState> host(WidgetTester tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: Text('calendar'))));
      return tester.state<NavigatorState>(find.byType(Navigator));
    }

    testWidgets('from the calendar: entry view over the day Timeline',
        (tester) async {
      EntryStore.instance.entries = [evening, morning];
      final navigator = await host(tester);
      ShareReturn.show(navigator, kept: evening, day: evening.timeCreate);
      await tester.pumpAndSettle();
      expect(find.byType(EntriesListPage), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.byType(EntryTimelinePage), findsOneWidget);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('calendar'), findsOneWidget);
    });

    testWidgets('from a Timeline: only the entry view, back to that Timeline',
        (tester) async {
      EntryStore.instance.entries = [evening, morning];
      final navigator = await host(tester);
      ShareReturn.show(navigator,
          kept: evening, day: evening.timeCreate, timelineBelow: true);
      await tester.pumpAndSettle();
      expect(find.byType(EntriesListPage), findsOneWidget);
      expect(find.byType(EntryTimelinePage, skipOffstage: false), findsNothing);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('calendar'), findsOneWidget);
    });

    testWidgets('a discarded new entry from a Timeline stays on it',
        (tester) async {
      EntryStore.instance.entries = [morning];
      final navigator = await host(tester);
      ShareReturn.show(navigator,
          kept: null, day: morning.timeCreate, timelineBelow: true);
      await tester.pumpAndSettle();
      expect(find.text('calendar'), findsOneWidget);
      expect(find.byType(EntryTimelinePage), findsNothing);
    });
  });

  group('Places filter', () {
    Widget section(
            {required bool compact,
            String? place,
            required VoidCallback onPick,
            required VoidCallback onClear}) =>
        _app(Scaffold(
          body: QuickFiltersSection(
            favourite: null,
            showTrackers: false,
            pinned: const [],
            activeTagIds: const {},
            trackersOn: false,
            lastEditedOn: false,
            compact: compact,
            enabled: true,
            onToggleTag: (_) {},
            onToggleTrackers: () {},
            onToggleLastEdited: () {},
            onToggleCompact: () {},
            showPlaces: true,
            place: place,
            onPickPlace: onPick,
            onClearPlace: onClear,
          ),
        ));

    testWidgets('collapsed: tapping a picked place turns it off',
        (tester) async {
      var picked = 0, cleared = 0;
      await tester.pumpWidget(section(
          compact: true,
          place: 'Chan',
          onPick: () => picked++,
          onClear: () => cleared++));
      await tester.tap(find.byIcon(Icons.place_rounded));
      expect((picked, cleared), (0, 1));
    });

    testWidgets('collapsed and off: tapping opens the list', (tester) async {
      var picked = 0, cleared = 0;
      await tester.pumpWidget(section(
          compact: true, onPick: () => picked++, onClear: () => cleared++));
      await tester.tap(find.byIcon(Icons.place_rounded));
      expect((picked, cleared), (1, 0));
    });

    testWidgets('with names: tapping a picked place opens the list to switch',
        (tester) async {
      var picked = 0, cleared = 0;
      await tester.pumpWidget(section(
          compact: false,
          place: 'Chan',
          onPick: () => picked++,
          onClear: () => cleared++));
      await tester.tap(find.text('Chan'));
      expect((picked, cleared), (1, 0));
    });

    final entries = [
      for (var i = 0; i < 12; i++)
        _entry(i + 1, DateTime(2026, 11, 1), [Place('Spot $i')]),
      _entry(20, DateTime(2026, 11, 2), [const Place('Chan')]),
      _entry(21, DateTime(2026, 11, 3), [const Place('Chan')]),
    ];

    Future<String?> openPicker(WidgetTester tester, {String? current}) async {
      String? result = 'unset';
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result =
                await PlaceFilter.pick(context, entries, current: current),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('the list shows about 6 places, then scrolls', (tester) async {
      await openPicker(tester);
      final list = tester.getSize(find.byType(ListView));
      expect(list.height, closeTo(40 * 6.5, 0.5));
      expect(find.text('Clear place'), findsNothing);
    });

    testWidgets('with a place picked: ticked, and Clear place turns it off',
        (tester) async {
      String? result;
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result =
                await PlaceFilter.pick(context, entries, current: 'Chan'),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.tap(find.text('Clear place'));
      await tester.pumpAndSettle();
      expect(result, PlaceFilter.cleared);
    });
  });

  group('Action pill', () {
    Widget host(bool visible) => MaterialApp(
          home: Scaffold(
            floatingActionButtonLocation: ActionPill.location,
            floatingActionButton: ActionPillSlot(
              visible: visible,
              pill: (_) => const ActionPill(child: Text('actions')),
            ),
          ),
        );

    testWidgets('slides up when shown and is gone when hidden', (tester) async {
      await tester.pumpWidget(host(false));
      expect(find.text('actions'), findsNothing);
      await tester.pumpWidget(host(true));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(SlideTransition), findsWidgets);
      await tester.pumpAndSettle();
      final shown = tester.getRect(find.text('actions'));
      await tester.pumpWidget(host(false));
      await tester.pump(const Duration(milliseconds: 100));
      // On its way down
      expect(tester.getRect(find.text('actions')).top, greaterThan(shown.top));
      await tester.pumpAndSettle();
      expect(find.text('actions'), findsNothing);
    });
  });
}
