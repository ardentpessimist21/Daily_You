// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/future_entries.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/stats/stats_counts.dart';
import 'package:daily_you/fork/stats/stats_year.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/layouts/mobile_scaffold.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/pages/gallery_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/attachment_cover_thumbnail.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/widgets/vertical_calendar.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// The pages behind the Statistics counts (3.7.0.48): logs, days, words,
// tags, places and photos.

/// Logs, and anything tapped on these pages: a Gallery of its own with the
/// tag, place or word already set. Back returns to where it was opened.
class StatsGalleryPage extends StatelessWidget {
  const StatsGalleryPage({super.key, this.preset = const GalleryPreset()});

  final GalleryPreset preset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.pageGalleryTitle),
          centerTitle: true),
      body: GalleryPage(preset: preset),
    );
  }
}

void _openGallery(BuildContext context, GalleryPreset preset) {
  Navigator.of(context).push(MaterialPageRoute(
    allowSnapshotting: false,
    builder: (_) => StatsGalleryPage(preset: preset),
  ));
}

/// Past entries, rebuilt when entries change.
List<Entry> _pastEntries(BuildContext context) =>
    FutureEntries.past(Provider.of<EntriesProvider>(context).entries);

/// A page with the Statistics range buttons and, under All Time, the year
/// button. [builder] gets the entries in range.
class _RangedPage extends StatefulWidget {
  const _RangedPage({
    required this.title,
    required this.builder,
    this.extraControls,
  });

  final String title;
  final List<Widget> Function(BuildContext context, List<Entry> entries)
      builder;
  final List<Widget> Function(BuildContext context)? extraControls;

  @override
  State<_RangedPage> createState() => _RangedPageState();
}

class _RangedPageState extends State<_RangedPage> {
  StatsRange _range = StatsRange.allTime;
  int? _year;

  @override
  Widget build(BuildContext context) {
    final past = _pastEntries(context);
    final entries = entriesForStats(past, _range, _year);
    final yearCounts = entryCountsByYear(past);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: [
                  StatsRangeSelector(
                    key: ValueKey(_range),
                    statsRange: _range,
                    onSelectionChanged: (range) => setState(() {
                      _range = range;
                      _year = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_range == StatsRange.allTime && yearCounts.length > 1)
                        StatsYearButton(
                          year: _year,
                          counts: yearCounts,
                          onChanged: (year) => setState(() => _year = year),
                        ),
                      ...?widget.extraControls?.call(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ...widget.builder(context, entries),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// A rounded card holding a page's list.
Widget _card(BuildContext context, Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      ),
    );

Widget _empty(BuildContext context) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(AppLocalizations.of(context)!.noLogs,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ),
    );

/// A row's bar: how often, against the most used.
Widget _bar(double fraction, Color color) => Padding(
      padding: const EdgeInsets.only(top: 5),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: fraction.clamp(0.02, 1.0),
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );

Widget _countText(BuildContext context, int count) {
  final l10n = AppLocalizations.of(context)!;
  final color = Theme.of(context).colorScheme.onSurfaceVariant;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(NumberFormat.decimalPattern().format(count),
          style: TextStyle(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()])),
      Text(l10n.statsEntriesLabel,
          style: TextStyle(color: color, fontSize: 10.5)),
    ],
  );
}

// ---------------------------------------------------------------- Words

/// Most used words, as a list or a cloud. Tap a word to search it.
class MostUsedWordsPage extends StatefulWidget {
  const MostUsedWordsPage({super.key});

  @override
  State<MostUsedWordsPage> createState() => _MostUsedWordsPageState();
}

class _MostUsedWordsPageState extends State<MostUsedWordsPage> {
  bool get _cloud =>
      ConfigProvider.instance.get(Settings.statsWordsView) == 'cloud';

  List<Entry>? _for;
  List<MapEntry<String, int>> _words = const [];

