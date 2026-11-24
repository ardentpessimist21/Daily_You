// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/moods.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:material_ui/material_ui.dart';

/// The Gallery's filter pill row (3.7.0.64): Favourite, Last Edited, Date,
/// Mood, Media, Places, Trackers, Tags and Keywords, under the search bar.
/// Favourite and Last Edited switch on with a tap; the others open a
/// picker. Pills that are on move to the front. The ‹ button folds the row
/// into icons only (remembered); › brings the names back.

/// Keywords (3.7.0.64, like upstream 3.11.0): several words, all or any of
/// them, optionally matching case. No Text keeps only entries without text.
@immutable
class KeywordFilter {
  const KeywordFilter({
    this.words = const [],
    this.all = true,
    this.matchCase = false,
    this.noText = false,
  });

  final List<String> words;
  final bool all;
  final bool matchCase;
  final bool noText;

  bool get isOn => noText || words.isNotEmpty;

  /// How many things are picked, for the pill's count.
  int get count => noText ? 1 : words.length;

  KeywordFilter copyWith(
          {List<String>? words, bool? all, bool? matchCase, bool? noText}) =>
      KeywordFilter(
        words: words ?? this.words,
        all: all ?? this.all,
        matchCase: matchCase ?? this.matchCase,
        noText: noText ?? this.noText,
      );

  List<Entry> apply(List<Entry> entries) {
    if (noText) {
      return entries.where((entry) => entry.text.trim().isEmpty).toList();
    }
    if (words.isEmpty) return entries;
    final wanted =
        matchCase ? words : [for (final word in words) word.toLowerCase()];
    return entries.where((entry) {
      final text = matchCase ? entry.text : entry.text.toLowerCase();
      return all ? wanted.every(text.contains) : wanted.any(text.contains);
    }).toList();
  }
}

/// Mood (3.7.0.64): several moods at once; null stands for No mood.
class MoodFilter {
  MoodFilter._();

  static List<Entry> apply(List<Entry> entries, Set<int?> moods) {
    if (moods.isEmpty) return entries;
    return entries.where((entry) => moods.contains(entry.mood)).toList();
  }
}

/// Trackers (3.7.0.64): entries that have any of the picked trackers.
class TrackerFilter {
  TrackerFilter._();

  static List<Tag> get trackers => TagsProvider.instance.tags
      .where((tag) => tag.tagType == TagType.tracker)
      .toList();

  static List<Entry> apply(List<Entry> entries, Set<int> tagIds) {
    if (tagIds.isEmpty) return entries;
    return entries.where((entry) {
      return TagsProvider.instance
          .getEntryTagsForEntry(entry.id ?? -1)
          .any((entryTag) => tagIds.contains(entryTag.tagId));
    }).toList();
  }
}

/// One pill of the row.
class GalleryPillSpec {
  const GalleryPillSpec({
    required this.id,
    required this.name,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.opensPicker = false,
    this.count = 0,
    this.activeIconColor,
  });

  final String id;

  /// The filter's name, shown on long-press when folded.
  final String name;

  /// What the pill says: its name, or what's picked while on.
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  /// Shows ▾: tapping opens a picker rather than switching it on.
  final bool opensPicker;

  /// More than one picked: shown as a dot on the folded icon.
  final int count;

  /// The icon's colour while on (⭐ stays gold).
  final Color? activeIconColor;
}

class GalleryFilterRow extends StatelessWidget {
  const GalleryFilterRow({
    super.key,
    required this.pills,
    required this.compact,
    required this.onToggleCompact,
  });

  static const double height = 46;
  static const double _pillHeight = 36;
  static const double _iconSize = 34;

  /// Whether the row shows icons only.
  static bool get savedCompact =>
      ConfigProvider.instance.get(Settings.galleryFilterIconsOnly);

  static Future<void> saveCompact(bool value) =>
      ConfigProvider.instance.set(Settings.galleryFilterIconsOnly, value);

  /// In the given order, with the ones that are on moved to the front.
  final List<GalleryPillSpec> pills;
  final bool compact;
  final VoidCallback onToggleCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final ordered = [
      ...pills.where((pill) => pill.active),
      ...pills.where((pill) => !pill.active),
    ];
    final fold = SizedBox(
      width: _iconSize,
      height: _iconSize,
      child: IconButton(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHigh),
        tooltip: compact ? l10n.galleryFiltersUnfold : l10n.galleryFiltersFold,
        iconSize: 20,
        icon: Icon(
            compact ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
        onPressed: onToggleCompact,
      ),
    );

