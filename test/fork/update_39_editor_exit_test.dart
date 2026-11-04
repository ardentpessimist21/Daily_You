// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

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
  late Database database;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
  });
  tearDown(() async {
    await database.close();
    AppDatabase.instance.database = null;
  });

  testWidgets('edit-off on a shared entry reports the kept entry',
      (tester) async {
    final entry = Entry(
        id: 1,
        text: 'Lunch',
        timeCreate: DateTime(2026, 10, 20, 12),
        timeModified: DateTime(2026, 10, 20, 12));
    EntryStore.instance.entries = [entry];
    Entry? kept;
    var calls = 0;
    await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AddEditEntryPage(
                          entry: entry,
                          onLeave: (k, _) {
                            kept = k;
                            calls++;
                          },
                        ))),
                child: const Text('open'),
              ),
            ))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_off_rounded));
    await tester.pump();
    for (var i = 0; i < 10 && calls == 0; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(calls, 1);
    expect(kept?.id, 1);
  });
}
