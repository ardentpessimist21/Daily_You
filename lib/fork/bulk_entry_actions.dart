// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:material_ui/material_ui.dart';

/// Changes to many entries at once, used by the timeline's select mode.
///
/// Every save passes each entry's existing tags and attachments back
/// unchanged, so only the intended field changes.
class BulkEntryActions {
  static Future<void> _save(Entry entry, List<EntryTag> tags) async {
    final attachments = EntryAttachmentsProvider.instance.getForEntry(entry);
    await EntryStore.instance.beginDraft().save((_) => EntryDraft(
          entry: entry,
          tags: tags,
          attachments: attachments,
        ));
  }

  static Future<void> setMood(List<Entry> entries, int? mood) async {
    for (final entry in entries) {
      if (entry.id == null || entry.mood == mood) continue;
      final tags = TagsProvider.instance.getEntryTagsForEntry(entry.id!);
      // Mood changes keep "Last modified", which follows text edits only
      await _save(entry.copy(mood: mood), tags);
    }
  }

  /// Adds [add] tags to, and removes [remove] tags from, every entry.
  static Future<void> changeTags(
      List<Entry> entries, Set<int> add, Set<int> remove) async {
    for (final entry in entries) {
      if (entry.id == null) continue;
      final current = TagsProvider.instance.getEntryTagsForEntry(entry.id!);
      final currentIds = current.map((entryTag) => entryTag.tagId).toSet();
      final toAdd = add.difference(currentIds);
      final toRemove = remove.intersection(currentIds);
      if (toAdd.isEmpty && toRemove.isEmpty) continue;
      final desired = [
        for (final entryTag in current)
          if (!toRemove.contains(entryTag.tagId)) entryTag,
        for (final tagId in toAdd)
          EntryTag(
              entryId: entry.id!, tagId: tagId, timeCreate: DateTime.now()),
      ];
      await _save(entry, desired);
    }
  }

  static Future<void> delete(List<Entry> entries) async {
    for (final entry in entries) {
      if (entry.id != null) await EntryStore.instance.delete(entry);
    }
  }

  /// Returns the chosen mood wrapped in a record, null if cancelled (the
  /// mood itself can be null, meaning "no mood").
  static Future<({int? mood})?> pickMood(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context)!;
    return showAppDialog<({int? mood})>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bulkChangeMood),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.bulkForEntries(count)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final mood in [-2, -1, 0, 1, 2])
                  IconButton.filledTonal(
                    iconSize: 30,
                    onPressed: () => Navigator.pop(context, (mood: mood)),
                    icon: MoodIcon(moodValue: mood, size: 28),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, (mood: null)),
            child: Text(l10n.bulkNoMood),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
  }

  /// Opens the app's own "Add tags" picker for several entries at once.
  /// Tags on every selected entry start attached; tapping a tag puts it on
  /// all of them, and ✕ takes it off all of them. Tags on only some entries
  /// are listed in a note and left alone unless you add or remove them.
  /// Returns (add, remove) tag ids.
  static Future<(Set<int>, Set<int>)> pickTags(
      BuildContext context, List<Entry> entries) async {
    final provider = TagsProvider.instance;
    final labelTags =
        provider.tags.where((tag) => tag.tagType == TagType.label).toList();

    int countWith(int tagId) => entries
        .where((entry) =>
            entry.id != null &&
            provider
                .getEntryTagsForEntry(entry.id!)
                .any((entryTag) => entryTag.tagId == tagId))
        .length;

    final onAll = <int>{};
    final onSome = <Tag>[];
    for (final tag in labelTags) {
      final count = countWith(tag.id!);
      if (count == entries.length) {
        onAll.add(tag.id!);
      } else if (count > 0) {
        onSome.add(tag);
      }
    }

    final source = TagAttachmentSource(initialTagIds: onAll.toList());
    // Anything attached during this session, so "add then ✕" on a tag that
    // was on only some entries removes it from all of them
    final touched = <int>{...onAll};
    void track() => touched.addAll(source.attachedTagIds);
    source.addListener(track);

    final l10n = AppLocalizations.of(context)!;
    final visibleSome =
        onSome.where((tag) => !Favourites.isFavouriteTag(tag)).toList();
    await showAppDialog<void>(
      context: context,
      builder: (_) => TagPickerDialog(
        mode: TagPickerMode.attach,
        source: source,
        tagTypeFilter: TagType.label,
        note: visibleSome.isEmpty
            ? null
            : l10n.bulkTagsOnSome(
                entries.length, visibleSome.map((tag) => tag.name).join(', ')),
      ),
    );
    source.removeListener(track);

    final finalIds = source.attachedTagIds.toSet();
    return (finalIds.difference(onAll), touched.difference(finalIds));
  }

  static Future<bool> confirmDelete(BuildContext context, int count) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bulkDeleteTitle(count)),
        content: Text(l10n.bulkDeleteDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
