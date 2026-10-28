// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/entry_share.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/search_highlight.dart';
import 'package:daily_you/fork/search_text.dart';
import 'package:daily_you/fork/selection_actions.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, String text, DateTime created, {DateTime? modified}) =>
    Entry(
        id: id,
        text: text,
        timeCreate: created,
        timeModified: modified ?? created);

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
  group('Search reads visible words', () {
    const batang =
        '_Nagtawag ang [batang](https://www.facebook.com/some_profile_name) sa labas._';
    const raziel =
        'Kasama si [Raziel](https://www.facebook.com/raziel.x) kanina.';

    test('link text inside italics is found', () {
      expect(SearchText.matches(batang, 'batang'), isTrue);
      expect(SearchText.matches(batang, 'Nagtawag'), isTrue);
      expect(SearchText.matches(raziel, 'raziel'), isTrue);
    });

    test('a phrase across the link and its italics is found', () {
      expect(SearchText.matches(batang, 'ang batang sa'), isTrue);
      expect(SearchText.matches('**Mahal** _kita_', 'mahal kita'), isTrue);
    });

    test('invisible marks pasted from Messenger are ignored', () {
      const pasted = '_Nagtawag ang [⁨ba​tang⁩](https://m.me/x)_';
      expect(SearchText.matches(pasted, 'batang'), isTrue);
      expect(SearchText.matches(batang, 'bat‎ang'), isTrue);
    });

    test('link addresses and the hidden places line are not searched', () {
      expect(SearchText.matches(batang, 'facebook'), isFalse);
      expect(SearchText.matches(batang, 'some_profile'), isFalse);
    });

    test('counts match the search', () {
      expect(SearchHighlight.count('[Batang](x:y) and batang', 'BATANG'), 2);
    });

    test('highlights land on the original characters', () {
      final folded = FoldedText('A ba​tang!');
      expect(folded.matches('batang'), [(2, 9)]);
    });
  });

  group('Gallery swipe follows the order shown', () {
    testWidgets('oldest first: right-to-left goes to the newer entry',
        (tester) async {
      final pager =
          EntriesListPage(index: 0, getEntries: () => [], newestFirst: false);
      expect(pager.newestFirst, isFalse);
      // The page view is laid out front to back when oldest first
      await tester.pumpWidget(_app(
          EntriesListPage(index: 0, getEntries: () => [], newestFirst: false)));
      expect(tester.widget<PageView>(find.byType(PageView)).reverse, isFalse);
      await tester
          .pumpWidget(_app(EntriesListPage(index: 0, getEntries: () => [])));
      expect(tester.widget<PageView>(find.byType(PageView)).reverse, isTrue);
    });
  });

  group('Recently edited', () {
    useTemporaryConfig();
    tearDown(() {
      EntriesProvider.instance.orderBy = OrderBy.date;
      EntriesProvider.instance.sortOrder = SortOrder.descending;
      EntryStore.instance.entries = [];
    });

    test('lists only entries edited on a later day, last edited first', () {
      final day = DateTime(2025, 3, 1, 9);
      EntryStore.instance.entries = [
        _entry(1, 'never edited', day),
        _entry(2, 'same day edit', day,
            modified: day.add(const Duration(hours: 3))),
        _entry(3, 'edited in May', day, modified: DateTime(2025, 5, 2)),
        _entry(4, 'edited in October', DateTime(2025, 1, 1),
            modified: DateTime(2026, 10, 1)),
      ];
      EntriesProvider.instance.orderBy = OrderBy.edited;
      expect(EntriesProvider.instance.getFilteredEntries().map((e) => e.id),
          [4, 3]);
      EntriesProvider.instance.sortOrder = SortOrder.ascending;
      expect(EntriesProvider.instance.getFilteredEntries().map((e) => e.id),
          [3, 4]);
    });
  });

  group('Sharing several entries', () {
    test('oldest first, one block each, entry links as words', () {
      final text = EntryShare.textForAll([
        _entry(2, 'Later [shift](entry:7)', DateTime(2026, 10, 2)),
        _entry(1, 'Earlier', DateTime(2026, 10, 1)),
      ], (entry) => 'D${entry.id}');
      expect(text, 'D1\nEarlier\n\nD2\nLater shift');
    });
  });

  group('Selection actions setting', () {
    useTemporaryConfig();

    test('every action shows until turned off', () async {
      expect(SelectionActions.isShown(SelectionAction.mood), isTrue);
      await SelectionActions.setShown(SelectionAction.mood, false);
      expect(SelectionActions.isShown(SelectionAction.mood), isFalse);
      expect(SelectionActions.isShown(SelectionAction.tags), isTrue);
      await SelectionActions.setShown(SelectionAction.mood, true);
      expect(SelectionActions.isShown(SelectionAction.mood), isTrue);
    });

    testWidgets('the bar leaves out hidden actions', (tester) async {
      await SelectionActions.setShown(SelectionAction.delete, false);
      // The config file write waits on a debounce timer
      EasyDebounce.cancelAll();
      final entries = [_entry(1, 'a', DateTime(2026))];
      await tester.pumpWidget(_app(Scaffold(
        appBar: SelectionAppBar(
          selected: entries,
          all: entries,
          onClear: () {},
          onSelectAll: () {},
          onDone: (_) {},
        ),
      )));
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.sell_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_rounded), findsNothing);
    });
  });

  group('Gallery filter Trackers button', () {
    useTemporaryConfig();
    final t0 = DateTime(2026, 1, 1);
    setUp(() {
      TagsProvider.instance.categories = [
        TagCategory(
            id: 1,
            name: 'Health',
            sortOrder: 0,
            timeCreate: t0,
            timeModified: t0),
        TagCategory(
            id: 2,
            name: 'People',
            sortOrder: 1,
            timeCreate: t0,
            timeModified: t0),
      ];
      TagsProvider.instance.tags = [
        Tag(
            id: 1,
            name: 'Steps',
            tagType: TagType.tracker,
            categoryId: 1,
            timeCreate: t0,
            timeModified: t0),
        Tag(
            id: 2,
            name: 'Sleep hours',
            tagType: TagType.tracker,
            timeCreate: t0,
            timeModified: t0),
        Tag(
            id: 3,
            name: 'Friends',
            tagType: TagType.label,
            categoryId: 2,
            timeCreate: t0,
            timeModified: t0),
        Tag(
            id: 99,
            name: Favourites.tagName,
            tagType: TagType.label,
            icon: Favourites.tagIcon,
            iconType: TagIconType.character,
            timeCreate: t0,
            timeModified: t0),
      ];
      TagsProvider.instance.debugSetEntryTags([]);
    });

    testWidgets('shows every tracker in its own category, ⭐ stays',
        (tester) async {
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog(
                context: context,
                builder: (_) =>
                    const TagPickerDialog(mode: TagPickerMode.filter)),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Trackers'), findsOneWidget);
      expect(find.text('Steps'), findsNothing);

      await tester.tap(find.text('Trackers'));
      await tester.pumpAndSettle();
      expect(find.text(Favourites.tagName), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.text('Sleep hours'), findsOneWidget);
      expect(find.text('People'), findsNothing);
      expect(find.text('Friends'), findsNothing);
    });
  });
}
