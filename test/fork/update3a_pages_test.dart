// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/search_highlight.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/pages/gallery_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, DateTime time, String text) =>
    Entry(id: id, text: text, timeCreate: time, timeModified: time);

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

  testWidgets('day timeline swipes to the next and previous day with entries',
      (tester) async {
    EntryStore.instance.entries = [
      _entry(3, DateTime(2026, 10, 15, 20), 'Fifteenth evening'),
      _entry(2, DateTime(2026, 10, 15, 8), 'Fifteenth morning'),
      _entry(1, DateTime(2026, 10, 12, 9), 'Twelfth'),
    ];
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () =>
            EntryTimelinePage.pushForDay(context, DateTime(2026, 10, 15)),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fifteenth morning'), findsWidgets);

    // Swipe right: back to the previous day with entries, skipping empty days
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.textContaining('Twelfth'), findsWidgets);
    expect(find.text('Oct 12, 2026'), findsOneWidget);

    // Swipe left: forward again
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Oct 15, 2026'), findsOneWidget);
  });

  testWidgets('gallery keeps upcoming entries in their own row',
      (tester) async {
    final now = DateTime.now();
    EntryStore.instance.entries = [
      _entry(3, DateTime(now.year, now.month, now.day + 3, 9), 'Exam day'),
      _entry(2, now, 'Today'),
      _entry(1, now.subtract(const Duration(days: 40)), 'Older'),
    ];
    // Recalculate the provider's filtered list from the new entries
    EntriesProvider.instance.searchText = 'x';
    EntriesProvider.instance.searchText = '';
    await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
    await tester.pumpAndSettle();
    expect(find.text('Upcoming · 1 entry'), findsOneWidget);
    expect(find.textContaining('Exam day'), findsNothing);
    expect(find.textContaining('Today'), findsWidgets);
  });

  testWidgets('gallery search highlights and counts matches', (tester) async {
    final now = DateTime.now();
    EntryStore.instance.entries = [
      _entry(1, now, 'Meds round, then more meds'),
    ];
    EntriesProvider.instance.searchText = 'meds';

    bool hasHighlight(Widget widget) {
      if (widget is! RichText) return false;
      var found = false;
      widget.text.visitChildren((span) {
        if (span is TextSpan &&
            span.style?.backgroundColor == SearchHighlight.matchColor) {
          found = true;
        }
        return !found;
      });
      return found;
    }

    // Grid: words highlighted on the text tile
    await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'grid');
    await tester.pumpWidget(_app(const Scaffold(body: GalleryPage())));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate(hasHighlight), findsWidgets);

    // List: highlighted, plus a match count
    await ConfigProvider.instance.set(Settings.galleryPageViewMode, 'list');
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate(hasHighlight), findsWidgets);
    expect(find.byType(SearchMatchBadge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    EntriesProvider.instance.searchText = '';
    // Let the debounced config save finish
    await tester.pump(const Duration(seconds: 2));
  });
}
