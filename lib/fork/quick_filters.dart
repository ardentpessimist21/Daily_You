// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/tag_pins.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:material_ui/material_ui.dart';

/// The Gallery filter's Quick filters: ⭐ Favourite, Trackers, Last Edited,
/// then up to [maxPins] tags pinned in Settings › Tags. Unlike tags they're
/// switches: tapping one tints it in place. Favourite, Last Edited and the
/// pinned tags narrow the Gallery (each one that's on must match, and they
/// combine with the tag filter); Trackers only switches the popup's list to
/// your trackers.
class QuickFilters {
  static int get maxPins => TagPinList.gallery.max;

  static const Color trackersColor = Color(0xFF2BB3A3);
  static const Color lastEditedColor = Color(0xFFE8963A);
  static const Color favouriteFallback = Color(0xFF4A90E2);

  /// Pinned tag ids, in their saved order, skipping deleted tags.
  static List<int> get pinnedIds => TagPinList.gallery.ids;

  static bool isPinned(int tagId) => TagPinList.gallery.contains(tagId);

  static Future<(int, int)> pin(Iterable<int> tagIds) =>
      TagPinList.gallery.pin(tagIds);

  static Future<void> unpin(Iterable<int> tagIds) =>
      TagPinList.gallery.unpin(tagIds);

  static bool get compact =>
      ConfigProvider.instance.get(Settings.quickFiltersCompact);

  static Future<void> setCompact(bool value) =>
      ConfigProvider.instance.set(Settings.quickFiltersCompact, value);

  /// [entries] narrowed by the quick filters that are on: every tag in
  /// [tagIds] (Favourite or pinned) must be on the entry, and with
  /// [lastEdited] only entries whose text changed on a later day are kept,
  /// listed by when they were last edited.
  static List<Entry> apply(List<Entry> entries,
      {required Set<int> tagIds,
      required bool lastEdited,
      required bool ascending}) {
    var result = entries;
    if (tagIds.isNotEmpty) {
      result = result.where((entry) {
        final onEntry = TagsProvider.instance
            .getEntryTagsForEntry(entry.id ?? -1)
            .map((entryTag) => entryTag.tagId)
            .toSet();
        return tagIds.every(onEntry.contains);
      }).toList();
    }
    if (lastEdited) {
      result = result.where(editedLater).toList()
        ..sort((a, b) => ascending
            ? a.timeModified.compareTo(b.timeModified)
            : b.timeModified.compareTo(a.timeModified));
    }
    return result;
  }

  /// Whether [entry]'s text was changed on a later day than it was written.
  /// Same-day edits don't count.
  static bool editedLater(Entry entry) {
    final created = DateUtils.dateOnly(entry.timeCreate);
    final modified = DateUtils.dateOnly(entry.timeModified);
    return modified.isAfter(created);
  }
}

/// One Quick filter: an outlined pill with its own colour and icon, tinted
/// while on. [compact] shows the icon only (its name on long-press).
class QuickFilterChip extends StatelessWidget {
  const QuickFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final Color color;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  static const double height = 40;
  static const double compactWidth = 46;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shape = BoxDecoration(
      borderRadius: BorderRadius.circular(height / 2),
      border: Border.all(color: color, width: 2),
      color: selected ? color.withValues(alpha: 0.28) : Colors.transparent,
    );
    final content = compact
        ? SizedBox(
            width: compactWidth - 4,
            height: height - 4,
            child: Center(child: icon),
          )
        : Padding(
            padding: const EdgeInsets.only(left: 10, right: 14),
            child: SizedBox(
              height: height - 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 15, color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          );
    final chip = Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: compact,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: onTap,
          child: DecoratedBox(decoration: shape, child: content),
        ),
      ),
    );
    return compact ? Tooltip(message: label, child: chip) : chip;
  }
}

/// The QUICK FILTERS header (tap to switch between names and icons only)
/// and its chips, for the Gallery filter popup.
class QuickFiltersSection extends StatelessWidget {
  const QuickFiltersSection({
    super.key,
    required this.favourite,
    required this.showTrackers,
    required this.pinned,
    required this.activeTagIds,
    required this.trackersOn,
    required this.lastEditedOn,
    required this.compact,
    required this.enabled,
    required this.onToggleTag,
    required this.onToggleTrackers,
    required this.onToggleLastEdited,
    required this.onToggleCompact,
  });

  final Tag? favourite;
  final bool showTrackers;
  final List<Tag> pinned;
  final Set<int> activeTagIds;
  final bool trackersOn;
  final bool lastEditedOn;
  final bool compact;
  final bool enabled;
  final void Function(Tag) onToggleTag;
  final VoidCallback onToggleTrackers;
  final VoidCallback onToggleLastEdited;
  final VoidCallback onToggleCompact;

  Widget _tagChip(BuildContext context, Tag tag, Color fallback) {
    final color = tag.resolvedColor(context, fallback: fallback);
    final isFavourite = Favourites.isFavouriteTag(tag);
    return QuickFilterChip(
      label: isFavourite
          ? AppLocalizations.of(context)!.quickFilterFavourite
          : tag.name,
      icon: TagIconGlyph(
        icon: tag.icon,
        iconType: isFavourite ? TagIconType.character : tag.iconType,
        fallbackIcon: tag.typeIcon,
        color: color,
        size: 20,
      ),
      color: color,
      selected: activeTagIds.contains(tag.id),
      compact: compact,
      onTap: enabled ? () => onToggleTag(tag) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    final chips = <Widget>[
      if (favourite != null)
        _tagChip(context, favourite!, QuickFilters.favouriteFallback),
      if (showTrackers)
        QuickFilterChip(
          label: l10n.tagFilterTrackers,
          icon: const Icon(Icons.numbers_rounded,
              size: 20, color: QuickFilters.trackersColor),
          color: QuickFilters.trackersColor,
          selected: trackersOn,
          compact: compact,
          onTap: enabled ? onToggleTrackers : null,
        ),
      QuickFilterChip(
        label: l10n.quickFilterLastEdited,
        icon: const Icon(Icons.history_rounded,
            size: 20, color: QuickFilters.lastEditedColor),
        color: QuickFilters.lastEditedColor,
        selected: lastEditedOn,
        compact: compact,
        onTap: enabled ? onToggleLastEdited : null,
      ),
      for (final tag in pinned)
        _tagChip(context, tag, theme.colorScheme.secondary),
    ];

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
                  Text(l10n.quickFiltersTitle.toUpperCase(), style: labelStyle),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: 8,
          children: chips,
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 8),
      ],
    );
  }
}
