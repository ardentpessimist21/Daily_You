import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/moods.dart';
import 'package:daily_you/fork/selection_actions.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, DateTime created, String text, {int? mood}) => Entry(
    id: id, text: text, timeCreate: created, timeModified: created, mood: mood);

Widget _app(Widget home, {ThemeData? theme}) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ConfigProvider.instance),
        ChangeNotifierProvider.value(value: EntriesProvider.instance),
        ChangeNotifierProvider.value(value: EntryAttachmentsProvider.instance),
        ChangeNotifierProvider.value(value: TagsProvider.instance),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

/// A phone-shaped screen tall enough for all three cards.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Future<void> _openDay(WidgetTester tester, DateTime day,
    {ThemeData? theme}) async {
  _tall(tester);
  await tester.pumpWidget(_app(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => EntryTimelinePage.pushForDay(context, day),
          child: const Text('open'),
        ),
      ),
      theme: theme));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _flush(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  EasyDebounce.cancelAll();
}

void main() {
  useTemporaryConfig();

  final day = DateTime(2025, 11, 7);
  setUp(() {
    EntryStore.instance.entries = [
      _entry(1, DateTime(2025, 11, 7, 7, 5), 'Morning coffee', mood: 1),
      _entry(2, DateTime(2025, 11, 7, 12, 30), 'Lunch note'),
      _entry(3, DateTime(2025, 11, 7, 22, 15), 'Evening call', mood: 2),
    ];
  });
  tearDown(() => EntryStore.instance.entries = []);

  test('full day name, short month', () {
    expect(TimeManager.formatDateWithFullWeekdayIn(day, 'en_US'),
        'Friday, Nov 7, 2025');
  });

  testWidgets('date pill with the full day; the top bar has no title',
      (tester) async {
    await _openDay(tester, day);
    expect(find.byKey(const Key('timelineDatePill')), findsOneWidget);
    expect(find.text('Friday, Nov 7, 2025'), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.title, isNull);
  });

  testWidgets('mood on the line, not in the card; no mood keeps the dot',
      (tester) async {
    await _openDay(tester, day);
    expect(find.byKey(const Key('timelineMood')), findsNWidgets(2));
    expect(find.byKey(const Key('timelineDot')), findsOneWidget);
    // Every mood emoji on screen sits in a rail circle
    for (final icon in tester.widgetList(find.byType(MoodIcon))) {
      expect(
          find.ancestor(
              of: find.byWidget(icon),
              matching: find.byKey(const Key('timelineMood'))),
          findsOneWidget);
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('circle uses the mood colour, grey when off ($brightness)',
        (tester) async {
      final theme = ThemeData(brightness: brightness);
      await _openDay(tester, day, theme: theme);
      BoxDecoration ring() => tester
          .widget<Container>(find.byKey(const Key('timelineMood')).first)
          .decoration as BoxDecoration;
      // Sorted newest first: the 10:15 PM entry (Very Pleasant) leads
      expect((ring().border as Border).top.color, Moods.colorOf(2));

      await ConfigProvider.instance.set(Settings.calendarMoodColors, false);
      await tester.pumpAndSettle();
      expect((ring().border as Border).top.color, theme.colorScheme.outline);
      expect(ring().color, theme.colorScheme.surfaceContainerHigh);
      await _flush(tester);
    });
  }

  testWidgets('full entries: same circle on the line', (tester) async {
    await ConfigProvider.instance.set(Settings.timelineShowFullEntries, true);
    await _openDay(tester, day);
    expect(find.byKey(const Key('timelineMood')), findsNWidgets(2));
    expect(find.byKey(const Key('timelineDot')), findsOneWidget);
    await _flush(tester);
  });

  testWidgets('select mode: top bar has no actions, the pill has them',
      (tester) async {
    await _openDay(tester, day);
    expect(find.byType(SelectionActionPill), findsNothing);
    await tester.longPress(find.textContaining('Morning coffee'),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    // Date pill stays
    expect(find.text('Friday, Nov 7, 2025'), findsOneWidget);
    // Top bar: ✕, count, Select all only
    final bar = find.byType(SelectionAppBar);
    expect(find.descendant(of: bar, matching: find.byIcon(Icons.mood_rounded)),
        findsNothing);
    expect(
        find.descendant(
            of: bar, matching: find.byIcon(Icons.select_all_rounded)),
        findsOneWidget);
    // Pill at the bottom with labels
    expect(find.byType(SelectionActionPill), findsOneWidget);
    for (final label in ['Mood', 'Tags', 'Delete']) {
      expect(
          find.descendant(
              of: find.byType(SelectionActionPill), matching: find.text(label)),
          findsOneWidget);
    }
    final pillTop = tester.getTopLeft(find.byType(SelectionActionPill)).dy;
    expect(
        pillTop,
        greaterThan(tester.view.physicalSize.height /
            tester.view.devicePixelRatio /
            2));
    // Clearing the selection slides it away
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(SelectionActionPill), findsNothing);
  });

  testWidgets('hidden selection actions stay hidden in the pill',
      (tester) async {
    await SelectionActions.setShown(SelectionAction.tags, false);
    await _openDay(tester, day);
    await tester.longPress(find.textContaining('Morning coffee'),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(SelectionActionPill), matching: find.text('Tags')),
        findsNothing);
    await _flush(tester);
  });

  testWidgets('On This Day keeps its title and Years Ago headers, no pill',
      (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(EntryTimelinePage(
      header: 'On this day',
      getEntries: () => EntriesProvider.instance.entries,
      labelBuilder: (context, entry) => '1 Year Ago',
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('timelineDatePill')), findsNothing);
    expect(find.text('On this day'), findsOneWidget);
    expect(find.text('1 Year Ago'), findsWidgets);
    expect(find.byKey(const Key('timelineMood')), findsNWidgets(2));
  });
}
