// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/place_filter.dart';
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
/// 📍 Places, then up to [maxPins] tags pinned in Settings › Tags. Unlike tags they're
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

/// One Quick filter: an outlined pill with its own colour and icon. While
/// on it fills solid with its colour, with dark or light text to suit
/// (3.7.0.40). [compact] shows the icon only (its name on long-press).
/// [tracker] adds the # badge trackers carry elsewhere: after the name, or
/// on the icon's corner when compact. [onClear] adds an ✕ (Places).
class QuickFilterChip extends StatelessWidget {
  const QuickFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.compact,
    required this.onTap,
    this.tracker = false,
    this.onClear,
  });

  final String label;

  /// Builds the icon in the colour it should be drawn in.
  final Widget Function(Color color) icon;
  final Color color;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;
  final bool tracker;
  final VoidCallback? onClear;

  static const double height = 40;
  static const double compactWidth = 46;

  /// Text and icons drawn on a chip filled with [fill].
  static Color onFill(Color fill) =>
      ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
          ? Colors.white
          : const Color(0xFF14181C);

  Widget _trackerBadge(Color background, Color foreground, double size) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: size / 3),
        height: size,
        constraints: BoxConstraints(minWidth: size),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(Icons.numbers_rounded, size: size * 0.7, color: foreground),
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = selected ? onFill(color) : colorScheme.onSurface;
    final iconColor = selected ? ink : color;
    final shape = BoxDecoration(
      borderRadius: BorderRadius.circular(height / 2),
      border: Border.all(color: color, width: 2),
      color: selected ? color : Colors.transparent,
    );
    final Widget content;
    if (compact) {
      content = SizedBox(
        width: compactWidth - 4,
        height: height - 4,
        child: Center(child: icon(iconColor)),
      );
    } else {
      content = Padding(
        padding: EdgeInsets.only(left: 10, right: onClear != null ? 4 : 14),
        child: SizedBox(
          height: height - 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon(iconColor),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      color: ink,
                      fontWeight: selected ? FontWeight.w600 : null),
                ),
              ),
              if (tracker) ...[
                const SizedBox(width: 6),
                _trackerBadge(
                    selected
                        ? ink.withValues(alpha: 0.18)
                        : colorScheme.surfaceContainerHighest,
                    ink.withValues(alpha: 0.75),
                    18),
              ],
              if (onClear != null)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    color: ink,
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onClear,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    Widget chip = Semantics(
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
    if (compact && tracker) {
      // The # sits on the corner, in the chip's colour, ringed with the
      // background so it reads against the outline
      chip = Stack(
        clipBehavior: Clip.none,
        children: [
          chip,
          PositionedDirectional(
            end: -4,
            bottom: -4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: _trackerBadge(color, onFill(color), 17),
              ),
            ),
          ),
        ],
      );
    }
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
    this.showPlaces = false,
    this.place,
    this.onPickPlace,
    this.onClearPlace,
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

  /// 📍 Places (3.7.0.40): shown once any entry has a place. [place] is the
  /// picked one, shown in the chip with an ✕.
  final bool showPlaces;
  final String? place;
  final VoidCallback? onPickPlace;
  final VoidCallback? onClearPlace;

  Widget _tagChip(BuildContext context, Tag tag, Color fallback) {
    final color = tag.resolvedColor(context, fallback: fallback);
    final isFavourite = Favourites.isFavouriteTag(tag);
    return QuickFilterChip(
      label: isFavourite
          ? AppLocalizations.of(context)!.quickFilterFavourite
          : tag.name,
      icon: (iconColor) => TagIconGlyph(
        icon: tag.icon,
        iconType: isFavourite ? TagIconType.character : tag.iconType,
        fallbackIcon: tag.typeIcon,
        color: iconColor,
        size: 20,
      ),
      color: color,
      tracker: tag.tagType == TagType.tracker,
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
          icon: (iconColor) =>
              Icon(Icons.numbers_rounded, size: 20, color: iconColor),
          color: QuickFilters.trackersColor,
          selected: trackersOn,
          compact: compact,
          onTap: enabled ? onToggleTrackers : null,
        ),
      QuickFilterChip(
        label: l10n.quickFilterLastEdited,
        icon: (iconColor) =>
            Icon(Icons.history_rounded, size: 20, color: iconColor),
        color: QuickFilters.lastEditedColor,
        selected: lastEditedOn,
        compact: compact,
        onTap: enabled ? onToggleLastEdited : null,
      ),
      if (showPlaces || place != null)
        QuickFilterChip(
          label: place ?? l10n.quickFilterPlaces,
          icon: (iconColor) =>
              Icon(Icons.place_rounded, size: 20, color: iconColor),
          color: PlaceFilter.color,
          selected: place != null,
          compact: compact,
          onTap: enabled ? onPickPlace : null,
          onClear: place != null && !compact ? onClearPlace : null,
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
