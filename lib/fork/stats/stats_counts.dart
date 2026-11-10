// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/search_text.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:material_ui/material_ui.dart';

/// Statistics counts and the numbers behind their pages (3.7.0.48).
class StatsCounts {
  const StatsCounts(
      {required this.tags, required this.places, required this.media});

  /// Different tags used on the entries.
  final int tags;

  /// Different places (same name = same place).
  final int places;

  /// Photos, videos and audio clips on the entries.
  final int media;

  static StatsCounts of(List<Entry> entries, List<EntryTag> entryTags,
      List<EntryAttachment> attachments) {
    final ids = {for (final entry in entries) entry.id};
    final tags = {
      for (final entryTag in entryTags)
        if (ids.contains(entryTag.entryId)) entryTag.tagId,
    };
    final places = <String>{};
    for (final entry in entries) {
      for (final place in EntryLocations.placesOf(entry.text)) {
        places.add(placeKey(place.name));
      }
    }
    final media =
        attachments.where((attachment) => ids.contains(attachment.entryId));
    return StatsCounts(
        tags: tags.length, places: places.length, media: media.length);
  }
}

/// Places with the same name count as one.
String placeKey(String name) => name.trim().toLowerCase();

/// How many of [entries] each tag is on.
Map<int, int> tagUseCounts(List<Entry> entries, List<EntryTag> entryTags) {
  final ids = {for (final entry in entries) entry.id};
  final counts = <int, int>{};
  for (final entryTag in entryTags) {
    if (!ids.contains(entryTag.entryId)) continue;
    counts.update(entryTag.tagId, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

/// One place on Top places: the newest entry's version of it (for its
/// description), how many entries it's on, and its entries newest first.
class PlaceUse {
  PlaceUse(this.place);

  Place place;
  final List<Entry> entries = [];
  int get count => entries.length;
}

/// Places on [entries], most used first (newest first on a tie).
List<PlaceUse> placeUses(List<Entry> entries) {
  final sorted = entries.toList()
    ..sort((a, b) => b.timeCreate.compareTo(a.timeCreate));
  final byKey = <String, PlaceUse>{};
  for (final entry in sorted) {
    final seen = <String>{};
    for (final place in EntryLocations.placesOf(entry.text)) {
      final key = placeKey(place.name);
      if (!seen.add(key)) continue;
      final use = byKey.putIfAbsent(key, () => PlaceUse(place));
      if (use.place.description.isEmpty && place.description.isNotEmpty) {
        use.place = place;
      }
      use.entries.add(entry);
    }
  }
  final list = byKey.values.toList();
  list.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return b.entries.first.timeCreate.compareTo(a.entries.first.timeCreate);
  });
  return list;
}

/// Most used words: small filler words (English and Tagalog), words under
/// 3 letters and numbers are left out. Case doesn't matter.
List<MapEntry<String, int>> wordUses(List<Entry> entries) {
  final counts = <String, int>{};
  final original = <String, String>{};
  for (final entry in entries) {
    final text = SearchText.visible(entry.text);
    final raw = EntryLocations.bodyOf(entry.text);
    for (final match in _word.allMatches(text)) {
      final word = match.group(0)!;
      if (word.length < 3 || _stopWords.contains(word)) continue;
      counts.update(word, (count) => count + 1, ifAbsent: () => 1);
    }
    // Keep names capitalised the way they're written ("Iris")
    for (final match in _wordCased.allMatches(raw)) {
      final word = match.group(0)!;
      final lower = word.toLowerCase();
      if (counts.containsKey(lower) && word != lower) {
        original.putIfAbsent(lower, () => word);
      }
    }
  }
  final list = [
    for (final MapEntry(:key, :value) in counts.entries)
      MapEntry(original[key] ?? key, value),
  ];
  list.sort((a, b) => b.value.compareTo(a.value));
  return list;
}

final _word = RegExp(r"[\p{L}][\p{L}'’-]*[\p{L}]|[\p{L}]", unicode: true);
final _wordCased = RegExp(r"[\p{L}][\p{L}'’-]*[\p{L}]", unicode: true);

const _stopWords = {
  'the',
  'and',
  'for',
  'but',
  'not',
  'you',
  'your',
  'yours',
  'she',
  'her',
  'hers',
  'him',
  'his',
  'they',
  'them',
  'their',
  'our',
  'ours',
  'its',
  'was',
  'were',
  'are',
  'been',
  'being',
  'have',
  'has',
  'had',
  'having',
  'did',
  'does',
  'doing',
  'done',
  'can',
  'could',
  'will',
  'would',
  'shall',
  'should',
  'may',
  'might',
  'must',
  'this',
  'that',
  'these',
  'those',
  'there',
  'here',
  'what',
  'which',
  'who',
  'whom',
  'whose',
  'when',
  'where',
  'why',
  'how',
  'all',
  'any',
  'both',
  'each',
  'few',
  'more',
  'most',
  'other',
  'some',
  'such',
  'only',
  'own',
  'same',
  'than',
  'too',
  'very',
  'just',
  'also',
  'into',
  'onto',
  'with',
  'without',
  'from',
  'about',
  'above',
  'below',
  'over',
  'under',
  'again',
  'then',
  'once',
  'out',
  'off',
  'because',
  'while',
  'until',
  'after',
  'before',
  'during',
  'through',
  'between',
  'against',
  'myself',
  'yourself',
  'himself',
  'herself',
  'itself',
  'ourselves',
  'themselves',
  'get',
  'got',
  'gets',
  'getting',
  'really',
  'still',
  'even',
  'like',
  'lot',
  'lots',
  'one',
  'two',
  'yet',
  'now',
  "i'm",
  "it's",
  "don't",
  "didn't",
  "can't",
  "i've",
  "i'll",
  "i'd",
  "that's",
  "there's",
  "wasn't",
  "isn't",
  "won't",
  "doesn't",
  "couldn't",
  "wouldn't",
  'im',
  'dont',
  'didnt',
  'cant',
  'ive',
  'thats',
  'theres',
  'went',
  'go',
  'goes',
  'going',
  'make',
  'made',
  'say',
  'said',
  'much',
  'many',
  'every',
  'well',
  'back',
  'way',
  'yeah',
  'ang',
  'mga',
  'ako',
  'ikaw',
  'siya',
  'sila',
  'kami',
  'tayo',
  'kayo',
  'niya',
  'nila',
  'namin',
  'natin',
  'ninyo',
  'nyo',
  'mo',
  'ko',
  'ka',
  'ito',
  'iyan',
  'iyon',
  'yan',
  'yun',
  'yung',
  'yong',
  'dito',
  'diyan',
  'doon',
  'dun',
  'nang',
  'para',
  'pero',
  'kasi',
  'dahil',
  'kung',
  'kapag',
  'pag',
  'din',
  'rin',
  'lang',
  'lamang',
  'naman',
  'pa',
  'na',
  'ng',
  'sa',
  'si',
  'ni',
  'kay',
  'kina',
  'sina',
  'nina',
  'mayroon',
  'meron',
  'wala',
  'hindi',
  'oo',
  'opo',
  'ba',
  'po',
  'ho',
  'nga',
  'kaya',
  'talaga',
  'sobrang',
  'sobra',
  'masyado',
  'ano',
  'sino',
  'saan',
  'kailan',
  'bakit',
  'paano',
  'ayun',
  'ayan',
  'tapos',
  'pagkatapos',
  'habang',
  'sana',
  'baka',
  'siguro',
  'parang',
  'ganun',
  'ganito',
  'ganyan',
  'akin',
  'iyo',
  'kanya',
  'atin',
  'amin',
  'inyo',
  'kanila',
  'ngayon',
  'mag',
  'nag',
  'sya',
  'nya',
  'kasama',
  'lahat',
  'isa',
  'dalawa',
  'pang',
  'pala',
  'muna',
  'ulit',
  'tsaka',
  'saka',
  'at',
};

/// Opens [day]: its entry, or its Timeline when it has several.
Future<void> openDay(BuildContext context, DateTime day) async {
  final all = EntriesProvider.instance.entries;
  final onDay =
      all.where((entry) => TimeManager.isSameDay(entry.timeCreate, day));
  if (onDay.length == 1) return openEntry(context, onDay.first);
  if (onDay.isEmpty) return;
  await EntryTimelinePage.pushForDay(context, day);
}

/// Opens one entry, swipeable through the rest like from the calendar.
Future<void> openEntry(BuildContext context, Entry entry) async {
  final index = EntriesProvider.instance.getIndexOfEntry(entry.id!);
  if (index < 0) return;
  await Navigator.of(context).push(MaterialPageRoute(
    allowSnapshotting: false,
    builder: (_) => EntriesListPage(
        index: index, getEntries: () => EntriesProvider.instance.entries),
  ));
}
