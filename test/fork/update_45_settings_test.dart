// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/settings/appearance_settings.dart';
import 'package:daily_you/pages/settings_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Widget _app(Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ConfigProvider.instance),
        ChangeNotifierProvider.value(value: EntriesProvider.instance),
        ChangeNotifierProvider.value(value: EntryAttachmentsProvider.instance),
        ChangeNotifierProvider.value(value: TagsProvider.instance),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
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

Future<List<String>> _rowTitles(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1080, 6000);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(_app(page));
  await tester.pumpAndSettle();
  return tester
      .widgetList<Text>(find.descendant(
          of: find.byType(ListView), matching: find.byType(Text)))
      .map((text) => text.data ?? '')
      .where((text) => text.isNotEmpty)
      .toList();
}

void main() {
  useTemporaryConfig();

  testWidgets('main page is grouped, in order', (tester) async {
    final titles = await _rowTitles(tester, const SettingsPage());
    final order = [
      'Look and feel',
      'Appearance',
      'Home and calendar',
      'Language',
      'Journal',
      'Writing',
      'Reading and browsing',
      'Tags',
      'Templates',
      'Reminders and memories',
      'Flashbacks',
      'Your data',
      'Backup & Restore',
      'Storage & Sync',
      'Security',
      'About',
    ];
    final positions = [
      for (final title in order)
        titles.indexWhere((t) => t.toLowerCase() == title.toLowerCase()),
    ];
    for (var i = 0; i < order.length; i++) {
      expect(positions[i], isNonNegative, reason: order[i]);
      if (i > 0) expect(positions[i], greaterThan(positions[i - 1]));
    }
  });

  testWidgets('Appearance keeps only the look', (tester) async {
    final titles = await _rowTitles(tester, const AppearanceSettings());
    expect(titles, contains('Theme'));
    expect(titles, contains('Change Mood Icons'));
    expect(titles, isNot(contains('Writing Prompts')));
    expect(titles, isNot(contains('First Day Of Week')));
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });

  testWidgets('the three new pages hold the moved rows', (tester) async {
    var titles = await _rowTitles(tester,
        const AppearanceSettings(section: AppearanceSection.homeAndCalendar));
    expect(titles, containsAll(['First Day Of Week', 'Calendar System']));
    expect(titles, isNot(contains('Theme')));

    titles = await _rowTitles(
        tester, const AppearanceSettings(section: AppearanceSection.writing));
    expect(titles, containsAll(['Editor Buttons', 'Writing Prompts']));

    titles = await _rowTitles(
        tester, const AppearanceSettings(section: AppearanceSection.reading));
    expect(
        titles,
        containsAll([
          'Show Full Entries In Timeline',
          'Hide Images',
          'Gallery View Layout',
        ]));
  });
}
