// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/tag_bulk_move.dart';
import 'package:daily_you/fork/tag_picker_layout.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/pages/settings/tags_settings.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/vertical_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

final _t0 = DateTime(2026, 1, 1);
final _now = DateTime(2026, 10, 25, 9);

TagCategory _cat(int id, String name, int order) => TagCategory(
    id: id, name: name, sortOrder: order, timeCreate: _t0, timeModified: _t0);

Tag _tag(int id, String name, {int? category, int order = 0}) => Tag(
    id: id,
    name: name,
    tagType: TagType.label,
    categoryId: category,
    sortOrder: order,
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

EntryTag _use(int tagId, int entryId, DateTime when) =>
    EntryTag(entryId: entryId, tagId: tagId, timeCreate: when);

final _categories = [_cat(1, 'People', 0), _cat(2, 'Hobbies', 1)];
final _tags = [
  _tag(1, 'Friends', category: 1, order: 0),
  _tag(2, 'Family', category: 1, order: 1),
  _tag(3, 'Games', category: 2, order: 0),
  _tag(4, 'Walking', category: 2, order: 1),
  _tag(5, 'Photography', category: 2, order: 2),
  _tag(6, 'Gadget', order: 0),
  _tag(7, 'Discovery', order: 1),
  _favourite,
];

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

void _seed() {
  TagsProvider.instance.categories = _categories;
  TagsProvider.instance.tags = _tags;
  // Entries aren't loaded in tests, so usage falls back to when each tag was
  // added. Walking: 3 recent uses, Friends 2, Gadget 1, Games only long ago.
  final recent = DateTime.now().subtract(const Duration(days: 3));
  TagsProvider.instance.debugSetEntryTags([
    _use(4, 1, recent),
    _use(4, 2, recent),
    _use(4, 3, recent),
    _use(1, 1, recent),
    _use(1, 2, recent),
    _use(6, 3, recent),
    _use(3, 4, DateTime.now().subtract(const Duration(days: 200))),
    _use(99, 1, recent),
  ]);
}

void main() {
  group('Tag usage', () {
    test('counts the last 60 days by entry date, not when the tag was added',
        () {
      final usage = TagPickerLayout.usage([
        _use(1, 10, _now), // entry 10 is old, despite a recent tag date
        _use(1, 11, _now),
        _use(2, 12, _now.subtract(const Duration(days: 90))),
      ], {
        10: _now.subtract(const Duration(days: 400)),
        11: _now.subtract(const Duration(days: 5)),
      }, _now);
      expect(usage[1]!.recentCount, 1);
      expect(usage[1]!.lastUsed, _now.subtract(const Duration(days: 5)));
      expect(usage[2]!.recentCount, 0);
    });

    test('sorts by recent count, then last use, then Settings order', () {
      final usage = {
        3: TagUsage(0, _now.subtract(const Duration(days: 200))),
        4: TagUsage(3, _now),
        5: const TagUsage(3, null),
      };
      final content = TagPickerLayout.build(
          pool: _tags, categories: _categories, usage: usage);
      final hobbies = content.groups[1];
      expect(hobbies.category!.name, 'Hobbies');
      expect(
          hobbies.tags.map((t) => t.name), ['Walking', 'Photography', 'Games']);
    });

    test('unused tags keep Settings order', () {
      final content = TagPickerLayout.build(
          pool: _tags, categories: _categories, usage: const {});
      expect(content.groups[0].tags.map((t) => t.name), ['Friends', 'Family']);
      expect(content.frequent, isEmpty);
    });
  });

  group('Picker layout', () {
    final usage = {
      4: TagUsage(3, _now),
      1: TagUsage(2, _now),
      6: TagUsage(1, _now),
      99: TagUsage(5, _now),
    };

    test('categories in Settings order, Uncategorized last', () {
      final content = TagPickerLayout.build(
          pool: _tags, categories: _categories, usage: usage);
      expect(content.groups.map((g) => g.category?.name),
          ['People', 'Hobbies', null]);
    });

    test('Frequent lists the most used, never Favourite', () {
      final content = TagPickerLayout.build(
          pool: _tags, categories: _categories, usage: usage);
      expect(content.frequent.map((t) => t.name),
          ['Walking', 'Friends', 'Gadget']);
      expect(content.pinnedFavourite, isNull);
      expect(content.groups.expand((g) => g.tags), isNot(contains(_favourite)));
    });

    test('Frequent stops at six', () {
      final many = [
        for (var i = 1; i <= 9; i++) _tag(100 + i, 'Tag $i'),
      ];
      final content = TagPickerLayout.build(
          pool: many,
          categories: const [],
          usage: {for (final t in many) t.id!: TagUsage(t.id!, _now)});
      expect(content.frequent, hasLength(TagPickerLayout.frequentLimit));
      expect(content.frequent.first.name, 'Tag 9');
    });

    test('the Gallery filter pins Favourite at the top', () {
      final content = TagPickerLayout.build(
          pool: _tags,
          categories: _categories,
          usage: usage,
          pinFavourite: true);
      expect(content.pinnedFavourite, _favourite);
      expect(content.frequent, isNot(contains(_favourite)));
    });

    test('searching hides Frequent and matches category names', () {
      final content = TagPickerLayout.build(
          pool: _tags, categories: _categories, usage: usage, query: 'hob');
      expect(content.frequent, isEmpty);
      expect(content.groups, hasLength(1));
      expect(content.groups.single.tags, hasLength(3));
    });

    test('tags in a deleted category count as uncategorized', () {
      final content = TagPickerLayout.build(
          pool: [_tag(50, 'Orphan', category: 77)],
          categories: _categories,
          usage: const {});
      expect(content.groups.single.category, isNull);
    });
  });

  group('Move to category', () {
    test('appends to the target, keeping order, and skips Favourite', () {
      final updates = TagBulkMove.plan(_tags, {7, 6, 99, 2}, 2, now: _now);
      expect(updates.map((t) => t.name), ['Gadget', 'Discovery', 'Family']);
      expect(updates.map((t) => t.categoryId).toSet(), {2});
      expect(updates.map((t) => t.sortOrder), [3, 4, 5]);
      expect(updates.first.timeModified, _now);
    });

    test('moving to Uncategorized clears the category', () {
      final updates = TagBulkMove.plan(_tags, {3}, null, now: _now);
      expect(updates.single.categoryId, isNull);
      expect(updates.single.sortOrder, 2);
    });

    test('tags already there are left alone', () {
      expect(TagBulkMove.plan(_tags, {3, 4}, 2), isEmpty);
    });
  });

  group('Picker popup', () {
    useTemporaryConfig();
    setUp(_seed);

    Future<void> open(WidgetTester tester, TagPickerDialog dialog) async {
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showDialog(context: context, builder: (_) => dialog),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens with Frequent and every group closed', (tester) async {
      await open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      expect(find.text('FREQUENT'), findsOneWidget);
      expect(find.text('Last 60 days'), findsOneWidget);
      // Walking is in Frequent; Photography sits in closed Hobbies
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Photography'), findsNothing);
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.byIcon(Icons.sort_rounded), findsNothing);
      // ⭐ stays out of Add Tags
      expect(find.text(Favourites.tagName), findsNothing);
    });

    testWidgets('tapping a category opens it', (tester) async {
      await open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      await tester.tap(find.text('Hobbies'));
      await tester.pumpAndSettle();
      expect(find.text('Photography'), findsOneWidget);
      expect(find.text('Walking'), findsNWidgets(2));
    });

    testWidgets('searching opens everything and hides Frequent',
        (tester) async {
      await open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      await tester.enterText(find.byType(TextField), 'pho');
      await tester.pumpAndSettle();
      expect(find.text('FREQUENT'), findsNothing);
      expect(find.text('Photography'), findsOneWidget);
      // + create stays, since no tag is called "pho"
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('Gallery filter: ⭐ pinned, No tags beside Any/All',
        (tester) async {
      await open(
          tester,
          TagPickerDialog(
            mode: TagPickerMode.filter,
            initialSelectedTagIds: const [1, 4],
          ));
      expect(find.text(Favourites.tagName), findsOneWidget);
      expect(find.text('No Tags'), findsOneWidget);
      final anyAll =
          tester.getCenter(find.byType(SegmentedButton<TagFilterMode>));
      final noTags = tester.getCenter(find.text('No Tags'));
      expect((anyAll.dy - noTags.dy).abs(), lessThan(24));
    });
  });

  group('Settings › Tags', () {
    useTemporaryConfig();
    setUp(_seed);

    testWidgets('⭐ shows as a locked row with a colour button', (tester) async {
      await tester.pumpWidget(_app(const TagsSettings()));
      await tester.pumpAndSettle();
      expect(find.text(Favourites.tagName), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      expect(find.textContaining('star button'), findsOneWidget);
    });

    testWidgets('search narrows the list', (tester) async {
      await tester.pumpWidget(_app(const TagsSettings()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'walk');
      await tester.pumpAndSettle();
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Friends'), findsNothing);
      expect(find.text('People'), findsNothing);
      expect(find.text(Favourites.tagName), findsNothing);
      expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
    });

    testWidgets('long press selects tags for Move to category', (tester) async {
      await tester.pumpWidget(_app(const TagsSettings()));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Friends'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byTooltip('Move to category'), findsOneWidget);
      await tester.tap(find.text('Family'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Move to category'));
      await tester.pumpAndSettle();
      expect(
          find.widgetWithText(SimpleDialogOption, 'Hobbies'), findsOneWidget);
      expect(find.widgetWithText(SimpleDialogOption, 'Uncategorized'),
          findsOneWidget);
    });
  });

  group('Share screen calendar', () {
    useTemporaryConfig();
    setUp(() {
      EntryStore.instance.entries = [];
      _seed();
    });

    Future<List<String>> menuFor(WidgetTester tester,
        void Function(BuildContext, DateTime)? onDay) async {
      final controller = ScrollController();
      await tester.pumpWidget(_app(Scaffold(
        body: VerticalCalendar(
            scrollController: controller, onDaySelected: onDay),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_month_rounded).first);
      await tester.pumpAndSettle();
      final l10n =
          AppLocalizations.of(tester.element(find.byType(VerticalCalendar)))!;
      return [
        if (find.text(l10n.jumpToMonthTitle).evaluate().isNotEmpty) 'month',
        if (find.text(l10n.jumpToLogTitle).evaluate().isNotEmpty) 'log',
      ];
    }

    testWidgets('sharing: the calendar icon opens the month picker directly',
        (tester) async {
      // Update 10.1: no one-item menu first
      expect(await menuFor(tester, (_, __) {}), <String>[]);
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      final dropdowns = tester
          .widgetList<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .toList();
      expect(dropdowns.length, 2);
      // Neither year nor month is blank
      for (final dropdown in dropdowns) {
        expect(
            dropdown.items!.where((item) => item.value == dropdown.value),
            hasLength(1));
      }
      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    });

    testWidgets('Calendar page keeps both', (tester) async {
      expect(await menuFor(tester, null), ['month', 'log']);
    });
  });
}
