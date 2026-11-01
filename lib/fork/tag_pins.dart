// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:material_ui/material_ui.dart';

/// A list of pinned tags, set from Settings › Tags. There are two:
/// [gallery] (the Gallery filter's Quick filters, after Favourite, Trackers
/// and Last Edited) and [addTags] (the Add Tags popup's Pinned row). Each
/// keeps its own order; a tag can be in both.
class TagPinList {
  const TagPinList._(this.setting, this.max);

  final Setting<String> setting;
  final int max;

  static const gallery = TagPinList._(Settings.quickFilterPins, 3);
  static const addTags = TagPinList._(Settings.addTagsPins, 6);

  static const all = [gallery, addTags];

  /// Pinned tag ids in their saved order, skipping deleted tags.
  List<int> get ids {
    final live = {
      for (final tag in TagsProvider.instance.tags)
        if (!Favourites.isFavouriteTag(tag)) tag.id,
    };
    try {
      final raw = jsonDecode(ConfigProvider.instance.get(setting)) as List;
      return [
        for (final id in raw)
          if (id is int && live.contains(id)) id,
      ];
    } catch (_) {
      return [];
    }
  }

  List<Tag> get tags {
    final byId = {for (final tag in TagsProvider.instance.tags) tag.id: tag};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  bool contains(int tagId) => ids.contains(tagId);

  int get free => (max - ids.length).clamp(0, max);

  Future<void> _save(List<int> ids) =>
      ConfigProvider.instance.set(setting, jsonEncode(ids));

  /// Pins as many of [tagIds] as there's room for. Returns how many were
  /// pinned and how many didn't fit.
  Future<(int, int)> pin(Iterable<int> tagIds) async {
    final pins = ids;
    var added = 0;
    var skipped = 0;
    for (final id in tagIds) {
      if (pins.contains(id)) continue;
      if (pins.length >= max) {
        skipped++;
        continue;
      }
      pins.add(id);
      added++;
    }
    await _save(pins);
    return (added, skipped);
  }

  Future<void> unpin(Iterable<int> tagIds) async {
    final remove = tagIds.toSet();
    await _save(ids.where((id) => !remove.contains(id)).toList());
  }

  /// Moves the pin at [from] to [to] (onReorderItem indexes, where [to]
  /// already allows for the removed item).
  Future<void> move(int from, int to) async {
    final pins = ids;
    if (from < 0 || from >= pins.length) return;
    final id = pins.removeAt(from);
    pins.insert(to.clamp(0, pins.length), id);
    await _save(pins);
  }

  /// Takes deleted tags out of both lists.
  static Future<void> forget(Iterable<int> tagIds) async {
    final remove = tagIds.toSet();
    for (final list in all) {
      try {
        final raw =
            jsonDecode(ConfigProvider.instance.get(list.setting)) as List;
        if (!raw.any(remove.contains)) continue;
        await list._save([
          for (final id in raw)
            if (id is int && !remove.contains(id)) id,
        ]);
      } catch (_) {}
    }
  }

  static bool pinnedAnywhere(int tagId) =>
      all.any((list) => list.contains(tagId));
}

/// The Add Tags popup's Pinned row: the same outlined chips as the Gallery
/// filter's Quick filters, tinted while the tag is on the entry. Tap the
/// header to switch between names and icons only (remembered, separately
/// from the Gallery's).
class PinnedTagsSection extends StatelessWidget {
  const PinnedTagsSection({
    super.key,
    required this.tags,
    required this.onIds,
    required this.compact,
    required this.onToggleTag,
    required this.onToggleCompact,
  });

  final List<Tag> tags;
  final Set<int> onIds;
  final bool compact;
  final void Function(Tag) onToggleTag;
  final VoidCallback onToggleCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: !compact,
          child: InkWell(
            onTap: onToggleCompact,
            child: SizedBox(
              height: 36,
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: compact ? 0 : 0.25,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 6),
                  Text(l10n.pinnedTagsTitle.toUpperCase(), style: labelStyle),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              Builder(builder: (context) {
                final color = tag.resolvedColor(context,
                    fallback: theme.colorScheme.secondary);
                return QuickFilterChip(
                  label: tag.name,
                  icon: TagIconGlyph(
                    icon: tag.icon,
                    iconType: tag.iconType,
                    fallbackIcon: tag.typeIcon,
                    color: color,
                    size: 20,
                  ),
                  color: color,
                  selected: onIds.contains(tag.id),
                  compact: compact,
                  onTap: () => onToggleTag(tag),
                );
              }),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 8),
      ],
    );
  }
}