    final Widget body;
    if (compact) {
      body = LayoutBuilder(builder: (context, constraints) {
        final icons = [
          for (final pill in ordered)
            _IconPill(key: ValueKey('gallery-icon-${pill.id}'), pill: pill),
        ];
        final needed = icons.length * _iconSize + (icons.length - 1) * 4;
        if (needed <= constraints.maxWidth) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: icons,
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < icons.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              icons[i],
            ],
          ]),
        );
      });
    } else {
      body = ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.9, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 24),
          child: Row(children: [
            for (var i = 0; i < ordered.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _FullPill(
                  key: ValueKey('gallery-pill-${ordered[i].id}'),
                  pill: ordered[i]),
            ],
          ]),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
        child: Row(
          children: [
            fold,
            const SizedBox(width: 6),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _FullPill extends StatelessWidget {
  const _FullPill({super.key, required this.pill});

  final GalleryPillSpec pill;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final on = pill.active;
    final foreground =
        on ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? colorScheme.primaryContainer : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
              color: on ? colorScheme.primaryContainer : colorScheme.outline),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: pill.onTap,
          child: SizedBox(
            height: GalleryFilterRow._pillHeight,
            child: Padding(
              padding:
                  EdgeInsets.only(left: 10, right: pill.opensPicker ? 6 : 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(pill.icon,
                      size: 17,
                      color: on
                          ? pill.activeIconColor ?? foreground
                          : colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      pill.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          color: foreground,
                          fontWeight: on ? FontWeight.w600 : null),
                    ),
                  ),
                  if (pill.opensPicker)
                    Icon(Icons.arrow_drop_down_rounded,
                        size: 20, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({super.key, required this.pill});

  final GalleryPillSpec pill;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final on = pill.active;
    const size = GalleryFilterRow._iconSize;
    final circle = Semantics(
      button: true,
      selected: on,
      label: pill.name,
      excludeSemantics: true,
      child: Material(
        color: on ? colorScheme.primaryContainer : Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(
              color: on ? colorScheme.primaryContainer : colorScheme.outline),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: pill.onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(pill.icon,
                size: 17,
                color: on
                    ? pill.activeIconColor ?? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
    final showCount = on && pill.count > 1;
    return Tooltip(
      message: pill.name,
      triggerMode: TooltipTriggerMode.longPress,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            circle,
            if (showCount)
              Positioned(
                top: -3,
                right: -3,
                child: IgnorePointer(
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 15, minHeight: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('${pill.count}',
                        style: TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimary)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- Pickers ---------------------------------------------------------------

/// A filter picker (Mood, Media, Trackers, Keywords): its choices apply as
/// they're tapped. The bottom button counts the logs left ("Show 14 Logs");
/// with none left it reads No Logs Match, with Clear all beside it.
Future<void> showGalleryFilterPicker(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context, VoidCallback refresh) body,
  required int Function() count,
  required VoidCallback onClearAll,
}) {
  return showAppDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;
        final left = count();
        return AlertDialog(
          title: Text(title),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: body(context, () => setState(() {})),
            ),
          ),
          actions: [
            if (left == 0)
              TextButton(
                key: const ValueKey('filter-clear-all'),
                onPressed: () {
                  onClearAll();
                  setState(() {});
                },
                child: Text(l10n.clearAllFilters),
              ),
            GalleryShowLogsButton(
                count: left, onPressed: () => Navigator.pop(dialogContext)),
          ],
        );
      },
    ),
  );
}

/// "Show 14 Logs", or "No Logs Match" when nothing is left.
class GalleryShowLogsButton extends StatelessWidget {
  const GalleryShowLogsButton(
      {super.key, required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (count == 0) {
      return TextButton(
        key: const ValueKey('filter-no-match'),
        onPressed: onPressed,
        child: Text(l10n.galleryNoLogsMatch),
      );
    }
    return FilledButton.tonal(
      key: const ValueKey('filter-show-logs'),
      onPressed: onPressed,
      child: Text(l10n.galleryShowLogs(count)),
    );
  }
}

/// A row with a leading widget, a name and a tick, for the pickers.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                const SizedBox(width: 12),
                SizedBox(width: 28, child: Center(child: leading)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          fontWeight: selected ? FontWeight.w600 : null)),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: selected ? 1 : 0,
                  child: Icon(Icons.check_rounded,
                      size: 20, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mood: the five moods and No mood; several can be picked.
Widget moodFilterBody(BuildContext context,
    {required Set<int?> moods,
    required void Function(Set<int?>) onChanged,
    required VoidCallback refresh}) {
  final l10n = AppLocalizations.of(context)!;
  void toggle(int? mood) {
    final next = {...moods};
    if (!next.remove(mood)) next.add(mood);
    onChanged(next);
    refresh();
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final mood in Moods.values)
        _PickRow(
          leading: MoodIcon(moodValue: mood, size: 22),
          label: Moods.nameOf(mood),
          selected: moods.contains(mood),
          onTap: () => toggle(mood),
        ),
      _PickRow(
        leading: Icon(Icons.sentiment_neutral_outlined,
            size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
        label: l10n.galleryFilterNoMood,
        selected: moods.contains(null),
        onTap: () => toggle(null),
      ),
    ],
  );
}

/// Media: Photos, Audio, Video (combine), Any media, No media (alone).
Widget mediaFilterBody(BuildContext context,
    {required Set<MediaFilter> media,
    required void Function(Set<MediaFilter>) onChanged,
    required VoidCallback refresh}) {
  final l10n = AppLocalizations.of(context)!;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final filter in MediaFilter.values)
        _PickRow(
          leading: Icon(filter.icon, size: 22, color: filter.color),
          label: filter.label(l10n),
          selected: media.contains(filter),
          onTap: () {
            onChanged(MediaFilter.toggle(media, filter));
            refresh();
          },
        ),
    ],
  );
}

