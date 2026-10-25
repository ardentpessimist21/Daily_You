// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';

/// Settings › Tags helpers: search matching and moving several tags at once.
class TagBulkMove {
  /// A copy of [tag] in [categoryId] (null = Uncategorized) at [sortOrder].
  /// Built directly so a null category is kept.
  static Tag withCategory(Tag tag, int? categoryId, int sortOrder,
          {DateTime? now}) =>
      Tag(
        id: tag.id,
        name: tag.name,
        color: tag.color,
        tagType: tag.tagType,
        icon: tag.icon,
        iconType: tag.iconType,
        categoryId: categoryId,
        sortOrder: sortOrder,
        timeCreate: tag.timeCreate,
        timeModified: tag.categoryId == categoryId
            ? tag.timeModified
            : (now ?? DateTime.now()),
      );

  /// The updates that put [selectedIds] at the end of [targetCategoryId],
  /// keeping their current order. Tags already there stay where they are, and
  /// ⭐ Favourite is never moved.
  static List<Tag> plan(
      List<Tag> tags, Set<int> selectedIds, int? targetCategoryId,
      {DateTime? now}) {
    final moving = tags
        .where((tag) =>
            selectedIds.contains(tag.id) &&
            tag.categoryId != targetCategoryId &&
            !Favourites.isFavouriteTag(tag))
        .toList()
      ..sort((a, b) {
        final byCategory = (a.categoryId ?? -1).compareTo(b.categoryId ?? -1);
        if (byCategory != 0) return byCategory;
        return a.sortOrder.compareTo(b.sortOrder);
      });
    if (moving.isEmpty) return const [];

    var next = 0;
    for (final tag in tags) {
      if (tag.categoryId == targetCategoryId && tag.sortOrder >= next) {
        next = tag.sortOrder + 1;
      }
    }
    return [
      for (final tag in moving)
        withCategory(tag, targetCategoryId, next++, now: now),
    ];
  }

  /// Whether [tag] matches a Settings › Tags search: by its name or its
  /// category's name.
  static bool matches(Tag tag, String query, List<TagCategory> categories) {
    final search = query.trim().toLowerCase();
    if (search.isEmpty) return true;
    if (tag.name.toLowerCase().contains(search)) return true;
    final category =
        categories.where((c) => c.id == tag.categoryId).firstOrNull;
    return category != null && category.name.toLowerCase().contains(search);
  }
}