  List<MapEntry<String, int>> _wordsOf(List<Entry> entries) {
    final same = _for != null &&
        _for!.length == entries.length &&
        (entries.isEmpty || identical(_for!.first, entries.first)) &&
        (entries.isEmpty || identical(_for!.last, entries.last));
    if (!same) {
      _for = entries;
      _words = wordUses(entries);
    }
    return _words;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return _RangedPage(
      title: l10n.statsMostUsedWords,
      extraControls: (context) => [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: false,
                icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
                label: Text(l10n.statsWordsList)),
            ButtonSegment(
                value: true,
                icon: const Icon(Icons.cloud_outlined, size: 18),
                label: Text(l10n.statsWordsCloud)),
          ],
          selected: {_cloud},
          onSelectionChanged: (value) async {
            await ConfigProvider.instance
                .set(Settings.statsWordsView, value.first ? 'cloud' : 'list');
            if (mounted) setState(() {});
          },
        ),
      ],
      builder: (context, entries) {
        final words = _wordsOf(entries);
        if (words.isEmpty) return [_empty(context)];
        void search(String word) =>
            _openGallery(context, GalleryPreset(search: word));
        if (_cloud) {
          final top = words.take(40).toList();
          final max = top.first.value;
          final palette = [
            colorScheme.primary,
            colorScheme.tertiary,
            colorScheme.secondary,
            colorScheme.onSurface,
          ];
          // Mixed order, so big words aren't all on top
          final mixed = [
            for (var i = 0; i < top.length; i++) (i, top[i]),
          ]..sort((a, b) => ((a.$1 * 7) % 11).compareTo((b.$1 * 7) % 11));
          return [
            SliverToBoxAdapter(
              child: _card(
                context,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 2,
                    children: [
                      for (final (i, word) in mixed)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => search(word.key),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              word.key,
                              style: TextStyle(
                                fontSize: 12 + 22 * math.sqrt(word.value / max),
                                fontWeight: FontWeight.w500,
                                color: palette[i % palette.length].withValues(
                                    alpha: 0.6 + 0.4 * word.value / max),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        }
        final top = words.take(50).toList();
        final max = top.first.value;
        return [
          SliverToBoxAdapter(
            child: _card(
              context,
              Column(
                children: [
                  for (var i = 0; i < top.length; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => search(top[i].key),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 7),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${i + 1}',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(top[i].key,
                                      style: const TextStyle(fontSize: 15)),
                                  _bar(top[i].value / max, colorScheme.primary),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                                NumberFormat.decimalPattern()
                                    .format(top[i].value),
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ])),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}

// ---------------------------------------------------------------- Tags

/// Top tags, with a category menu and Most / Least used. Tap a tag to see
/// its entries.
class TopTagsPage extends StatefulWidget {
  const TopTagsPage({super.key});

  @override
  State<TopTagsPage> createState() => _TopTagsPageState();
}

class _TopTagsPageState extends State<TopTagsPage> {
  int? _category; // null: all categories; -1: uncategorised
  bool _leastFirst = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tagsProvider = Provider.of<TagsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final categories = tagsProvider.categories;
    final categoryName = _category == null
        ? l10n.statsAllCategories
        : _category == -1
            ? l10n.statsUncategorised
            : categories
                    .where((category) => category.id == _category)
                    .firstOrNull
                    ?.name ??
                l10n.statsAllCategories;

    return _RangedPage(
      title: l10n.statsTopTags,
      extraControls: (context) => [
        PopupMenuButton<int?>(
          tooltip: l10n.statsAllCategories,
          onSelected: (value) => setState(() => _category = value),
          itemBuilder: (_) => [
            PopupMenuItem(value: null, child: Text(l10n.statsAllCategories)),
            for (final category in categories)
              PopupMenuItem(value: category.id, child: Text(category.name)),
            PopupMenuItem(value: -1, child: Text(l10n.statsUncategorised)),
          ],
          child: _OutlinedPill(label: categoryName),
        ),
        IconButton.outlined(
          tooltip: _leastFirst ? l10n.statsLeastUsed : l10n.statsMostUsed,
          icon: Icon(_leastFirst
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded),
          onPressed: () => setState(() => _leastFirst = !_leastFirst),
        ),
      ],
      builder: (context, entries) {
        final counts = tagUseCounts(entries, tagsProvider.entryTags);
        bool inCategory(Tag tag) => _category == null
            ? true
            : _category == -1
                ? tag.categoryId == null
                : tag.categoryId == _category;
        final tags = tagsProvider.tags
            .where(inCategory)
            .where((tag) => _leastFirst || (counts[tag.id] ?? 0) > 0)
            .toList()
          ..sort((a, b) {
            final byCount = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
            return _leastFirst ? -byCount : byCount;
          });
        if (tags.isEmpty) return [_empty(context)];
        final max = math.max(1, counts.values.fold<int>(0, math.max));
        return [
          SliverToBoxAdapter(
            child: _card(
              context,
              Column(
                children: [
                  for (final tag in tags)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          _openGallery(context, GalleryPreset(tagId: tag.id)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 7),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IgnorePointer(child: TagChip(tag: tag)),
                                  _bar(
                                      (counts[tag.id] ?? 0) / max,
                                      tag.resolvedColor(context,
                                          fallback: colorScheme.primary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _countText(context, counts[tag.id] ?? 0),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}

class _OutlinedPill extends StatelessWidget {
  const _OutlinedPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
            side:
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.7))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.arrow_drop_down_rounded, size: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Places

/// Top places: latest photo, description, bar and count. Tap one to see
/// its entries.
class TopPlacesPage extends StatelessWidget {
  const TopPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attachments =
        Provider.of<EntryAttachmentsProvider>(context).attachments;
    final colorScheme = Theme.of(context).colorScheme;
    return _RangedPage(
      title: l10n.statsTopPlaces,
      builder: (context, entries) {
        final uses = placeUses(entries);
        if (uses.isEmpty) return [_empty(context)];
        final max = uses.first.count;
        final visualByEntry = <int, EntryAttachment>{};
        for (final attachment in attachments) {
          final id = attachment.entryId;
          if (id == null || !attachment.type.isVisual) continue;
          visualByEntry.putIfAbsent(id, () => attachment);
        }
        return [
          SliverToBoxAdapter(
            child: _card(
              context,
              Column(
                children: [
                  for (final use in uses)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openGallery(
                          context, GalleryPreset(place: use.place.name)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 7),
                        child: Row(
                          children: [
                            _PlaceThumb(
                              attachment: use.entries
                                  .map((entry) => visualByEntry[entry.id])
                                  .nonNulls
                                  .firstOrNull,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(use.place.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500)),
                                  if (use.place.description.isNotEmpty)
                                    Text(use.place.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                colorScheme.onSurfaceVariant)),
                                  _bar(use.count / max, colorScheme.primary),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _countText(context, use.count),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}

class _PlaceThumb extends StatelessWidget {
  const _PlaceThumb({required this.attachment});

  final EntryAttachment? attachment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: attachment == null
            ? ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.place_outlined,
                    color: colorScheme.onSurfaceVariant),
              )
            : AttachmentCoverThumbnail(candidates: [attachment!]),
      ),
    );
  }
}

// ---------------------------------------------------------------- Photos

/// Photos, videos and audio: counts, the busiest day, then everything by
/// month, newest first. Tap one to open its entry.
class PhotosPage extends StatelessWidget {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attachments =
        Provider.of<EntryAttachmentsProvider>(context).attachments;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = TimeManager.currentLocale(context);
    return _RangedPage(
      title: l10n.statsPhotosTitle,
      builder: (context, entries) {
        final byId = {for (final entry in entries) entry.id: entry};
        final media = [
          for (final attachment in attachments)
            if (byId[attachment.entryId] case final entry?) (attachment, entry),
        ]..sort((a, b) => b.$2.timeCreate.compareTo(a.$2.timeCreate));
        if (media.isEmpty) return [_empty(context)];

        int countOf(AttachmentType type) =>
            media.where((item) => item.$1.type == type).length;
        final perDay = <DateTime, int>{};
        for (final (_, entry) in media) {
          perDay.update(DateUtils.dateOnly(entry.timeCreate), (n) => n + 1,
              ifAbsent: () => 1);
        }
        final busiest =
            perDay.entries.reduce((a, b) => b.value > a.value ? b : a);

        final months = <DateTime, List<(EntryAttachment, Entry)>>{};
        for (final item in media) {
          final date = item.$2.timeCreate;
          months
              .putIfAbsent(DateTime(date.year, date.month), () => [])
              .add(item);
        }

        Widget tile(String number, String label) => Expanded(
              child: Card.filled(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(number,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      Text(label,
                          style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            );
        final number = NumberFormat.decimalPattern();

        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  tile(number.format(countOf(AttachmentType.image)),
                      l10n.statsPhotosLabel),
                  tile(number.format(countOf(AttachmentType.video)),
                      l10n.statsVideosLabel),
                  tile(number.format(countOf(AttachmentType.audio)),
                      l10n.statsAudioLabel),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _card(
              context,
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => openDay(context, busiest.key),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text.rich(TextSpan(
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    children: [
                      TextSpan(text: '${l10n.statsBusiestDay}: '),
                      TextSpan(
                          text: TimeManager.formatDate(busiest.key, context),
                          style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600)),
                      TextSpan(text: ' · ${busiest.value}'),
                    ],
                  )),
                ),
              ),
            ),
          ),
          for (final MapEntry(key: month, value: items) in months.entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(DateFormat.yMMMM(locale).format(month),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Text('${items.length}',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, mainAxisSpacing: 3, crossAxisSpacing: 3),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final (attachment, entry) = items[index];
                  return InkWell(
                    onTap: () => openEntry(context, entry),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: attachment.type.isVisual
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                AttachmentCoverThumbnail(
                                    candidates: [attachment]),
                                if (attachment.type == AttachmentType.video)
                                  const Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(3),
                                      child: Icon(Icons.play_arrow_rounded,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                              ],
                            )
                          : ColoredBox(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.mic_none_rounded,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ];
      },
    );
  }
}

// ---------------------------------------------------------------- Days

/// Stand-in mood colours until the mood-coloured calendar sets real ones.
const _moodColors = {
  -2: Color(0xFFC8645E),
  -1: Color(0xFFD29457),
  0: Color(0xFF8E979E),
  1: Color(0xFF4FAE9A),
  2: Color(0xFF5CC59C),
};

/// Your days: the year in pixels (by mood or by entries), best month, days
/// written and the longest gaps without writing.
class YourDaysPage extends StatefulWidget {
  const YourDaysPage({super.key});

  @override
  State<YourDaysPage> createState() => _YourDaysPageState();
}

class _YourDaysPageState extends State<YourDaysPage> {
  int _year = DateTime.now().year;
  bool _written = false;
  bool _gapsNewest = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final past = _pastEntries(context);
    final counts = entryCountsByYear(past);
    final locale = TimeManager.currentLocale(context);

    // Each day's entries (newest first, as entries come)
    final byDay = <DateTime, List<Entry>>{};
    for (final entry in past) {
      byDay
          .putIfAbsent(DateUtils.dateOnly(entry.timeCreate), () => [])
          .add(entry);
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final daysWritten = byDay.keys.where((day) => day.year == _year).length;
    final daysInYear = _year == today.year
        ? today.difference(DateTime(_year)).inDays + 1
        : DateTime(_year + 1).difference(DateTime(_year)).inDays;

    // Best month, ever: most days written (ties: the newest)
    MapEntry<DateTime, int>? best;
    final monthDays = <DateTime, int>{};
    for (final day in byDay.keys) {
      monthDays.update(DateTime(day.year, day.month), (n) => n + 1,
          ifAbsent: () => 1);
    }
    for (final month in monthDays.entries) {
      if (best == null ||
          month.value > best.value ||
          (month.value == best.value && month.key.isAfter(best.key))) {
        best = month;
      }
    }

    final gaps = _gaps(byDay.keys.toList(), today);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsYourDays), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: false, label: Text(l10n.tagMoodTitle)),
                      ButtonSegment(
                          value: true, label: Text(l10n.statsWritten)),
                    ],
                    selected: {_written},
                    onSelectionChanged: (value) =>
                        setState(() => _written = value.first),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () async {
                    final pick = await showStatsYearPicker(context,
                        counts: counts, selected: _year, allowAll: false);
                    if (pick?.year != null) setState(() => _year = pick!.year!);
                  },
                  child: _OutlinedPill(label: '$_year'),
                ),
              ],
            ),
          ),
          _card(
            context,
            _YearPixels(
              year: _year,
              byDay: byDay,
              written: _written,
              today: today,
              onTapDay: (day) => _showDay(context, day, byDay[day]!),
            ),
          ),
          _card(context, _legend(context)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _infoTile(
                    context,
                    l10n.statsBestMonth,
                    best == null
                        ? '–'
                        : DateFormat.yMMM(locale).format(best.key),
                    best == null
                        ? ''
                        : l10n.statsDaysOf(
                            best.value,
                            DateUtils.getDaysInMonth(
                                best.key.year, best.key.month)),
                    onTap: best == null
                        ? null
                        : () => _showOnCalendar(context, best!.key),
                  ),
                ),
                Expanded(
                  child: _infoTile(
                    context,
                    l10n.statsDaysWritten,
                    '$daysWritten',
                    l10n.statsOfDaysIn(daysInYear, '$_year'),
                  ),
                ),
              ],
            ),
          ),
          if (gaps.isNotEmpty)
            _card(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l10n.statsMissingDays.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurfaceVariant)),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _gapsNewest = !_gapsNewest),
                          icon: const Icon(Icons.sort_rounded, size: 18),
                          label: Text(_gapsNewest
                              ? l10n.statsNewest
                              : l10n.statsLongest),
                        ),
                      ],
                    ),
                  ),
                  for (final gap in _shownGaps(gaps))
                    _gapRow(context, gap, locale),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The ongoing gap first, then the 5 longest (or newest).
  List<_Gap> _shownGaps(List<_Gap> gaps) {
    final ongoing = gaps.where((gap) => gap.ongoing).toList();
    final rest = gaps.where((gap) => !gap.ongoing).toList()
      ..sort((a, b) => _gapsNewest
          ? b.start.compareTo(a.start)
          : b.days != a.days
              ? b.days.compareTo(a.days)
              : b.start.compareTo(a.start));
    return [...ongoing, ...rest.take(5)];
  }

  List<_Gap> _gaps(List<DateTime> days, DateTime today) {
    if (days.isEmpty) return const [];
    final sorted = days.toList()..sort();
    final gaps = <_Gap>[];
    for (var i = 1; i < sorted.length; i++) {
      final missed = sorted[i].difference(sorted[i - 1]).inDays - 1;
      if (missed > 0) {
        gaps.add(_Gap(sorted[i - 1].add(const Duration(days: 1)),
            sorted[i].subtract(const Duration(days: 1)), missed));
      }
    }
    // Still going: the days since the last entry, not counting today
    final sinceLast = today.difference(sorted.last).inDays - 1;
    if (sinceLast > 0) {
      gaps.add(_Gap(sorted.last.add(const Duration(days: 1)),
          today.subtract(const Duration(days: 1)), sinceLast,
          ongoing: true, lastEntry: sorted.last));
    }
    return gaps;
  }

  Widget _gapRow(BuildContext context, _Gap gap, String locale) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final format = DateFormat.yMMMd(locale);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showOnCalendar(context, gap.start),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Text(gap.ongoing ? l10n.statsNow : '${gap.days}',
                      style: TextStyle(
                          fontSize: gap.ongoing ? 14 : 17,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary)),
                  Text(
                      gap.ongoing
                          ? '${gap.days} ${l10n.statsDaysUnit(gap.days)}'
                          : l10n.statsDaysUnit(gap.days),
                      style: TextStyle(
                          fontSize: 10.5, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gap.ongoing
                        ? l10n.statsSinceLastEntry
                        : gap.days == 1
                            ? format.format(gap.start)
                            : '${format.format(gap.start)} – ${format.format(gap.end)}',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  Text(
                    gap.ongoing
                        ? l10n.statsSince(format.format(gap.lastEntry!))
                        : l10n.statsNoEntries,
                    style: TextStyle(
                        fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  /// Back to Home with the calendar on [day]'s month.
  void _showOnCalendar(BuildContext context, DateTime day) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    MobileScaffold.showHome();
    VerticalCalendar.landHomeOn(day);
  }

  Widget _infoTile(
      BuildContext context, String label, String value, String detail,
      {VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: const EdgeInsets.all(4),
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.6,
                      color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              if (detail.isNotEmpty)
                Text(detail,
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    Widget swatch(Color color, Widget label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 4),
            label,
          ],
        );
    final style =
        TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: _written
            ? [
                swatch(_emptyColor(colorScheme),
                    Text(l10n.statsNone, style: style)),
                for (final n in [1, 2, 3])
                  swatch(_writtenColor(colorScheme, n),
                      Text(n == 3 ? '3+' : '$n', style: style)),
              ]
            : [
                for (final mood in [-2, -1, 0, 1, 2])
                  swatch(_moodColors[mood]!,
                      MoodIcon(moodValue: mood, size: 13, allowScaling: false)),
                swatch(_noMoodColor(colorScheme),
                    Text(l10n.statsNoMood, style: style)),
                swatch(_emptyColor(colorScheme),
                    Text(l10n.statsNoEntry, style: style)),
              ],
      ),
    );
  }

  void _showDay(BuildContext context, DateTime day, List<Entry> entries) {
    final l10n = AppLocalizations.of(context)!;
    final first = entries.last; // oldest that day
    final mood = entries.first.mood;
    final line = EntryLocations.bodyOf(first.text)
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^[#>\-\*\s\[\]x]+'), '').trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(TimeManager.formatDate(day, context),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                if (mood != null)
                  MoodIcon(moodValue: mood, size: 20, allowScaling: false),
              ],
            ),
            if (entries.length > 1)
              Text(l10n.logCount(entries.length),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (line.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  openDay(context, day);
                },
                child: Text(l10n.statsOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _emptyColor(ColorScheme colorScheme) =>
    colorScheme.surfaceContainerHighest;
Color _noMoodColor(ColorScheme colorScheme) =>
    colorScheme.outline.withValues(alpha: 0.7);
Color _writtenColor(ColorScheme colorScheme, int count) => colorScheme.primary
    .withValues(alpha: switch (count) { 1 => 0.35, 2 => 0.65, _ => 1.0 });

class _Gap {
  _Gap(this.start, this.end, this.days, {this.ongoing = false, this.lastEntry});

  final DateTime start;
  final DateTime end;
  final int days;
  final bool ongoing;
  final DateTime? lastEntry;
}

/// Months across, days 1–31 down. Days that don't exist are blank; today
/// has an outline.
class _YearPixels extends StatelessWidget {
  const _YearPixels({
    required this.year,
    required this.byDay,
    required this.written,
    required this.today,
    required this.onTapDay,
  });

  final int year;
  final Map<DateTime, List<Entry>> byDay;
  final bool written;
  final DateTime today;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = TimeManager.currentLocale(context);
    final label = TextStyle(fontSize: 9.5, color: colorScheme.onSurfaceVariant);
    Color colorFor(List<Entry>? entries) {
      if (entries == null || entries.isEmpty) return _emptyColor(colorScheme);
      if (written) return _writtenColor(colorScheme, entries.length);
      final mood = entries.first.mood; // the day's last entry
      return mood == null ? _noMoodColor(colorScheme) : _moodColors[mood]!;
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 18),
              for (var month = 1; month <= 12; month++)
                Expanded(
                  child: Text(
                      DateFormat.MMM(locale)
                          .format(DateTime(year, month))
                          .characters
                          .first,
                      textAlign: TextAlign.center,
                      style: label),
                ),
            ],
          ),
          const SizedBox(height: 3),
          for (var day = 1; day <= 31; day++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text([1, 10, 20, 30].contains(day) ? '$day' : '',
                        textAlign: TextAlign.end,
                        style: label.copyWith(fontSize: 8.5, height: 1)),
                  ),
                  for (var month = 1; month <= 12; month++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: day > DateUtils.getDaysInMonth(year, month)
                            ? const SizedBox(height: 9)
                            : _pixel(
                                context, DateTime(year, month, day), colorFor),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pixel(BuildContext context, DateTime date,
      Color Function(List<Entry>?) colorFor) {
    final entries = byDay[date];
    final isToday = date == today;
    final box = Container(
      height: 9,
      decoration: BoxDecoration(
        color: colorFor(entries),
        borderRadius: BorderRadius.circular(2),
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.onSurface)
            : null,
      ),
    );
    if (entries == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapDay(date),
      child: box,
    );
  }
}
