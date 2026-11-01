// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

final _t0 = DateTime(2026, 1, 1);

Tag _tag(int id, String name, {int? category, TagType type = TagType.label}) =>
    Tag(
        id: id,
        name: name,
        tagType: type,
        categoryId: category,
        timeCreate: _t0,
        timeModified: _t0);

final _favourite = Tag(
    id: 99,
    name: Favourites.tagName,
    tagType: TagType.label,
    icon: Favourites.tagIcon,
    iconType: TagIconType.character,
    timeCreate: _t0,
    timeModified: _t0);

void _seed() {
  TagsProvider.instance.categories = [
    TagCategory(
        id: 1,
        name: 'Hobbies',
        sortOrder: 0,
        timeCreate: _t0,
        timeModified: _t0),
  ];
  TagsProvider.instance.tags = [
    _tag(1, 'Walking', category: 1),
    _tag(2, 'Movie', category: 1),
    _tag(3, 'Games', category: 1),
    _tag(4, 'Food'),
    _tag(5, 'Steps', type: TagType.tracker),
    _favourite,
  ];
  final recent = DateTime.now().subtract(const Duration(days: 3));
  TagsProvider.instance.debugSetEntryTags([
    EntryTag(entryId: 1, tagId: 1, timeCreate: recent),
    EntryTag(entryId: 1, tagId: 99, timeCreate: recent),
    EntryTag(entryId: 2, tagId: 1, timeCreate: recent),
    EntryTag(entryId: 2, tagId: 2, timeCreate: recent),
  ]);
}

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

Future<void> _open(WidgetTester tester, TagPickerDialog dialog) async {
  await tester.pumpWidget(_app(Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => showDialog(context: context, builder: (_) => dialog),
        child: const Text('open'),
      ),
    ),
  )));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('Pins', () {
    useTemporaryConfig();
    setUp(_seed);

    test('up to 3, in pin order, skipping what does not fit', () async {
      expect(await QuickFilters.pin([2, 1]), (2, 0));
      expect(await QuickFilters.pin([4, 3]), (1, 1));
      expect(QuickFilters.pinnedIds, [2, 1, 4]);
      await QuickFilters.unpin([1]);
      expect(QuickFilters.pinnedIds, [2, 4]);
    });

    test('deleted tags and ⭐ never count as pins', () async {
      await QuickFilters.pin([99, 2, 42]);
      expect(QuickFilters.pinnedIds, [2]);
    });
  });

  group('Quick filters narrow together', () {
    setUp(_seed);

    test('every tag that is on must be on the entry', () {
      final entries = [
        Entry(id: 1, text: 'a', timeCreate: _t0, timeModified: _t0),
        Entry(id: 2, text: 'b', timeCreate: _t0, timeModified: _t0),
      ];
      List<int?> ids(Set<int> on) => QuickFilters.apply(entries,
              tagIds: on, lastEdited: false, ascending: false)
          .map((e) => e.id)
          .toList();
      expect(ids({1}), [1, 2]);
      expect(ids({1, 99}), [1]);
      expect(ids({2, 99}), isEmpty);
    });
  });

  group('Gallery filter popup', () {
    useTemporaryConfig();
    setUp(() async {
      _seed();
      await QuickFilters.pin([2]);
      EasyDebounce.cancelAll();
    });

    testWidgets('Quick filters row, tinting in place', (tester) async {
      Set<int>? quickTags;
      bool? lastEdited;
      await _open(
          tester,
          TagPickerDialog(
            mode: TagPickerMode.filter,
            onQuickFiltersChanged: (tags, edited) {
              quickTags = tags;
              lastEdited = edited;
            },
          ));
      expect(find.text('QUICK FILTERS'), findsOneWidget);
      expect(find.text(Favourites.tagName), findsOneWidget);
      expect(find.text('Trackers'), findsOneWidget);
      expect(find.text('Last Edited'), findsOneWidget);

      await tester.tap(find.text(Favourites.tagName));
      await tester.pumpAndSettle();
      expect(quickTags, {99});
      // Stays where it is: no ✕ chip among the selected tags
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.tap(find.text('Last Edited'));
      await tester.pumpAndSettle();
      expect(lastEdited, isTrue);
    });

    testWidgets('pinned tag shows in Quick filters and its category',
        (tester) async {
      await _open(tester, const TagPickerDialog(mode: TagPickerMode.filter));
      // Movie: Quick filters, Frequent and (once opened) Hobbies
      expect(find.text('Movie'), findsNWidgets(2));
      await tester.tap(find.text('Hobbies'));
      await tester.pumpAndSettle();
      expect(find.text('Movie'), findsNWidgets(3));
    });

    testWidgets('Frequent: no window label, collapses, opens expanded again',
        (tester) async {
      await _open(tester, const TagPickerDialog(mode: TagPickerMode.filter));
      expect(find.text('Last 60 days'), findsNothing);
      expect(find.text('Walking'), findsOneWidget);
      await tester.tap(find.text('FREQUENT'));
      await tester.pumpAndSettle();
      expect(find.text('Walking'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Walking'), findsOneWidget);
    });

    testWidgets('icon-only collapse is remembered', (tester) async {
      await _open(tester, const TagPickerDialog(mode: TagPickerMode.filter));
      await tester.tap(find.text('QUICK FILTERS'));
      await tester.pumpAndSettle();
      EasyDebounce.cancelAll();
      expect(find.text('Last Edited'), findsNothing);
      expect(find.byTooltip('Last Edited'), findsOneWidget);
      expect(QuickFilters.compact, isTrue);
    });

    testWidgets('Add Tags Frequent folds too (3.7.0.37)', (tester) async {
      await _open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      expect(find.text('Last 60 days'), findsNothing);
      expect(find.text('FREQUENT'), findsOneWidget);
      expect(find.text('QUICK FILTERS'), findsNothing);
    });
  });
}
