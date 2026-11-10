// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/future_entries.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/layouts/mobile_scaffold.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/stats/stats_counts.dart';
import 'package:daily_you/fork/stats/explore_pages.dart';
import 'package:daily_you/fork/stats/stats_year.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/stats_subject.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/stats/entry_stats.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/stats/streaks.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/distribution_chart.dart';
import 'package:daily_you/widgets/label_summary_card.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/mood_summary_chart.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:daily_you/widgets/stats_overview_card.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/utils/bucket_combiner.dart';
import 'package:daily_you/utils/chart_y_range.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/value_by_day_chart.dart';
import 'package:daily_you/widgets/value_over_time_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with AutomaticKeepAliveClientMixin {
  late StatsRange statsRange;
  late String _subjectConfig;

  /// A calendar year picked under All Time (3.7.0.48). Not remembered.
  int? _year;
  DateTime? get _yearStart => _year == null ? null : DateTime(_year!);
  DateTime? get _yearEnd =>
      _year == null ? null : DateTime(_year!, 12, 31, 23, 59, 59);

  // Header height calculated based on an offstage copy
  double _headerHeight = 98.0;
  final GlobalKey _headerMeasureKey = GlobalKey();

  List<Entry>? _countedEntries;
  int _wordCount = 0;

  static const _rangeToString = {
    StatsRange.month: 'month',
    StatsRange.sixMonths: 'sixMonths',
    StatsRange.year: 'year',
    StatsRange.allTime: 'allTime',
  };

  static const _stringToRange = {
    'month': StatsRange.month,
    'sixMonths': StatsRange.sixMonths,
    'year': StatsRange.year,
    'allTime': StatsRange.allTime,
  };

  @override
  void initState() {
    super.initState();
    final saved = ConfigProvider.instance.get(Settings.statsRange);
    statsRange = _stringToRange[saved] ?? StatsRange.allTime;
    _subjectConfig = ConfigProvider.instance.get(Settings.statsSubject);
    MobileScaffold.tab.addListener(_onTabShown);
  }

  @override
  void dispose() {
    MobileScaffold.tab.removeListener(_onTabShown);
    super.dispose();
  }

  // "Tap a count to explore" (3.7.0.48): the first 3 times Statistics is
  // opened, until a count is tapped or the hint is closed
  bool _hintCounted = false;
  bool _showHint = false;

  void _onTabShown() {
    if (MobileScaffold.tab.value != 2 || _hintCounted || !mounted) return;
    _hintCounted = true;
    final shown = ConfigProvider.instance.get(Settings.statsTapHintShown);
    if (shown >= 3) return;
    ConfigProvider.instance.set(Settings.statsTapHintShown, shown + 1);
    setState(() => _showHint = true);
  }

  void _hideHintForGood() {
    if (ConfigProvider.instance.get(Settings.statsTapHintShown) < 3) {
      ConfigProvider.instance.set(Settings.statsTapHintShown, 3);
    }
    if (_showHint) setState(() => _showHint = false);
  }

  void _explore(Widget page) {
    _hideHintForGood();
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page, allowSnapshotting: false));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Recalculate header height when text size changes
    MediaQuery.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeaderHeight());
    return buildPage(context);
  }

  void _measureHeaderHeight() {
    if (!mounted) return;
    final renderBox =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final measuredHeight = renderBox.size.height + 2.0;
    if ((measuredHeight - _headerHeight).abs() > 0.5) {
      setState(() => _headerHeight = measuredHeight);
    }
  }

  int _wordCountOf(List<Entry> entries) {
    if (!identical(entries, _countedEntries)) {
      _countedEntries = entries;
      _wordCount = totalWordCount(entries);
    }
    return _wordCount;
  }

  Widget buildPage(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final tagsProvider = Provider.of<TagsProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    final subject =
        StatsSubject.fromConfigString(_subjectConfig, tagsProvider.tags);
    // Upcoming entries count once their day arrives
    final pastEntries = FutureEntries.past(entriesProvider.entries);
    final rangedEntries = entriesForStats(pastEntries, statsRange, _year);
    final yearCounts = entryCountsByYear(pastEntries);
    final streaks = calculateStreaks(pastEntries);
    final daysSinceBadDay = streaks.daysSinceBadDay;

    final logCount = pastEntries.length;
    final entryDayCount = identical(pastEntries, entriesProvider.entries)
        ? entriesProvider.getEntryDayCount()
        : pastEntries
            .map((entry) => TimeManager.startOfDay(entry.timeCreate))
            .toSet()
            .length;
    final wordCount = _wordCountOf(pastEntries);

    final primaryStreakItem = logCount > 0
        ? StatItem(
            icon: Icons.bolt,
            title: l10n.streakCurrent(streaks.current),
          )
        : null;

    final streakSideItems = <StatItem>[
      if (streaks.longest > 0)
        StatItem(
          icon: Icons.history_rounded,
          title: l10n.streakLongest(streaks.longest),
        ),
      if (logCount > 0)
        StatItem(
          icon: Icons.mood_rounded,
          title: l10n.streakGreatDays(greatDayCount(pastEntries)),
        ),
      if (daysSinceBadDay != null && daysSinceBadDay > 3)
        StatItem(
          icon: Icons.timeline_rounded,
          title: l10n.streakSinceBadDay(daysSinceBadDay),
        ),
    ];

    final counts = StatsCounts.of(pastEntries, tagsProvider.entryTags,
        EntryAttachmentsProvider.instance.attachments);
    final writingItems = <StatItem>[
      if (logCount > 0)
        StatItem(
          icon: Icons.description_outlined,
          title: l10n.logCount(logCount),
          onTap: () => _explore(const StatsGalleryPage()),
        ),
      if (entryDayCount > 0)
        StatItem(
          icon: Icons.today_rounded,
          title: l10n.dayCount(entryDayCount),
          onTap: () => _explore(const YourDaysPage()),
        ),
      if (wordCount > 0)
        StatItem(
          icon: Icons.sort_rounded,
          title: l10n.wordCount(wordCount),
          onTap: () => _explore(const MostUsedWordsPage()),
        ),
      if (counts.tags > 0)
        StatItem(
          icon: Icons.local_offer_outlined,
          title: l10n.tagCount(counts.tags),
          onTap: () => _explore(const TopTagsPage()),
        ),
      if (counts.places > 0 && EntryLocations.showButtons)
        StatItem(
          icon: Icons.place_outlined,
          title: l10n.placeCount(counts.places),
          onTap: () => _explore(const TopPlacesPage()),
        ),
      if (counts.media > 0)
        StatItem(
          icon: Icons.photo_outlined,
          title: l10n.photoCount(counts.media),
          onTap: () => _explore(const PhotosPage()),
        ),
    ];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            if (primaryStreakItem != null || writingItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: StatsOverviewCard(
                    primary: primaryStreakItem,
                    sideItems: streakSideItems,
                    writingItems: writingItems,
                  ),
                ),
              ),
            if (_showHint && writingItems.isNotEmpty)
              SliverToBoxAdapter(child: _TapHint(onClose: _hideHintForGood)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                statsRange: statsRange,
                subject: subject,
                height: _headerHeight,
                year: _year,
                yearCounts: yearCounts,
                onYearChanged: (year) => setState(() => _year = year),
                onRangeChanged: (newRange) {
                  setState(() {
                    statsRange = newRange;
                    _year = null;
                  });
                  ConfigProvider.instance
                      .set(Settings.statsRange, _rangeToString[newRange]!);
                },
                onSubjectTypeSelected: (type) =>
                    _onSubjectTypeSelected(context, type),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildChartsForSubject(
                        context, subject, rangedEntries, tagsProvider),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ],
        ),

        // An offstage copy of the header content, so _measureHeaderHeight can read its
        // natural size.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Offstage(
            offstage: true,
            child: _HeaderContent(
              key: _headerMeasureKey,
              statsRange: statsRange,
              subject: subject,
              year: _year,
              yearCounts: yearCounts,
              onYearChanged: (_) {},
              onRangeChanged: (_) {},
              onSubjectTypeSelected: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSubjectTypeSelected(BuildContext context, String type) async {
    if (type == 'mood') {
      _applySubject(const MoodSubject());
      return;
    }
    final tag = await showAppDialog<Tag>(
      context: context,
      builder: (_) => TagPickerDialog(
        mode: TagPickerMode.selectSingle,
        tagTypeFilter: type == 'label' ? TagType.label : TagType.tracker,
      ),
    );
    if (tag == null) return; // cancelled, leave current subject untouched
    _applySubject(type == 'label' ? LabelSubject(tag) : TrackerSubject(tag));
  }

  void _applySubject(StatsSubject subject) {
    setState(() => _subjectConfig = subject.toConfigString());
    ConfigProvider.instance.set(Settings.statsSubject, _subjectConfig);
  }

  List<Widget> _buildChartsForSubject(
    BuildContext context,
    StatsSubject subject,
    List<Entry> entries,
    TagsProvider tagsProvider,
  ) {
    return switch (subject) {
      MoodSubject() => _buildMoodCharts(context, entries),
      TrackerSubject(tag: final tag) =>
        _buildTrackerCharts(context, entries, tagsProvider, tag),
      LabelSubject(tag: final tag) =>
        _buildLabelCharts(context, entries, tagsProvider, tag),
    };
  }

  static const _moodRange = FixedYRange(minY: -2, maxY: 2, interval: 1);

  List<Widget> _buildMoodCharts(BuildContext context, List<Entry> entries) {
    final l10n = AppLocalizations.of(context)!;
    final moodPoints = entries
        .where((entry) => entry.mood != null)
        .map((entry) => (date: entry.timeCreate, value: entry.mood!.toDouble()))
        .toList();
    final hasData = moodPoints.length > 1;

    return [
      ValueOverTimeChart(
        fixedStart: _yearStart,
        fixedEnd: _yearEnd,
        dataPoints: moodPoints,
        hasData: hasData,
        yRange: _moodRange,
        combine: combineByAverage,
        title: l10n.chartOverTimeTitle(l10n.tagMoodTitle),
        buildLeftTitle: (value, meta) => SideTitleWidget(
          meta: meta,
          child: MoodIcon(moodValue: value.toInt(), allowScaling: false),
        ),
      ),
      MoodSummaryChart(
        moodCounts: moodTotals(entries),
        hasData: hasData,
      ),
      ValueByDayChart(
        averageValues: averageByDayOfWeek(
            entries, (entry) => entry.mood?.toDouble(),
            emptyDayValue: -2),
        hasData: hasData,
        yRange: _moodRange,
        title: l10n.chartByDayTitle(l10n.tagMoodTitle),
        buildLeftTitle: (value, meta) => SideTitleWidget(
          meta: meta,
          child: MoodIcon(moodValue: value.toInt(), allowScaling: false),
        ),
      ),
    ];
  }

  List<Widget> _buildTrackerCharts(
    BuildContext context,
    List<Entry> entries,
    TagsProvider tagsProvider,
    Tag tag,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tagColor = tag.resolvedColor(context);

    final valueByEntryId =
        trackerValuesByEntry(entries, tagsProvider.entryTags, tag.id!);

    final dataPoints = [
      for (final entry in entries)
        if (valueByEntryId[entry.id] case final value?)
          (date: entry.timeCreate, value: value),
    ];
    final rawValues = dataPoints.map((point) => point.value).toList();

    final hasData = dataPoints.length > 1;
    final (minY, maxY) = trackerYRange(rawValues);
    final trackerRange = FixedYRange(minY: minY, maxY: maxY);

    return [
      ValueOverTimeChart(
        fixedStart: _yearStart,
        fixedEnd: _yearEnd,
        dataPoints: dataPoints,
        hasData: hasData,
        yRange: trackerRange,
        combine: combineByAverage,
        title: l10n.chartOverTimeTitle(tag.name),
        color: tagColor,
        anchorAtZero: true,
      ),
      DistributionChart(
        values: rawValues,
        title: l10n.chartDistributionTitle(tag.name),
        color: tagColor,
      ),
      ValueByDayChart(
        averageValues:
            averageByDayOfWeek(entries, (entry) => valueByEntryId[entry.id]),
        hasData: hasData,
        yRange: trackerRange,
        title: l10n.chartByDayTitle(tag.name),
        color: tagColor,
        anchorAtZero: true,
      ),
    ];
  }

  List<Widget> _buildLabelCharts(
    BuildContext context,
    List<Entry> entries,
    TagsProvider tagsProvider,
    Tag tag,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tagColor = tag.resolvedColor(context);

    final presentIds = entryIdsWithTag(tagsProvider.entryTags, tag.id!);

    final presentCount =
        entries.where((entry) => presentIds.contains(entry.id)).length;
    final totalCount = entries.length;

    final coveragePoints = entries
        .map((entry) => (
              date: entry.timeCreate,
              value: presentIds.contains(entry.id) ? 1.0 : 0.0,
            ))
        .toList();

    final dayCounts =
        countByDayOfWeek(entries, (entry) => presentIds.contains(entry.id));

    return [
      ValueOverTimeChart(
        fixedStart: _yearStart,
        fixedEnd: _yearEnd,
        dataPoints: coveragePoints,
        hasData: entries.isNotEmpty,
        yRange: const DynamicYRange(),
        combine: combineBySum,
        title: l10n.chartOverTimeTitle(tag.name),
        color: tagColor,
      ),
      LabelSummaryCard(
        tag: tag,
        presentCount: presentCount,
        totalCount: totalCount,
      ),
      ValueByDayChart(
        averageValues: dayCounts,
        hasData: entries.isNotEmpty,
        yRange: const DynamicYRange(),
        title: l10n.chartByDayTitle(tag.name),
        color: tagColor,
      ),
    ];
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final StatsRange statsRange;
  final StatsSubject subject;
  final double height;
  final int? year;
  final Map<int, int> yearCounts;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<StatsRange> onRangeChanged;
  final ValueChanged<String> onSubjectTypeSelected;

  const _HeaderDelegate({
    required this.statsRange,
    required this.subject,
    required this.height,
    required this.year,
    required this.yearCounts,
    required this.onYearChanged,
    required this.onRangeChanged,
    required this.onSubjectTypeSelected,
  });

  static const double _fadeHeight = 8.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Wrapped in align to avoid painting size issue https://github.com/flutter/flutter/issues/78748
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor,
                      backgroundColor,
                      backgroundColor.withValues(alpha: 0.0),
                    ],
                    stops: [
                      0.0,
                      (height - _fadeHeight) / height,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
            // Clipped while the new height is measured, e.g. right after
            // the year button appears (3.7.0.48)
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: double.infinity,
                child: _HeaderContent(
                  statsRange: statsRange,
                  subject: subject,
                  year: year,
                  yearCounts: yearCounts,
                  onYearChanged: onYearChanged,
                  onRangeChanged: onRangeChanged,
                  onSubjectTypeSelected: onSubjectTypeSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) =>
      oldDelegate.statsRange != statsRange ||
      oldDelegate.year != year ||
      oldDelegate.yearCounts.length != yearCounts.length ||
      oldDelegate.subject.toConfigString() != subject.toConfigString() ||
      oldDelegate.height != height;
}

class _HeaderContent extends StatelessWidget {
  final StatsRange statsRange;
  final StatsSubject subject;
  final int? year;
  final Map<int, int> yearCounts;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<StatsRange> onRangeChanged;
  final ValueChanged<String> onSubjectTypeSelected;

  const _HeaderContent({
    super.key,
    required this.statsRange,
    required this.subject,
    required this.year,
    required this.yearCounts,
    required this.onYearChanged,
    required this.onRangeChanged,
    required this.onSubjectTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = Theme.of(context).colorScheme.secondary;

    final (subjectIcon, subjectLabel, subjectColor) = switch (subject) {
      MoodSubject() => (
          Icons.mood_rounded,
          l10n.tagMoodTitle,
          secondary,
        ),
      LabelSubject(tag: final t) => (
          t.typeIcon,
          t.name,
          t.resolvedColor(context, fallback: secondary),
        ),
      TrackerSubject(tag: final t) => (
          t.typeIcon,
          t.name,
          t.resolvedColor(context, fallback: secondary),
        ),
    };

    final currentType = switch (subject) {
      MoodSubject() => 'mood',
      LabelSubject() => 'label',
      TrackerSubject() => 'tracker',
    };

    final subjectTag = switch (subject) {
      LabelSubject(tag: final t) => t,
      TrackerSubject(tag: final t) => t,
      MoodSubject() => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: onSubjectTypeSelected,
            itemBuilder: (menuContext) => [
              _subjectMenuItem(
                menuContext,
                value: 'mood',
                icon: Icons.mood_rounded,
                label: l10n.tagMoodTitle,
                selected: currentType == 'mood',
              ),
              _subjectMenuItem(
                menuContext,
                value: 'label',
                icon: Icons.label_rounded,
                label: l10n.tagTypeLabelTitle,
                selected: currentType == 'label',
              ),
              _subjectMenuItem(
                menuContext,
                value: 'tracker',
                icon: Icons.timeline_rounded,
                label: l10n.tagTypeTrackerTitle,
                selected: currentType == 'tracker',
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: subjectColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                color: subjectColor.withValues(alpha: 0.08),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TagIconGlyph(
                    icon: subjectTag?.icon,
                    iconType: subjectTag?.iconType ?? TagIconType.character,
                    fallbackIcon: subjectIcon,
                    color: subjectColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      subjectLabel,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        fontSize: 14,
                        color: subjectColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18, color: subjectColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          StatsRangeSelector(
            key: ValueKey(statsRange),
            statsRange: statsRange,
            onSelectionChanged: onRangeChanged,
          ),
          // All Time: pick one calendar year (3.7.0.48)
          if (statsRange == StatsRange.allTime && yearCounts.length > 1) ...[
            const SizedBox(height: 8),
            StatsYearButton(
                year: year, counts: yearCounts, onChanged: onYearChanged),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  PopupMenuItem<String> _subjectMenuItem(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(Icons.check_rounded,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent),
        const SizedBox(width: 8),
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ]),
    );
  }
}

/// "Tap a count to explore", small and muted under the counts card.
class _TapHint extends StatelessWidget {
  const _TapHint({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(l10n.statsTapHint,
                style: TextStyle(fontSize: 12.5, color: color)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 14,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(Icons.close_rounded, color: color),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
