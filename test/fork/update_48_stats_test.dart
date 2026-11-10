// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/stats/stats_counts.dart';
import 'package:daily_you/fork/stats/stats_year.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/utils/chart_axis.dart';
import 'package:flutter_test/flutter_test.dart';

Entry _entry(int id, DateTime date, String text) =>
    Entry(id: id, text: text, timeCreate: date, timeModified: date);

void main() {
  test('All Time axis: at most 6 year labels, like 3.9.0', () {
    expect(axisYearStep(6), 1);
    expect(axisYearStep(15), 5);
    expect(axisYearStep(24), 5);
    expect(axisYearStep(42), 10);
    expect(markerMonths(6), [1, 4, 7, 10]);
    expect(markerMonths(15), [1]);
  });

  test('a picked year shows only that year', () {
    final entries = [
      _entry(1, DateTime(2024, 3, 1), 'a'),
      _entry(2, DateTime(2025, 3, 1), 'b'),
      _entry(3, DateTime(2024, 12, 31, 23), 'c'),
    ];
    expect(entriesForStats(entries, StatsRange.allTime, 2024).map((e) => e.id),
        [1, 3]);
    expect(entriesForStats(entries, StatsRange.allTime, null), hasLength(3));
    expect(entryCountsByYear(entries), {2024: 2, 2025: 1});
  });

  test('most used words skip filler words, keep names as written', () {
    final entries = [
      _entry(1, DateTime(2026, 1, 1),
          'The shift was long and Iris called. Ang saya ng shift!'),
      _entry(2, DateTime(2026, 1, 2), 'Another **shift**, iris again'),
    ];
    final words = wordUses(entries);
    expect(words.first, isA<MapEntry<String, int>>());
    expect(words.first.key, 'shift');
    expect(words.first.value, 3);
    expect(words.map((w) => w.key), contains('Iris'));
    for (final filler in ['the', 'and', 'ang', 'ng', 'was']) {
      expect(words.map((w) => w.key.toLowerCase()), isNot(contains(filler)));
    }
  });

  test('places with the same name count as one', () {
    final entries = [
      _entry(1, DateTime(2026, 1, 3),
          EntryLocations.join('a', [const Place('Home')])),
      _entry(2, DateTime(2026, 1, 2),
          EntryLocations.join('b', [const Place('home', '', 'my place')])),
      _entry(3, DateTime(2026, 1, 1),
          EntryLocations.join('c', [const Place('Work')])),
    ];
    final uses = placeUses(entries);
    expect(uses.first.count, 2);
    expect(uses.first.place.description, 'my place');
    final counts = StatsCounts.of(entries, const [], const []);
    expect(counts.places, 2);
  });

  test('tag counts only cover the entries given', () {
    final t = DateTime(2026);
    final entryTags = [
      EntryTag(entryId: 1, tagId: 7, timeCreate: t),
      EntryTag(entryId: 2, tagId: 7, timeCreate: t),
      EntryTag(entryId: 9, tagId: 8, timeCreate: t),
    ];
    final entries = [
      _entry(1, DateTime(2026, 1, 1), 'a'),
      _entry(2, DateTime(2026, 1, 2), 'b'),
    ];
    expect(tagUseCounts(entries, entryTags), {7: 2});
    expect(StatsCounts.of(entries, entryTags, const []).tags, 1);
  });
}
