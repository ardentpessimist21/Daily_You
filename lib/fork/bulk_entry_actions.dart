// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
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
      await _save(entry.copy(mood: mood, timeModified: DateTime.now()), tags);
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

  /// Shows label tags as on all / some / none of [entries]; tapping a tag
  /// puts it on all of them, tapping again takes it off all of them.
  /// Returns (add, remove) tag ids, or null if cancelled.
  static Future<(Set<int>, Set<int>)?> pickTags(
      BuildContext context, List<Entry> entries) {
    final provider = TagsProvider.instance;
    final labelTags =
        provider.tags.where((tag) => tag.tagType == TagType.label).toList();
    final sections = provider.buildSections('', tagPool: labelTags);

    int countWith(int tagId) => entries
        .where((entry) =>
            entry.id != null &&
            provider
                .getEntryTagsForEntry(entry.id!)
                .any((entryTag) => entryTag.tagId == tagId))
        .length;

    // null = on some (left as is), true = on all, false = on none
    final state = <int, bool?>{
      for (final tag in labelTags)
        tag.id!: switch (countWith(tag.id!)) {
          0 => false,
          final n when n == entries.length => true,
          _ => null,
        }
    };
    final initial = Map<int, bool?>.from(state);
    final l10n = AppLocalizations.of(context)!;

    return showAppDialog<(Set<int>, Set<int>)>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        final colorScheme = Theme.of(context).colorScheme;
        Widget chip(Tag tag) {
          final value = state[tag.id!];
          return FilterChip(
            label: Text(tag.name),
            selected: value == true,
            showCheckmark: value == true,
            side: value == null
                ? BorderSide(color: colorScheme.primary, width: 1.5)
                : null,
            onSelected: (_) =>
                setState(() => state[tag.id!] = value == true ? false : true),
          );
        }

        return AlertDialog(
          title: Text(l10n.bulkChangeTags),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.bulkTagsHint(entries.length)),
                  const SizedBox(height: 12),
                  if (labelTags.isEmpty) Text(l10n.bulkNoTags),
                  for (final section in sections) ...[
                    if (section.category != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(section.category!.name,
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: section.tags.map(chip).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                final add = <int>{};
                final remove = <int>{};
                state.forEach((tagId, value) {
                  if (value == initial[tagId]) return;
                  if (value == true) add.add(tagId);
                  if (value == false) remove.add(tagId);
                });
                Navigator.pop(context, (add, remove));
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      }),
    );
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
