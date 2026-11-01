// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/fork/tag_picker_layout.dart';
import 'package:daily_you/fork/tag_pins.dart';
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
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

final _t0 = DateTime(2026, 1, 1);

Tag _tag(int id, String name,
        {int? category, int order = 0, TagType type = TagType.label}) =>
    Tag(
        id: id,
        name: name,
        tagType: type,
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

void _seed() {
  TagsProvider.instance.categories = [
    TagCategory(
        id: 1,
        name: 'People',
        sortOrder: 0,
        timeCreate: _t0,
        timeModified: _t0),
    TagCategory(
        id: 2,
        name: 'Hobbies',
        sortOrder: 1,
        timeCreate: _t0,
        timeModified: _t0),
  ];
  TagsProvider.instance.tags = [
    _tag(1, 'Friends', category: 1, order: 0),
    _tag(2, 'Family', category: 1, order: 1),
    _tag(3, 'Games', category: 2, order: 0),
    _tag(4, 'Walking', category: 2, order: 1),
    _tag(5, 'Steps', category: 2, order: 2, type: TagType.tracker),
    _tag(6, 'Gadget', order: 0),
    _tag(7, 'Discovery', order: 1),
    _tag(8, 'Water', order: 2, type: TagType.tracker),
    _favourite,
  ];
  TagsProvider.instance.debugSetEntryTags([]);
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

Future<void> _openSettings(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(const TagsSettings()));
  await tester.pumpAndSettle();
}

void main() {
  group('Pin lists', () {
    useTemporaryConfig();
    setUp(_seed);

    test('Gallery holds 3 and Add Tags 6, kept apart', () async {
      expect(await TagPinList.gallery.pin([1, 2, 3, 4]), (3, 1));
      expect(await TagPinList.addTags.pin([4, 3, 2, 1, 6, 7, 8]), (6, 1));
      expect(TagPinList.gallery.ids, [1, 2, 3]);
      expect(TagPinList.addTags.ids, [4, 3, 2, 1, 6, 7]);
      expect(TagPinList.gallery.free, 0);
      expect(QuickFilters.pinnedIds, [1, 2, 3]);
    });

    test('Add Tags starts empty, whatever the Gallery has', () async {
      await TagPinList.gallery.pin([1]);
      expect(TagPinList.addTags.ids, isEmpty);
    });

    test('drag order is saved', () async {
      await TagPinList.addTags.pin([1, 2, 3]);
      await TagPinList.addTags.move(0, 2);
      expect(TagPinList.addTags.ids, [2, 3, 1]);
      await TagPinList.addTags.move(2, 0);
      expect(TagPinList.addTags.ids, [1, 2, 3]);
    });

    test('a deleted tag leaves both lists', () async {
      await TagPinList.gallery.pin([1, 2]);
      await TagPinList.addTags.pin([2, 3]);
      await TagPinList.forget([2]);
      expect(TagPinList.gallery.ids, [1]);
      expect(TagPinList.addTags.ids, [3]);
      expect(TagPinList.pinnedAnywhere(2), isFalse);
      expect(TagPinList.pinnedAnywhere(3), isTrue);
    });

    test('pins and the sort choice go in backups', () {
      final keys = {for (final setting in Settings.all) setting.key};
      expect(keys, containsAll(['addTagsPins', 'addTagsSortMode']));
    });
  });

  group('Add Tags sort', () {
    final usage = {
      3: TagUsage(1, DateTime(2026, 10, 30)),
      4: TagUsage(5, DateTime(2026, 9, 1)),
    };
    List<String> hobbies(TagSortMode mode) {
      _seed();
      final content = TagPickerLayout.build(
        pool: TagsProvider.instance.tags,
        categories: TagsProvider.instance.categories,
        usage: usage,
        sortMode: mode,
      );
      return content.groups[1].tags.map((tag) => tag.name).toList();
    }

    test('Sort by Usage puts the most used first', () {
      expect(hobbies(TagSortMode.usage), ['Walking', 'Games', 'Steps']);
    });

    test('Recent puts the last used first', () {
      expect(hobbies(TagSortMode.recent), ['Games', 'Walking', 'Steps']);
    });

    test('My Order follows Settings › Tags', () {
      expect(hobbies(TagSortMode.manual), ['Games', 'Walking', 'Steps']);
      _seed();
      final content = TagPickerLayout.build(
        pool: TagsProvider.instance.tags,
        categories: TagsProvider.instance.categories,
        usage: usage,
        sortMode: TagSortMode.manual,
      );
      // Frequent stays by usage
      expect(content.frequent.map((tag) => tag.name), ['Walking', 'Games']);
    });
  });

  group('Add Tags popup', () {
    useTemporaryConfig();
    setUp(_seed);

    testWidgets('pinned row toggles tags on and off the entry', (tester) async {
      await TagPinList.addTags.pin([6, 2]);
      final source = TagAttachmentSource();
      await _open(
          tester, TagPickerDialog(mode: TagPickerMode.attach, source: source));
      expect(find.text('PINNED'), findsOneWidget);
      await tester.tap(find.widgetWithText(QuickFilterChip, 'Gadget'));
      await tester.pumpAndSettle();
      expect(source.attachedTagIds, [6]);
      await tester.tap(find.widgetWithText(QuickFilterChip, 'Gadget'));
      await tester.pumpAndSettle();
      expect(source.attachedTagIds, isEmpty);
    });

    testWidgets('no pins, no row', (tester) async {
      await _open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      expect(find.text('PINNED'), findsNothing);
    });

    testWidgets('icon-only Pinned row is remembered apart from Gallery',
        (tester) async {
      await TagPinList.addTags.pin([6]);
      await _open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      await tester.tap(find.text('PINNED'));
      await tester.pumpAndSettle();
      EasyDebounce.cancelAll();
      expect(ConfigProvider.instance.get(Settings.addTagsPinsCompact), isTrue);
      expect(QuickFilters.compact, isFalse);
    });

    testWidgets('# shows only trackers, with groups open', (tester) async {
      await TagPinList.addTags.pin([6]);
      await _open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      await tester.tap(find.byTooltip('Trackers only'));
      await tester.pumpAndSettle();
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Walking'), findsNothing);
      // Pinned and Frequent step aside, like when searching
      expect(find.text('PINNED'), findsNothing);
      await tester.tap(find.byTooltip('Trackers only'));
      await tester.pumpAndSettle();
      expect(find.text('Steps'), findsNothing);
    });

    testWidgets('sort menu choice is remembered', (tester) async {
      await _open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      await tester.tap(find.byIcon(Icons.sort_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Sort by Usage'), findsOneWidget);
      expect(find.text('My Order'), findsOneWidget);
      await tester.tap(find.text('My Order'));
      await tester.pumpAndSettle();
      EasyDebounce.cancelAll();
      expect(ConfigProvider.instance.get(Settings.addTagsSortMode), 'manual');
    });

    testWidgets('Gallery filter has no sort menu or # button', (tester) async {
      await _open(tester, const TagPickerDialog(mode: TagPickerMode.filter));
      expect(find.byIcon(Icons.sort_rounded), findsNothing);
      expect(find.byTooltip('Trackers only'), findsNothing);
    });
  });

  group('Settings › Tags', () {
    useTemporaryConfig();
    setUp(_seed);

    testWidgets('categories start collapsed; Expand all opens everything',
        (tester) async {
      await _openSettings(tester);
      expect(find.text('Friends'), findsNothing);
      expect(find.byIcon(Icons.share_rounded), findsNothing);
      await tester.tap(find.byTooltip('Expand all'));
      await tester.pumpAndSettle();
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Gadget'), findsOneWidget);
      await tester.tap(find.byTooltip('Collapse all'));
      await tester.pumpAndSettle();
      expect(find.text('Friends'), findsNothing);
    });

    testWidgets('long press turns + into the action pill', (tester) async {
      await _openSettings(tester);
      await tester.tap(find.byTooltip('Expand all'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Friends'));
      await tester.pumpAndSettle();
      for (final tooltip in [
        'Share',
        'Pin to',
        'Move to category',
        'Change colour',
        'Delete',
        'Select all',
        'Clear selection',
      ]) {
        expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
      }
      // Share opens Save and Share in the pill
      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Select all and Clear selection', (tester) async {
      await _openSettings(tester);
      await tester.tap(find.byTooltip('Expand all'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Friends'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Select all'));
      await tester.pumpAndSettle();
      // Everything but ⭐
      expect(find.text('8 selected'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear selection'));
      await tester.pumpAndSettle();
      // Still selecting, with nothing ticked
      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('a category checkbox ticks its tags without opening it',
        (tester) async {
      await _openSettings(tester);
      await tester.tap(find.byTooltip('Expand all'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Gadget'));
      await tester.pumpAndSettle();
      // Fold Hobbies by tapping its header, then tick it closed
      await tester.tap(find.text('Hobbies'));
      await tester.pumpAndSettle();
      expect(find.text('Walking'), findsNothing);
      // Hobbies header's checkbox: Games, Walking, Steps
      final hobbiesBox = find.descendant(
          of: find.ancestor(
              of: find.text('Hobbies'), matching: find.byType(Row)),
          matching: find.byType(Checkbox));
      await tester.tap(hobbiesBox.first);
      await tester.pumpAndSettle();
      expect(find.text('4 selected'), findsOneWidget);
      expect(find.text('Walking'), findsNothing);
    });

    testWidgets('with a search typed, Select all ticks only the matches',
        (tester) async {
      await _openSettings(tester);
      await tester.tap(find.byTooltip('Expand all'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Friends'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear selection'));
      await tester.enterText(find.byType(TextField), 'wa');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Select all'));
      await tester.pumpAndSettle();
      // Walking and Water
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('Pin asks Gallery or Add Tags and pins there', (tester) async {
      await _openSettings(tester);
      await tester.tap(find.byTooltip('Expand all'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Friends'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pin to'));
      await tester.pumpAndSettle();
      expect(find.text('Gallery filter'), findsOneWidget);
      expect(find.text('6 of 6 free'), findsOneWidget);
      await tester.tap(find.text('Add Tags'));
      await tester.pumpAndSettle();
      EasyDebounce.cancelAll();
      expect(TagPinList.addTags.ids, [1]);
      expect(TagPinList.gallery.ids, isEmpty);
      // Pinned tags keep their 📌 in the list
      expect(find.byIcon(Icons.push_pin_rounded), findsWidgets);
    });

    testWidgets('pinned rows show chips and the free slot', (tester) async {
      await TagPinList.gallery.pin([4]);
      await _openSettings(tester);
      await tester.tap(find.text('Pinned · Gallery'));
      await tester.pumpAndSettle();
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('2 free'), findsOneWidget);
      expect(find.text('Last Edited'), findsOneWidget);
      await tester.tap(find.byTooltip('Unpin from Quick filters'));
      await tester.pumpAndSettle();
      EasyDebounce.cancelAll();
      expect(TagPinList.gallery.ids, isEmpty);
    });
  });
}
