// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, int day, String text) => Entry(
    id: id,
    text: text,
    timeCreate: DateTime(2026, 10, day, 9),
    timeModified: DateTime(2026, 10, day, 9));

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

  testWidgets('tapping an entry link opens that entry', (tester) async {
    EntryStore.instance.entries = [
      _entry(1, 20, 'Read [Exam day](entry:2) again.'),
      _entry(2, 18, '# Exam day\n\nRenal pharmacology notes.'),
    ];
    await tester.pumpWidget(_app(EntriesListPage(
        index: 0, getEntries: () => EntriesProvider.instance.entries)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Renal pharmacology'), findsNothing);

    await tester.tapOnText(find.textRange.ofSubstring('Exam day'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Renal pharmacology'), findsOneWidget);
  });

  testWidgets('a link to a deleted entry says so', (tester) async {
    EntryStore.instance.entries = [
      _entry(1, 20, 'Read [Old note](entry:99) again.'),
    ];
    await tester.pumpWidget(_app(EntriesListPage(
        index: 0, getEntries: () => EntriesProvider.instance.entries)));
    await tester.pumpAndSettle();
    await tester.tapOnText(find.textRange.ofSubstring('Old note'));
    await tester.pump();
    expect(find.text('That entry no longer exists'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a place shared back from Maps goes into the waiting editor',
      (tester) async {
    final added = <Place>[];
    late BuildContext editorContext;
    await tester.pumpWidget(_app(Builder(builder: (context) {
      editorContext = context;
      return const SizedBox();
    })));
    // Maps can't open in a test; what matters is that the editor waits.
    Places.waitForMapsPlace(editorContext, added.add);
    expect(Places.deliverShared('Just some text'), isFalse);
    expect(
        Places.deliverShared('Jollibee Taipei\nhttps://maps.app.goo.gl/x7Kq'),
        isTrue);
    expect(added,
        [const Place('Jollibee Taipei', 'https://maps.app.goo.gl/x7Kq')]);
    // Only once
    expect(Places.deliverShared('https://maps.app.goo.gl/x7Kq'), isFalse);
  });
}