/// Trackers: every tracker tag; entries with any picked one show.
Widget trackerFilterBody(BuildContext context,
    {required Set<int> tagIds,
    required void Function(Set<int>) onChanged,
    required VoidCallback refresh}) {
  final l10n = AppLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  final trackers = TrackerFilter.trackers;
  if (trackers.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(l10n.galleryNoTrackers,
          style: TextStyle(color: colorScheme.onSurfaceVariant)),
    );
  }
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final tag in trackers)
        _PickRow(
          leading: TagIconGlyph(
            icon: tag.icon,
            iconType: tag.iconType,
            fallbackIcon: tag.typeIcon,
            color: tag.resolvedColor(context, fallback: colorScheme.secondary),
            size: 20,
          ),
          label: tag.name,
          selected: tagIds.contains(tag.id),
          onTap: () {
            final next = {...tagIds};
            if (!next.remove(tag.id)) next.add(tag.id!);
            onChanged(next);
            refresh();
          },
        ),
    ],
  );
}

/// Keywords: type words (Enter adds one), All / Any, Match case, No Text.
class KeywordFilterBody extends StatefulWidget {
  const KeywordFilterBody({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.refresh,
  });

  final KeywordFilter filter;
  final void Function(KeywordFilter) onChanged;
  final VoidCallback refresh;

  @override
  State<KeywordFilterBody> createState() => _KeywordFilterBodyState();
}

class _KeywordFilterBodyState extends State<KeywordFilterBody> {
  final TextEditingController _text = TextEditingController();
  late KeywordFilter _filter = widget.filter;

  void _set(KeywordFilter filter) {
    setState(() => _filter = filter);
    widget.onChanged(filter);
    widget.refresh();
  }

  void _add() {
    final words = _text.text
        .split(RegExp(r'\s+'))
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
    _text.clear();
    if (words.isEmpty) return;
    final next = [..._filter.words];
    for (final word in words) {
      if (!next.contains(word)) next.add(word);
    }
    _set(_filter.copyWith(words: next, noText: false));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final noText = _filter.noText;
    final words = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: noText ? 0.35 : 1,
      child: IgnorePointer(
        ignoring: noText,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _text,
              autofocus: _filter.words.isEmpty && !noText,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.keywordsHint,
                prefixIcon: const Icon(Icons.text_fields_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: _add,
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                isDense: true,
              ),
              onSubmitted: (_) => _add(),
            ),
            if (_filter.words.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final word in _filter.words)
                    InputChip(
                      label: Text(word),
                      onDeleted: () => _set(_filter.copyWith(
                          words: [..._filter.words]..remove(word))),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: true, label: Text(l10n.keywordsAll)),
                ButtonSegment(value: false, label: Text(l10n.keywordsAny)),
              ],
              selected: {_filter.all},
              onSelectionChanged: (selected) =>
                  _set(_filter.copyWith(all: selected.first)),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              dense: true,
              title: Text(l10n.keywordsMatchCase),
              value: _filter.matchCase,
              onChanged: (value) => _set(_filter.copyWith(matchCase: value)),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        words,
        Divider(height: 8, color: colorScheme.outlineVariant),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          dense: true,
          title: Text(l10n.keywordsNoText),
          value: noText,
          onChanged: (value) => _set(_filter.copyWith(noText: value)),
        ),
      ],
    );
  }
}
