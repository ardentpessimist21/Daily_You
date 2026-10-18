// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/tags_provider.dart';

/// Favourite entries are marked with an ordinary label tag, so they need no
/// database changes and survive backups, exports and the official app (where
/// the tag simply shows as "⭐ Favourite").
///
/// In this app the tag is kept out of the places you manage tags by hand
/// (pickers, chips, settings, statistics); it still shows as a ⭐ on entry
/// cards and can be used in the Gallery's tag filter.
class Favourites {
  static const String tagName = 'Favourite';
  static const String tagIcon = '⭐';

  static bool isFavouriteTag(Tag tag) =>
      tag.tagType == TagType.label &&
      tag.name == tagName &&
      tag.icon == tagIcon;

  static Tag? get tag =>
      TagsProvider.instance.tags.where(isFavouriteTag).firstOrNull;

  static EntryTag? _entryTagFor(int entryId) {
    final favourite = tag;
    if (favourite == null) return null;
    return TagsProvider.instance
        .getEntryTagsForEntry(entryId)
        .where((entryTag) => entryTag.tagId == favourite.id)
        .firstOrNull;
  }

  static bool isFavourite(int entryId) => _entryTagFor(entryId) != null;

  /// Stars or unstars an entry, creating the tag the first time it's needed.
  /// Returns whether the entry is now a favourite.
  static Future<bool> toggle(int entryId) async {
    final existing = _entryTagFor(entryId);
    if (existing != null) {
      await TagsProvider.instance.removeEntryTag(existing);
      return false;
    }

    var favourite = tag;
    if (favourite == null) {
      final now = DateTime.now();
      await TagsProvider.instance.add(Tag(
        name: tagName,
        icon: tagIcon,
        iconType: TagIconType.character,
        tagType: TagType.label,
        timeCreate: now,
        timeModified: now,
      ));
      favourite = tag;
      if (favourite == null) return false;
    }

    await TagsProvider.instance.addEntryTag(EntryTag(
      entryId: entryId,
      tagId: favourite.id!,
      timeCreate: DateTime.now(),
    ));
    return true;
  }
}
