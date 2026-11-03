// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/place_filter.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/fork/tag_picker_layout.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _t0 = DateTime(2026, 1, 1);

Entry _entry(int id, String body, List<Place> places) => Entry(
    id: id,
    text: EntryLocations.join(body, places),
    timeCreate: _t0,
    timeModified: _t0);

Tag _tag(int id, String name, {TagType type = TagType.label}) =>
    Tag(id: id, name: name, tagType: type, timeCreate: _t0, timeModified: _t0);

final _favourite = Tag(
    id: 99,
    name: Favourites.tagName,
    tagType: TagType.label,
    icon: Favourites.tagIcon,
    iconType: TagIconType.character,
    timeCreate: _t0,
    timeModified: _t0);

void main() {
  const jollibee = Place('Jollibee Taipei', 'https://maps.app.goo.gl/x');
  const work = Place('Work');

  group('Places filter', () {
    final entries = [
      _entry(1, 'Lunch', [jollibee, work]),
      _entry(2, 'Merienda', [Place('jollibee taipei')]),
      _entry(3, 'Shift', [work]),
      _entry(4, 'Home day', []),
      _entry(5, 'Again', [jollibee]),
    ];

    test('lists places most used first, matched by name ignoring case', () {
      final places = PlaceFilter.placesIn(entries);
      expect(places.map((p) => p.name), ['Jollibee Taipei', 'Work']);
      expect(places.map((p) => p.count), [3, 2]);
    });

    test('an entry matches the picked place', () {
      expect(PlaceFilter.matches(entries[1], 'Jollibee Taipei'), isTrue);
      expect(PlaceFilter.matches(entries[2], 'Jollibee Taipei'), isFalse);
      expect(PlaceFilter.matches(entries[3], 'Work'), isFalse);
    });

    test('typing narrows the list', () {
      final places = PlaceFilter.placesIn(entries);
      expect(PlaceFilter.search(places, 'jol').map((p) => p.name),
          ['Jollibee Taipei']);
      expect(PlaceFilter.search(places, '  ').length, 2);
      expect(PlaceFilter.search(places, 'zzz'), isEmpty);
    });
  });

  group('No Tags', () {
    setUp(() {
      TagsProvider.instance.tags = [_tag(1, 'Walking'), _favourite];
      TagsProvider.instance.debugSetEntryTags([
        EntryTag(entryId: 1, tagId: 1, timeCreate: _t0),
        EntryTag(entryId: 2, tagId: 99, timeCreate: _t0),
        EntryTag(entryId: 3, tagId: 1, timeCreate: _t0),
        EntryTag(entryId: 3, tagId: 99, timeCreate: _t0),
      ]);
    });

    test('⭐ Favourite does not count as a tag', () {
      expect(PlaceFilter.isUntagged(_entry(1, 'a', [])), isFalse);
      expect(PlaceFilter.isUntagged(_entry(2, 'b', [])), isTrue);
      expect(PlaceFilter.isUntagged(_entry(3, 'c', [])), isFalse);
      expect(PlaceFilter.isUntagged(_entry(4, 'd', [])), isTrue);
    });

    test('Favourite + No Tags keeps starred entries with no other tags', () {
      final all = [
        for (final id in [1, 2, 3, 4]) _entry(id, 'x', []),
      ];
      final untagged = all.where(PlaceFilter.isUntagged).toList();
      final starred = QuickFilters.apply(untagged,
          tagIds: {99}, lastEdited: false, ascending: false);
      expect(starred.map((e) => e.id), [2]);
    });
  });

  group('Quick filter chip', () {
    test('text on a filled chip is dark on light colours, light on dark', () {
      expect(
          QuickFilterChip.onFill(const Color(0xFFF2B632)), isNot(Colors.white));
      expect(QuickFilterChip.onFill(const Color(0xFF1A237E)), Colors.white);
    });

    Widget host(Widget chip) =>
        MaterialApp(home: Scaffold(body: Center(child: chip)));

    testWidgets('a pinned tracker shows its # badge open and collapsed',
        (tester) async {
      for (final compact in [false, true]) {
        await tester.pumpWidget(host(QuickFilterChip(
          label: 'Walking',
          icon: (c) => Icon(Icons.directions_walk_rounded, color: c),
          color: Colors.green,
          selected: false,
          compact: compact,
          tracker: true,
          onTap: () {},
        )));
        expect(find.byIcon(Icons.numbers_rounded), findsOneWidget);
      }
      await tester.pumpWidget(host(QuickFilterChip(
        label: 'To Do',
        icon: (c) => Icon(Icons.check_box_rounded, color: c),
        color: Colors.blue,
        selected: false,
        compact: true,
        onTap: () {},
      )));
      expect(find.byIcon(Icons.numbers_rounded), findsNothing);
    });

    testWidgets('on fills the chip with its colour', (tester) async {
      await tester.pumpWidget(host(QuickFilterChip(
        label: 'Last Edited',
        icon: (c) => Icon(Icons.history_rounded, color: c),
        color: QuickFilters.lastEditedColor,
        selected: true,
        compact: false,
        onTap: () {},
      )));
      final box = tester.widget<DecoratedBox>(find.descendant(
          of: find.byType(QuickFilterChip),
          matching: find.byType(DecoratedBox)));
      expect((box.decoration as BoxDecoration).color,
          QuickFilters.lastEditedColor);
      final icon = tester.widget<Icon>(find.byIcon(Icons.history_rounded));
      expect(icon.color, QuickFilterChip.onFill(QuickFilters.lastEditedColor));
    });

    testWidgets('a picked place has an ✕ that clears it', (tester) async {
      var cleared = false;
      await tester.pumpWidget(host(QuickFilterChip(
        label: 'Jollibee Taipei',
        icon: (c) => Icon(Icons.place_rounded, color: c),
        color: PlaceFilter.color,
        selected: true,
        compact: false,
        onTap: () {},
        onClear: () => cleared = true,
      )));
      expect(find.text('Jollibee Taipei'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(cleared, isTrue);
    });
  });

  test('Add Tags sort has only Sort by Usage and My Order', () {
    expect(TagSortMode.values, [TagSortMode.usage, TagSortMode.manual]);
    expect(TagSortMode.fromKey('recent'), TagSortMode.usage);
  });
}
