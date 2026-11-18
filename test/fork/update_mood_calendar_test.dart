import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/moods.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/calendar_view_options_dialog.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, DateTime day, int? mood) =>
    Entry(id: id, text: 'x', timeCreate: day, timeModified: day, mood: mood);

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

/// WCAG contrast ratio between two colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Color _cellFill(WidgetTester tester) {
  final box = tester
      .widgetList<Container>(find.descendant(
          of: find.byType(EntryDayCell), matching: find.byType(Container)))
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.color != null);
  return box.color!;
}

/// Lets the config file's 1 s save debounce run before the test ends.
Future<void> _flush(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  EasyDebounce.cancelAll();
}

void main() {
  useTemporaryConfig();

  group('Moods', () {
    test('a day\'s mood is the rounded average of its entries', () {
      final d = DateTime(2026, 11, 18);
      expect(Moods.dayMood([]), isNull);
      expect(Moods.dayMood([_entry(1, d, null)]), isNull);
      expect(Moods.dayMood([_entry(1, d, 2), _entry(2, d, null)]), 2);
      expect(Moods.dayMood([_entry(1, d, 2), _entry(2, d, 1)]), 2);
      expect(Moods.dayMood([_entry(1, d, -2), _entry(2, d, 0)]), -1);
    });

    test('names: yours, or the default when empty; max 20 characters',
        () async {
      expect(Moods.nameOf(1), 'Pleasant');
      await Moods.setName(1, '  Amazing ');
      expect(Moods.nameOf(1), 'Amazing');
      await Moods.setName(1, 'A really very long mood name');
      expect(Moods.nameOf(1).length, Moods.maxNameLength);
      await Moods.setName(1, '');
      expect(Moods.nameOf(1), 'Pleasant');
    });

    test('Reset puts back emoji, names and colours', () async {
      await Moods.setName(0, 'Meh');
      await Moods.setColor(0, const Color(0xFF29B6F6));
      await ConfigProvider.instance.set(Settings.neutralIcon, '🫠');
      await Moods.resetAll();
      expect(Moods.nameOf(0), 'Neutral');
      expect(Moods.colorOf(0), const Color(0xFFFBC02D));
      expect(ConfigProvider.instance.get(Settings.neutralIcon), '😐');
    });

    test('colours and names are saved settings (so they go in backups)', () {
      final keys = {for (final s in Settings.all) s.key};
      for (final mood in Moods.values) {
        expect(keys, contains(Moods.colorSettings[mood]!.key));
        expect(keys, contains(Moods.nameSettings[mood]!.key));
      }
      expect(keys, contains(Settings.calendarMoodColors.key));
    });

    test('icons on every fill stay readable, dark and light, any colour', () {
      final bases = [
        ThemeData(brightness: Brightness.dark).colorScheme.secondaryContainer,
        ThemeData(brightness: Brightness.light).colorScheme.secondaryContainer,
      ];
      final colours = [
        for (final s in Moods.colorSettings.values) Color(s.defaultValue),
        Colors.white,
        Colors.black,
        Colors.yellow,
        Colors.blue.shade900,
        const Color(0xFF29B6F6),
      ];
      for (final c in colours) {
        // The 🎨 button on the Moods page
        expect(_contrast(c, Moods.onColor(c)), greaterThanOrEqualTo(3.0),
            reason: 'palette icon on $c');
        // The day number on a coloured calendar day
        for (final base in bases) {
          final fill = Color.lerp(base, c, 0.78)!;
          expect(
              _contrast(fill, Moods.onColor(fill)), greaterThanOrEqualTo(3.0),
              reason: 'day number on $fill');
        }
      }
    });
  });

  group('calendar', () {
    final day = DateTime(2026, 11, 10);
    Widget cell({void Function(BuildContext, DateTime)? onSelectDay}) => Center(
          child: EntryDayCell(
            date: day,
            today: DateTime(2026, 11, 18),
            dayNumber: null,
            cellSize: 56,
            entries: [_entry(1, day, 1)],
            coverCandidates: const [],
            onSelectDay: onSelectDay,
          ),
        );

    for (final brightness in Brightness.values) {
      testWidgets('a mood day is filled with its colour ($brightness)',
          (tester) async {
        final theme = ThemeData(brightness: brightness);
        await tester.pumpWidget(_app(cell(), theme: theme));
        final base = theme.colorScheme.secondaryContainer;
        expect(_cellFill(tester), Moods.dayFill(base, 1));
        expect(_cellFill(tester), isNot(base));
      });
    }

    testWidgets('switch off: the plain square, as before', (tester) async {
      await ConfigProvider.instance.set(Settings.calendarMoodColors, false);
      final theme = ThemeData(brightness: Brightness.dark);
      await tester.pumpWidget(_app(cell(), theme: theme));
      expect(_cellFill(tester), theme.colorScheme.secondaryContainer);
      await _flush(tester);
    });

    testWidgets('the share screen\'s picker stays plain', (tester) async {
      final theme = ThemeData(brightness: Brightness.dark);
      await tester
          .pumpWidget(_app(cell(onSelectDay: (_, __) {}), theme: theme));
      expect(_cellFill(tester), theme.colorScheme.secondaryContainer);
    });

    testWidgets('a new colour shows on the calendar', (tester) async {
      await Moods.setColor(1, const Color(0xFF1E88E5));
      final theme = ThemeData(brightness: Brightness.dark);
      await tester.pumpWidget(_app(cell(), theme: theme));
      expect(
          _cellFill(tester),
          Color.lerp(theme.colorScheme.secondaryContainer,
              const Color(0xFF1E88E5), 0.78));
      await _flush(tester);
    });
  });

  group('switches', () {
    testWidgets('👁 menu has Mood colours, the same setting as the Moods page',
        (tester) async {
      await tester.pumpWidget(_app(
          const Scaffold(body: Center(child: CalendarViewOptionsDialog()))));
      expect(find.text('Mood colours'), findsOneWidget);
      expect(find.byIcon(Icons.invert_colors_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('calendarMoodColoursSwitch')));
      await tester.pumpAndSettle();
      expect(ConfigProvider.instance.get(Settings.calendarMoodColors), isFalse);

      await tester.pumpWidget(_app(const MoodsPage()));
      final pageSwitch = tester
          .widget<SwitchListTile>(find.byKey(const Key('moodColoursSwitch')));
      expect(pageSwitch.value, isFalse);
      await _flush(tester);
    });
  });

  group('Moods page', () {
    setUp(() {
      final today = DateTime.now();
      EntryStore.instance.entries = [_entry(1, today, 2)];
    });
    tearDown(() => EntryStore.instance.entries = []);

    testWidgets('five rows, best first, with names and colour buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const MoodsPage()));
      expect(find.text('Mood colours on calendar'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      for (final mood in Moods.values) {
        expect(find.byKey(Key('moodName$mood')), findsOneWidget);
        expect(find.byKey(Key('moodColor$mood')), findsOneWidget);
      }
      final top = tester.getTopLeft(find.byKey(const Key('moodName2'))).dy;
      final bottom = tester.getTopLeft(find.byKey(const Key('moodName-2'))).dy;
      expect(top, lessThan(bottom));
      expect(find.text('Very Pleasant'), findsWidgets);
    });

    testWidgets('renaming inline saves; clearing goes back to the default',
        (tester) async {
      await tester.pumpWidget(_app(const MoodsPage()));
      await tester.enterText(find.byKey(const Key('moodName0')), 'Meh');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(Moods.nameOf(0), 'Meh');
      await tester.enterText(find.byKey(const Key('moodName0')), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(Moods.nameOf(0), 'Neutral');
      final field =
          tester.widget<TextField>(find.byKey(const Key('moodName0')));
      expect(field.controller!.text, 'Neutral');
      await _flush(tester);
    });

    testWidgets('🎨 opens the app\'s Choose Color picker', (tester) async {
      await tester.pumpWidget(_app(const MoodsPage()));
      await tester.tap(find.byKey(const Key('moodColor1')));
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
    });

    for (final brightness in Brightness.values) {
      testWidgets('page builds in $brightness mode', (tester) async {
        await tester.pumpWidget(
            _app(const MoodsPage(), theme: ThemeData(brightness: brightness)));
        expect(tester.takeException(), isNull);
        final icon = tester.widget<Icon>(find.descendant(
            of: find.byKey(const Key('moodColor0')),
            matching: find.byType(Icon)));
        // Yellow takes a black icon
        expect(icon.color, Colors.black);
      });
    }
  });
}
