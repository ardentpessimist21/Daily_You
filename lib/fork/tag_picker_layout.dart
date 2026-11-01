// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';

/// How often a tag was used in the recent window, and when it was last used.
class TagUsage {
  final int recentCount;
  final DateTime? lastUsed;

  const TagUsage(this.recentCount, this.lastUsed);

  static const none = TagUsage(0, null);
}

/// One collapsible group in the tag picker. [category] null = Uncategorized.
class TagPickerGroup {
  final TagCategory? category;
  final List<Tag> tags;

  const TagPickerGroup(this.category, this.tags);
}

class TagPickerContent {
  /// ⭐ Favourite, pinned at the top (Gallery filter only).
  final Tag? pinnedFavourite;

  /// Most used tags in the window. Empty while searching.
  final List<Tag> frequent;

  /// Named categories in Settings order, then Uncategorized last.
  final List<TagPickerGroup> groups;

  const TagPickerContent({
    required this.pinnedFavourite,
    required this.frequent,
    required this.groups,
  });

  bool get isEmpty =>
      pinnedFavourite == null && frequent.isEmpty && groups.isEmpty;
}

/// How tags are ordered inside each group of the Add Tags popup.
enum TagSortMode {
  /// Last used first
  recent,

  /// Most used in the window first (the default)
  usage,

  /// The order set in Settings › Tags
  manual;

  static TagSortMode fromKey(String key) =>
      values.where((mode) => mode.name == key).firstOrNull ?? usage;
}

/// Layout rules for the Add Tags / Filter Tags / pick-a-tag popup:
/// - Frequent: the top [frequentLimit] tags used in the last [windowDays].
/// - Categories keep the order you set in Settings; Uncategorized goes last.
/// - Inside each group, tags used most in the window come first, then the
///   most recently used, then your Settings order.
/// - Searching hides Frequent; the picker opens every group that matches.
class TagPickerLayout {
  static const int windowDays = 60;
  static const int frequentLimit = 6;

  /// Usage per tag id. [entryDates] maps entry id to the entry's own date, so
  /// back-dated and imported entries count by when they happened; tags on an
  /// entry not in the map fall back to when the tag was added.
  static Map<int, TagUsage> usage(
    Iterable<EntryTag> entryTags,
    Map<int, DateTime> entryDates,
    DateTime now,
  ) {
    final windowStart = now.subtract(const Duration(days: windowDays));
    final counts = <int, int>{};
    final last = <int, DateTime>{};
    for (final entryTag in entryTags) {
      final when = entryDates[entryTag.entryId] ?? entryTag.timeCreate;
      final previous = last[entryTag.tagId];
      if (previous == null || when.isAfter(previous)) {
        last[entryTag.tagId] = when;
      }
      if (!when.isBefore(windowStart) && !when.isAfter(now)) {
        counts[entryTag.tagId] = (counts[entryTag.tagId] ?? 0) + 1;
      }
    }
    return {
      for (final id in {...counts.keys, ...last.keys})
        id: TagUsage(counts[id] ?? 0, last[id]),
    };
  }

  static int compareByUsage(Tag a, Tag b, Map<int, TagUsage> usage) {
    final usageA = usage[a.id] ?? TagUsage.none;
    final usageB = usage[b.id] ?? TagUsage.none;
    final byCount = usageB.recentCount.compareTo(usageA.recentCount);
    if (byCount != 0) return byCount;
    final lastA = usageA.lastUsed;
    final lastB = usageB.lastUsed;
    if (lastA != null && lastB != null) {
      final byLast = lastB.compareTo(lastA);
      if (byLast != 0) return byLast;
    } else if (lastA != null) {
      return -1;
    } else if (lastB != null) {
      return 1;
    }
    final bySettings = a.sortOrder.compareTo(b.sortOrder);
    if (bySettings != 0) return bySettings;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  static int compareByRecent(Tag a, Tag b, Map<int, TagUsage> usage) {
    final lastA = usage[a.id]?.lastUsed;
    final lastB = usage[b.id]?.lastUsed;
    if (lastA != null && lastB != null) {
      final byLast = lastB.compareTo(lastA);
      if (byLast != 0) return byLast;
    } else if (lastA != null) {
      return -1;
    } else if (lastB != null) {
      return 1;
    }
    return compareBySettings(a, b);
  }

  static int compareBySettings(Tag a, Tag b) {
    final bySettings = a.sortOrder.compareTo(b.sortOrder);
    if (bySettings != 0) return bySettings;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  static TagPickerContent build({
    required List<Tag> pool,
    required List<TagCategory> categories,
    required Map<int, TagUsage> usage,
    String query = '',
    bool pinFavourite = false,
    TagSortMode sortMode = TagSortMode.usage,
  }) {
    final search = query.trim().toLowerCase();
    final categoryById = {for (final c in categories) c.id: c};

    bool matches(Tag tag) {
      if (search.isEmpty) return true;
      if (tag.name.toLowerCase().contains(search)) return true;
      final category = categoryById[tag.categoryId];
      return category != null && category.name.toLowerCase().contains(search);
    }

    Tag? favourite;
    final tags = <Tag>[];
    for (final tag in pool) {
      if (Favourites.isFavouriteTag(tag)) {
        if (pinFavourite && matches(tag)) favourite ??= tag;
        continue;
      }
      if (matches(tag)) tags.add(tag);
    }

    // Frequent is always by usage; the sort choice orders the groups
    int byUsage(Tag a, Tag b) => compareByUsage(a, b, usage);
    int sorter(Tag a, Tag b) => switch (sortMode) {
          TagSortMode.recent => compareByRecent(a, b, usage),
          TagSortMode.usage => compareByUsage(a, b, usage),
          TagSortMode.manual => compareBySettings(a, b),
        };

    final frequent = search.isNotEmpty
        ? <Tag>[]
        : (tags.where((tag) => (usage[tag.id]?.recentCount ?? 0) > 0).toList()
              ..sort(byUsage))
            .take(frequentLimit)
            .toList();

    final groups = <TagPickerGroup>[];
    for (final category in categories) {
      final inCategory = tags
          .where((tag) => tag.categoryId == category.id)
          .toList()
        ..sort(sorter);
      if (inCategory.isNotEmpty) {
        groups.add(TagPickerGroup(category, inCategory));
      }
    }
    // Tags whose category no longer exists are treated as uncategorized
    final uncategorized = tags
        .where((tag) =>
            tag.categoryId == null || !categoryById.containsKey(tag.categoryId))
        .toList()
      ..sort(sorter);
    if (uncategorized.isNotEmpty) {
      groups.add(TagPickerGroup(null, uncategorized));
    }

    return TagPickerContent(
      pinnedFavourite: favourite,
      frequent: frequent,
      groups: groups,
    );
  }
}
