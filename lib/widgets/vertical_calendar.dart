// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:daily_you/fork/future_entries.dart';
import 'package:daily_you/fork/jump_picker.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/calendar_view_options_dialog.dart';
import 'package:daily_you/widgets/entry_day_cell.dart';
import 'package:daily_you/fork/year_month_range.dart';
import 'package:daily_you/widgets/year_month_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

sealed class _CalendarItem {
  const _CalendarItem();
}

final class _MonthHeaderItem extends _CalendarItem {
  final DateTime month;
  const _MonthHeaderItem(this.month);
}

final class _WeekRowItem extends _CalendarItem {
  final List<DateTime?> days;
  const _WeekRowItem(this.days);
}

class VerticalCalendar extends StatefulWidget {
  final ScrollController scrollController;
  final void Function(BuildContext context, DateTime date)? onDaySelected;

  /// Home's calendar only: scrolls back to the current month when the Home
  /// tab is tapped while already on Home (3.7.0.40).
  final bool followsHomeTab;

  const VerticalCalendar({
    super.key,
    required this.scrollController,
    this.onDaySelected,
    this.followsHomeTab = false,
  });

  /// Bumped when the Home tab is tapped again while on Home.
  static final ValueNotifier<int> homeTabRetapped = ValueNotifier(0);

  /// Home's calendar centres this month and flashes it (3.7.0.41), e.g.
  /// when leaving an entry from May 2021 brings you back to May 2021.
  static final ValueNotifier<(DateTime, int)?> _homeLand = ValueNotifier(null);
  static int _landCount = 0;
  static void landHomeOn(DateTime date) =>
      _homeLand.value = (date, ++_landCount);

  static _VerticalCalendarState? _home;

  /// Back on Home (3.7.0.41): when the calendar is scrolled away from the
  /// present month, scrolls back to it and returns true (the back is used
  /// up). False when it's already there.
  static bool homeBackToNow() => _home?._backToNow() ?? false;

  @override
  State<VerticalCalendar> createState() => _VerticalCalendarState();
}

class _VerticalCalendarState extends State<VerticalCalendar>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  static const double _daysOfWeekRowHeight = 32.0;

  double _weekRowHeight = 57.0;
  double _todayOffset = 0.0;

  Map<int, ui.Image> _dayNumberCache = {};
  double? _lastDevicePixelRatio;
  double _lastWeekRowHeight = 0.0;
  int _cacheGeneration = 0;

  bool _initialScrollDone = false;
  bool _isJalali = false;

  List<_CalendarItem> _items = [];
  List<(double, DateTime)> _monthOffsets = [];
  // Where each month's header row sits, newest month first.
  List<(double, DateTime)> _headerOffsets = [];
  // The month pinned at the top while scrolling, and how far the next
  // month's header has pushed it up.
  final _sticky = ValueNotifier<(DateTime?, double)>((null, 0));
  static const double _listBottomPadding = 85;

  final _showTodayButton = ValueNotifier<bool>(false);
  DateTime _visibleMonth = DateTime.now();
  String _cachedLocale = '';

  int? _lastFirstDayIndex;
  double _cellWidth = 0;
  List<String> _dayLabels = [];

  final DateTime _firstDate = DateTime(2000, 1, 1);
  // Recomputed when the day changes (see _checkForNewDay), so a calendar
  // left open past midnight or into a new month stays current.
  DateTime _lastDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  // Future entries: the calendar reaches 12 months ahead.
  bool _allowFuture = false;
  int get _monthsAhead => _allowFuture ? FutureEntries.monthsAhead : 0;
  // With future entries off, the next months still show, greyed out, so
  // the current month can sit in the middle of the screen (3.7.0.39).
  static const int _greyMonthsAhead = 2;
  int get _shownMonthsAhead => _allowFuture ? _monthsAhead : _greyMonthsAhead;
  // The current month's rows, as list offsets: its first week row's start
  // and its header row's end.
  (double, double)? _currentMonthSpan;
  DateTime _today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  Timer? _midnightTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    if (widget.followsHomeTab) {
      VerticalCalendar.homeTabRetapped.addListener(_onHomeTabRetapped);
      VerticalCalendar._homeLand.addListener(_onHomeLand);
      VerticalCalendar._home = this;
    }
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkForNewDay();
  }

  void _scheduleMidnightCheck() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // A second of slack so the check lands safely on the new day
    _midnightTimer =
        Timer(nextMidnight.difference(now) + const Duration(seconds: 1), () {
      _checkForNewDay();
      _scheduleMidnightCheck();
    });
  }

  void _checkForNewDay() {
    if (!mounted) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today == _today) return;
    setState(() {
      _today = today;
      _lastDate = DateTime(now.year, now.month + _monthsAhead, 1);
      if (_lastFirstDayIndex != null) _buildCalendarItems(_lastFirstDayIndex!);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final firstDayIndex = configProvider.getFirstDayOfWeekIndex(context);
    _setAllowFuture(configProvider.get(Settings.allowFutureEntries));
    final newLocale = TimeManager.currentLocale(context);

    final firstDayChanged = firstDayIndex != _lastFirstDayIndex;
    final localeChanged = newLocale != _cachedLocale;
    _cachedLocale = newLocale;

    final newIsJalali = TimeManager.isJalaliCalendar(context);
    final jalaliChanged = newIsJalali != _isJalali;
    _isJalali = newIsJalali;

    if (firstDayChanged || jalaliChanged) {
      _lastFirstDayIndex = firstDayIndex;
      _buildCalendarItems(firstDayIndex);
      _visibleMonth = DateTime.now();
    }

    if (firstDayChanged || localeChanged || jalaliChanged) {
      final allLabels = TimeManager.daysOfWeekLabels(context);
      _dayLabels = [
        ...allLabels.sublist(firstDayIndex),
        ...allLabels.sublist(0, firstDayIndex),
      ];
    }
  }

  /// Returns true when the setting changed, so the months need rebuilding.
  bool _setAllowFuture(bool allow) {
    if (allow == _allowFuture) return false;
    _allowFuture = allow;
    final now = DateTime.now();
    _lastDate = DateTime(now.year, now.month + _monthsAhead, 1);
    return true;
  }

  @override
  void dispose() {
    VerticalCalendar.homeTabRetapped.removeListener(_onHomeTabRetapped);
    VerticalCalendar._homeLand.removeListener(_onHomeLand);
    if (VerticalCalendar._home == this) VerticalCalendar._home = null;
    _flashTimer?.cancel();
    _midnightTimer?.cancel();
    _sticky.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _showTodayButton.dispose();
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  Future<ui.Image> _bakeDayNumber(
      String text, double devicePixelRatio, double logicalSize) async {
    final physicalSize = (logicalSize * devicePixelRatio).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio, devicePixelRatio);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 6),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        (logicalSize - painter.width) / 2,
        (logicalSize - painter.height) / 2,
      ),
    );

    return recorder.endRecording().toImage(physicalSize, physicalSize);
  }

  Future<void> _createDayNumberCache(double devicePixelRatio) async {
    final generation = ++_cacheGeneration;
    final logicalSize = _weekRowHeight;
    final cache = <int, ui.Image>{};
    for (int day = 1; day <= 31; day++) {
      cache[day] =
          await _bakeDayNumber(day.toString(), devicePixelRatio, logicalSize);
    }
    if (!mounted || generation != _cacheGeneration) return;
    setState(() => _dayNumberCache = cache);
  }

  void _buildCalendarItems(int firstDayIndex) {
    if (_isJalali) {
      _buildCalendarItemsJalali(firstDayIndex);
    } else {
      _buildCalendarItemsGregorian(firstDayIndex);
    }
  }

  /// Builds the week rows for one calendar month. [isInMonth] decides which days
  /// within a week belong to the month being built.
  List<List<DateTime?>> _buildWeekRowsForMonth({
    required DateTime firstDayOfMonth,
    required DateTime lastDayOfMonth,
    required int firstDayDart,
    required bool Function(DateTime day) isInMonth,
  }) {
    final daysFromWeekStart = (lastDayOfMonth.weekday - firstDayDart + 7) % 7;
    // Use the DateTime constructor to subtract days so the shift never
    // drifts across a daylight-saving transition.
    DateTime weekStart = DateTime(
      lastDayOfMonth.year,
      lastDayOfMonth.month,
      lastDayOfMonth.day - daysFromWeekStart,
    );

    final daysBeforeFirst = (firstDayOfMonth.weekday - firstDayDart + 7) % 7;
    final firstWeekStart = DateTime(
      firstDayOfMonth.year,
      firstDayOfMonth.month,
      firstDayOfMonth.day - daysBeforeFirst,
    );

    final weeks = <List<DateTime?>>[];
    while (!weekStart.isBefore(firstWeekStart)) {
      weeks.add(List<DateTime?>.generate(7, (dayOffset) {
        final day = DateTime(
            weekStart.year, weekStart.month, weekStart.day + dayOffset);
        return isInMonth(day) ? day : null;
      }));
      weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day - 7);
    }
    return weeks;
  }

  void _buildCalendarItemsGregorian(int firstDayIndex) {
    final firstDayDart = firstDayIndex == 6 ? 7 : firstDayIndex + 1;

    final items = <_CalendarItem>[];
    final monthOffsets = <(double, DateTime)>[];
    final headerOffsets = <(double, DateTime)>[];
    double offset = 0;

    final now = DateTime.now();
    DateTime current = DateTime(now.year, now.month + _shownMonthsAhead, 1);
    final end = DateTime(_firstDate.year, _firstDate.month, 1);

    while (!current.isBefore(end)) {
      monthOffsets.add((offset, current));

      // Day 0 of the following month is the last day of this one.
      final lastDayOfMonth = DateTime(current.year, current.month + 1, 0);
      final weeks = _buildWeekRowsForMonth(
        firstDayOfMonth: current,
        lastDayOfMonth: lastDayOfMonth,
        firstDayDart: firstDayDart,
        isInMonth: (day) =>
            day.month == current.month && day.year == current.year,
      );

      final isCurrentMonth =
          current.year == _today.year && current.month == _today.month;
      final monthStartOffset = offset;
      for (final week in weeks) {
        if (isCurrentMonth &&
            week.any((day) => day != null && day.day == _today.day)) {
          _todayOffset = (offset - _weekRowHeight).clamp(0, double.infinity);
        }
        items.add(_WeekRowItem(week));
        offset += _weekRowHeight;
      }

      items.add(_MonthHeaderItem(current));
      headerOffsets.add((offset, current));
      offset += _weekRowHeight;
      if (isCurrentMonth) _currentMonthSpan = (monthStartOffset, offset);

      current = DateTime(current.year, current.month - 1, 1);
    }

    _items = items;
    _monthOffsets = monthOffsets;
    _headerOffsets = headerOffsets;
  }

  void _buildCalendarItemsJalali(int firstDayIndex) {
    final firstDayDart = firstDayIndex == 6 ? 7 : firstDayIndex + 1;

    final items = <_CalendarItem>[];
    final monthOffsets = <(double, DateTime)>[];
    final headerOffsets = <(double, DateTime)>[];
    double offset = 0;

    final todayJalali = Jalali.fromDateTime(_today);
    final firstDateJalali = Jalali.fromDateTime(_firstDate);

    Jalali current = Jalali(todayJalali.year, todayJalali.month, 1)
        .addMonths(_shownMonthsAhead);
    final end = Jalali(firstDateJalali.year, firstDateJalali.month, 1);

    while (current >= end) {
      final monthStart = current.toDateTime();
      monthOffsets.add((offset, monthStart));

      final lastDayOfMonth =
          Jalali(current.year, current.month, current.monthLength).toDateTime();
      final weeks = _buildWeekRowsForMonth(
        firstDayOfMonth: monthStart,
        lastDayOfMonth: lastDayOfMonth,
        firstDayDart: firstDayDart,
        isInMonth: (day) {
          final jalaliDay = Jalali.fromDateTime(day);
          return jalaliDay.year == current.year &&
              jalaliDay.month == current.month;
        },
      );

      final isCurrentMonth = current.year == todayJalali.year &&
          current.month == todayJalali.month;
      final monthStartOffset = offset;
      for (final week in weeks) {
        if (isCurrentMonth &&
            week.any(
                (day) => day != null && TimeManager.isSameDay(day, _today))) {
          _todayOffset = (offset - _weekRowHeight).clamp(0, double.infinity);
        }
        items.add(_WeekRowItem(week));
        offset += _weekRowHeight;
      }

      items.add(_MonthHeaderItem(monthStart));
      headerOffsets.add((offset, monthStart));
      offset += _weekRowHeight;
      if (isCurrentMonth) _currentMonthSpan = (monthStartOffset, offset);

      current = current.addMonths(-1);
    }

    _items = items;
    _monthOffsets = monthOffsets;
    _headerOffsets = headerOffsets;
  }

  /// Where to scroll so the current month sits in the middle of the space
  /// between the pinned month header and the bottom padding (3.7.0.39).
  /// Falls back to today's row before the list has a size.
  double get _homeOffset {
    final span = _currentMonthSpan;
    final controller = widget.scrollController;
    if (span == null ||
        !controller.hasClients ||
        !controller.position.hasViewportDimension) {
      return _todayOffset;
    }
    final position = controller.position;
    final visible =
        position.viewportDimension - _listBottomPadding - _headerBoxHeight;
    final middle = (span.$1 + span.$2) / 2;
    final target = middle - visible / 2;
    final maxExtent =
        position.hasContentDimensions ? position.maxScrollExtent : target;
    return target.clamp(0.0, maxExtent < 0 ? 0.0 : maxExtent);
  }

  void _onHomeTabRetapped() {
    if (mounted) _scrollToToday();
  }

  void _onHomeLand() {
    final land = VerticalCalendar._homeLand.value;
    if (land == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _jumpToMonth(land.$1);
    });
  }

  bool _backToNow() {
    final controller = widget.scrollController;
    if (!mounted || !controller.hasClients) return false;
    if ((controller.offset - _homeOffset).abs() <= _weekRowHeight * 2) {
      return false;
    }
    _scrollToToday();
    return true;
  }

  // The month just landed on, lit in the accent colour then fading back
  DateTime? _flashMonth;
  bool _flashLit = false;
  Timer? _flashTimer;

  void _flash(DateTime monthStart) {
    _flashTimer?.cancel();
    setState(() {
      _flashMonth = monthStart;
      _flashLit = true;
    });
    _flashTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _flashLit = false);
      _flashTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _flashMonth = null);
      });
    });
  }

  /// The month that holds [date]: its start in [_monthOffsets] (newest
  /// first), so it works for Jalali months too.
  (double, DateTime)? _monthHolding(DateTime date) {
    final day = DateUtils.dateOnly(date);
    for (final entry in _monthOffsets) {
      if (!entry.$2.isAfter(day)) return entry;
    }
    return null;
  }

  /// Where to scroll so the month starting at [start] sits in the middle.
  double _centreOffsetFor(DateTime start, double startOffset) {
    final header = _headerOffsets.where((h) => h.$2 == start).firstOrNull;
    final end = (header?.$1 ?? startOffset) + _weekRowHeight;
    final controller = widget.scrollController;
    if (!controller.hasClients || !controller.position.hasViewportDimension) {
      return startOffset;
    }
    final visible = controller.position.viewportDimension -
        _listBottomPadding -
        _headerBoxHeight;
    return ((startOffset + end) / 2 - visible / 2).clamp(0.0, double.infinity);
  }

  void _scrollToToday({bool animate = true}) {
    if (!widget.scrollController.hasClients) return;
    final target = _homeOffset;
    if (animate) {
      widget.scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.scrollController.jumpTo(target);
    }
    _updateVisibleMonthFromOffset(target);
  }

  /// Centres the month holding [month] and flashes it (3.7.0.41).
  void _jumpToMonth(DateTime month) {
    if (!widget.scrollController.hasClients) return;
    final exact = _monthOffsets
        .where((offset) =>
            offset.$2.year == month.year && offset.$2.month == month.month)
        .firstOrNull;
    final monthOffset = exact ?? _monthHolding(month);
    if (monthOffset == null) return;
    _jumpToOffsetIteratively(_centreOffsetFor(monthOffset.$2, monthOffset.$1));
    _updateVisibleMonthFromOffset(monthOffset.$1);
    _flash(monthOffset.$2);
  }

  void _jumpToOffsetIteratively(double target, [double? previousMaxExtent]) {
    if (!mounted || !widget.scrollController.hasClients) return;
    final clamped =
        target.clamp(0.0, widget.scrollController.position.maxScrollExtent);
    widget.scrollController.jumpTo(clamped);

    if (widget.scrollController.offset < target - 1.0) {
      final currentMax = widget.scrollController.position.maxScrollExtent;
      if (previousMaxExtent != null && currentMax <= previousMaxExtent) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToOffsetIteratively(target, currentMax);
      });
    }
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final showToday = (offset - _homeOffset).abs() > _weekRowHeight * 12;
    if (_showTodayButton.value != showToday) {
      _showTodayButton.value = showToday;
    }
    _updateVisibleMonthFromOffset(offset);
    _updateSticky();
  }

  // The header box sits at the bottom of its row, 2px above the row's edge.
  double get _headerBoxHeight => _daysOfWeekRowHeight + 2;

  void _updateSticky() {
    final controller = widget.scrollController;
    if (!controller.hasClients || _headerOffsets.isEmpty) return;
    final position = controller.position;
    if (!position.hasViewportDimension) return;
    final viewport = position.viewportDimension;
    final offset = position.pixels;

    // Top of a month's header box, measured down from the top of the list.
    double headerTop(double rowOffset) =>
        viewport - _listBottomPadding - rowOffset + offset - _headerBoxHeight;

    // Newest first: the first header above the top edge is the pinned month.
    for (var i = 0; i < _headerOffsets.length; i++) {
      final top = headerTop(_headerOffsets[i].$1);
      if (top <= 0) {
        var shift = 0.0;
        if (i > 0) {
          final nextTop = headerTop(_headerOffsets[i - 1].$1);
          if (nextTop < _headerBoxHeight) shift = nextTop - _headerBoxHeight;
        }
        final value = (_headerOffsets[i].$2, shift);
        if (_sticky.value != value) _sticky.value = value;
        return;
      }
    }
    if (_sticky.value.$1 != null) _sticky.value = (null, 0);
  }

  void _updateVisibleMonthFromOffset(double offset) {
    if (_monthOffsets.isEmpty) return;
    // Binary search for current month
    int lo = 0, hi = _monthOffsets.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_monthOffsets[mid].$1 > offset) {
        hi = mid - 1;
      } else {
        lo = mid;
      }
    }
    _visibleMonth = _monthOffsets[lo].$2;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final configProvider = context.watch<ConfigProvider>();
    final firstDayIndex = configProvider.getFirstDayOfWeekIndex(context);
    final showImages = !configProvider.get(Settings.hideImagesInCalendar);
    final showMood = configProvider.get(Settings.calendarShowMood);
    if (_setAllowFuture(configProvider.get(Settings.allowFutureEntries)) &&
        _lastFirstDayIndex != null) {
      _buildCalendarItems(_lastFirstDayIndex!);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToToday(animate: false));
    }
    final entriesProvider = context.watch<EntriesProvider>();
    final attachmentsProvider = context.watch<EntryAttachmentsProvider>();

    final tagsProvider = context.watch<TagsProvider>();
    final overlayTagId = configProvider.get(Settings.calendarTagOverlay);
    final calendarTagOverride = overlayTagId != null
        ? tagsProvider.tags.where((tag) => tag.id == overlayTagId).firstOrNull
        : null;

    // The selected tag may have been deleted since it was saved; revert the
    // persisted setting back to "none" instead of leaving a stale tag id.
    if (overlayTagId != null && calendarTagOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          configProvider.set(Settings.calendarTagOverlay, null);
        }
      });
    }

    final calendarTagEntryMap = overlayTagId != null
        ? {
            for (final entryTag in tagsProvider.entryTags
                .where((entryTag) => entryTag.tagId == overlayTagId))
              entryTag.entryId: entryTag,
          }
        : const <int, EntryTag>{};

    return LayoutBuilder(
      builder: (context, constraints) {
        final newCellWidth = constraints.maxWidth / 7;
        if (newCellWidth != _cellWidth) {
          _cellWidth = newCellWidth;
          _weekRowHeight = newCellWidth;
          _buildCalendarItems(firstDayIndex);
        }

        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        if (_lastDevicePixelRatio != devicePixelRatio ||
            _lastWeekRowHeight != _weekRowHeight) {
          _lastDevicePixelRatio = devicePixelRatio;
          _lastWeekRowHeight = _weekRowHeight;
          _createDayNumberCache(devicePixelRatio);
        }

        if (!_initialScrollDone) {
          _initialScrollDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.scrollController.hasClients) {
              widget.scrollController.jumpTo(_homeOffset);
              _updateSticky();
            }
          });
        }

        return Stack(
            fit: StackFit.loose,
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              Column(
                children: [
                  _buildWeekdayHeader(context, _dayLabels),
                  Expanded(
                    child: Stack(children: [
                      CustomScrollView(
                        controller: widget.scrollController,
                        reverse: true,
                        slivers: [
                          const SliverPadding(
                              padding:
                                  EdgeInsets.only(bottom: _listBottomPadding)),
                          SliverFixedExtentList(
                            itemExtent: _weekRowHeight,
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildItem(
                                  context,
                                  index,
                                  entriesProvider,
                                  attachmentsProvider,
                                  showImages,
                                  showMood,
                                  calendarTagOverride,
                                  calendarTagEntryMap),
                              childCount: _items.length,
                            ),
                          ),
                        ],
                      ),
                      _buildStickyMonth(context),
                    ]),
                  ),
                ],
              ),
              // Shown on the share screen too, with Jump to month only
              _buildCalendarControls(context),
              // Home uses re-tapping Home and Back instead (3.7.0.41)
              if (!widget.followsHomeTab) _buildJumpToTodayButton(context),
            ]);
      },
    );
  }

  /// Today's column in the weekday row, given the first day of the week
  /// (labels start Monday at index 0).
  int get _todayColumn {
    final first = _lastFirstDayIndex ?? 0;
    return (_today.weekday - 1 - first) % 7;
  }

  Widget _buildWeekdayHeader(BuildContext context, List<String> dayLabels) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: SizedBox(
        height: _daysOfWeekRowHeight,
        child: Row(
          children: [
            for (var i = 0; i < dayLabels.length; i++)
              Expanded(
                child: i == _todayColumn
                    // Today's day in the accent colour (3.7.0.40); follows
                    // Use System Accent Color through the theme
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            dayLabels[i],
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          dayLabels[i],
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarControls(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 1,
            margin: EdgeInsets.all(0),
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(80))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // One tap opens Jump to month, on Home and when sharing
                // into the app. Jump to log is gone (3.7.0.49): typing a
                // date in the picker opens that day's entry instead.
                IconButton(
                  tooltip: l10n.jumpToMonthTitle,
                  onPressed: () => _onMonthLabelTap(context),
                  icon: const Icon(Icons.calendar_month_rounded),
                  color: theme.colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  onPressed: () => showAppDialog(
                    context: context,
                    builder: (_) => const CalendarViewOptionsDialog(),
                  ),
                  icon: const Icon(Icons.visibility_rounded),
                  color: theme.colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJumpToTodayButton(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 13.0),
        child: ValueListenableBuilder<bool>(
          valueListenable: _showTodayButton,
          builder: (context, showToday, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final scale = TweenSequence([
                TweenSequenceItem(
                  tween: Tween<double>(begin: 0.0, end: 1.1)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 50,
                ),
                TweenSequenceItem(
                  tween: Tween<double>(begin: 1.1, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeIn)),
                  weight: 50,
                ),
              ]).animate(animation);
              return ScaleTransition(scale: scale, child: child);
            },
            child: showToday
                ? IconButton(
                    color: theme.colorScheme.primary,
                    key: const ValueKey('todayBtn'),
                    onPressed: () => _scrollToToday(),
                    icon: Icon(Icons.arrow_downward_rounded),
                    style: IconButton.styleFrom(
                        elevation: 1,
                        shadowColor: theme.shadowColor,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer),
                  )
                : const SizedBox.shrink(key: ValueKey('noBtn')),
          ),
        ),
      ),
    );
  }

  /// The square showing [day], when it is on screen.
  BuildContext? _cellContextFor(DateTime day) {
    BuildContext? found;
    void visit(Element element) {
      if (found != null) return;
      final cell = element.widget;
      if (cell is EntryDayCell && TimeManager.isSameDay(cell.date, day)) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  Future<void> _onMonthLabelTap(BuildContext context) async {
    final entriesProvider = context.read<EntriesProvider>();
    final entries = entriesProvider.entries;
    // Never one of the greyed months shown after the current one
    final current =
        _visibleMonth.isAfter(_lastDate) ? _lastDate : _visibleMonth;

    // The Jalali calendar keeps the two-dropdown picker
    if (_isJalali) {
      final DateTime? selected = await showYearMonthPicker(context,
          initialDate: current,
          isJalali: true,
          firstYear: YearMonthRange.firstYearFor(
              entries.map((entry) => entry.timeCreate)),
          // Runs ahead of today when future entries are on
          lastDate: _lastDate);
      if (selected == null) return;
      _jumpToMonth(selected);
      return;
    }

    // Sharing into the app can go to any day, so empty months stay open
    final sharing = widget.onDaySelected != null;
    final picked = await JumpPicker.show(
      context,
      entryDates: entries.map((entry) => entry.timeCreate),
      selected: current,
      lastYear: _lastDate.year,
      allowEmpty: sharing,
      firstDate: sharing ? _firstDate : null,
      lastDate: sharing ? FutureEntries.lastPickableDate() : null,
    );
    if (picked == null || !mounted) return;
    _jumpToMonth(picked.month);
    final day = picked.day;
    if (day == null || !context.mounted) return;

    // A typed date
    if (sharing) {
      // Picks that day as the one being shared into, once the calendar
      // has settled on its month so the day's menu opens beside its square
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || !context.mounted) return;
      widget.onDaySelected!(_cellContextFor(day) ?? context, day);
      return;
    }
    final dayEntries = entriesProvider.getEntriesForDate(day);
    if (dayEntries.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .jumpNoEntriesOnDay(TimeManager.formatDate(day, context))),
        ));
    } else if (dayEntries.length == 1) {
      await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => EntriesListPage(
          index: entriesProvider.getIndexOfEntry(dayEntries.first.id!),
          getEntries: () => entriesProvider.entries,
        ),
      ));
    } else {
      await EntryTimelinePage.pushForDay(context, day);
    }
  }

  Widget _buildItem(
      BuildContext context,
      int index,
      EntriesProvider entriesProvider,
      EntryAttachmentsProvider attachmentsProvider,
      bool showImages,
      bool showMood,
      Tag? calendarTagOverride,
      Map<int, EntryTag> calendarTagEntryMap) {
    final item = _items[index];
    if (item is _MonthHeaderItem) return _buildMonthHeader(context, item.month);
    if (item is _WeekRowItem) {
      return _buildWeekRow(context, item, entriesProvider, attachmentsProvider,
          showImages, showMood, calendarTagOverride, calendarTagEntryMap);
    }
    return const SizedBox.shrink();
  }

  /// The current month, pinned to the top of the calendar while scrolling.
  /// The next month's header pushes it off as it arrives.
  Widget _buildStickyMonth(BuildContext context) {
    return ValueListenableBuilder<(DateTime?, double)>(
      valueListenable: _sticky,
      builder: (context, sticky, _) {
        final month = sticky.$1;
        if (month == null) return const SizedBox.shrink();
        return Positioned(
          top: sticky.$2,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _monthHeaderBox(context, month),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthHeader(BuildContext context, DateTime month) {
    return SizedBox(
      height: _weekRowHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _monthHeaderBox(context, month),
      ),
    );
  }

  Widget _monthHeaderBox(BuildContext context, DateTime month) {
    final scheme = Theme.of(context).colorScheme;
    final lit = _flashLit && _flashMonth == month;
    return AnimatedContainer(
      // Lights up fast, fades back slowly
      duration: Duration(milliseconds: lit ? 150 : 1100),
      curve: Curves.easeOut,
      height: _daysOfWeekRowHeight,
      margin: const EdgeInsets.only(bottom: 2.0),
      decoration: BoxDecoration(
        color: lit ? scheme.primary : scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: Duration(milliseconds: lit ? 150 : 1100),
          style: DefaultTextStyle.of(context).style.copyWith(
              fontSize: 16,
              // The current month stands out in bold (3.7.0.40)
              fontWeight:
                  _isCurrentMonth(month) ? FontWeight.w800 : FontWeight.w500,
              // Upcoming months shown only for spacing are greyed out
              color: lit
                  ? scheme.onPrimary
                  : _isGreyMonth(month)
                      ? Theme.of(context).disabledColor
                      : scheme.onSurface),
          child: Text(TimeManager.formatMonthYear(month, context)),
        ),
      ),
    );
  }

  bool _isCurrentMonth(DateTime monthStart) {
    if (_isJalali) {
      final today = Jalali.fromDateTime(_today);
      final month = Jalali.fromDateTime(monthStart);
      return today.year == month.year && today.month == month.month;
    }
    return monthStart.year == _today.year && monthStart.month == _today.month;
  }

  bool _isGreyMonth(DateTime monthStart) =>
      !_allowFuture && monthStart.isAfter(_today);

  Widget _buildWeekRow(
      BuildContext context,
      _WeekRowItem item,
      EntriesProvider entriesProvider,
      EntryAttachmentsProvider attachmentsProvider,
      bool showImages,
      bool showMood,
      Tag? calendarTagOverride,
      Map<int, EntryTag> calendarTagEntryMap) {
    return RepaintBoundary(
      child: _WeekRow(
        days: item.days,
        today: _today,
        cellSize: _cellWidth,
        dayNumberCache: _dayNumberCache,
        entriesProvider: entriesProvider,
        attachmentsProvider: attachmentsProvider,
        showImages: showImages,
        showMood: showMood,
        isJalali: _isJalali,
        allowFuture: _allowFuture,
        calendarTagOverride: calendarTagOverride,
        calendarTagEntryMap: calendarTagEntryMap,
        onSelectDay: widget.onDaySelected,
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<DateTime?> days;
  final DateTime today;
  final double cellSize;
  final Map<int, ui.Image> dayNumberCache;
  final EntriesProvider entriesProvider;
  final EntryAttachmentsProvider attachmentsProvider;
  final bool showImages;
  final bool showMood;
  final bool isJalali;
  final bool allowFuture;
  final Tag? calendarTagOverride;
  final Map<int, EntryTag> calendarTagEntryMap;
  final void Function(BuildContext context, DateTime date)? onSelectDay;

  const _WeekRow({
    required this.days,
    required this.today,
    required this.cellSize,
    required this.dayNumberCache,
    required this.entriesProvider,
    required this.attachmentsProvider,
    required this.showImages,
    required this.showMood,
    this.isJalali = false,
    this.allowFuture = false,
    this.calendarTagOverride,
    this.calendarTagEntryMap = const {},
    this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cellSize,
      child: Row(
        children: days.map((day) {
          if (day == null) {
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }

          final isFuture = !allowFuture &&
              day.isAfter(today) &&
              !TimeManager.isSameDay(day, today);
          if (isFuture) {
            final futureDayNum =
                isJalali ? TimeManager.jalaliDayNumber(day) : day.day;
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$futureDayNum',
                    style: TextStyle(
                        fontSize: 16, color: Theme.of(context).disabledColor),
                  ),
                ),
              ),
            );
          }

          final entries = entriesProvider.getEntriesForDate(day);
          final coverCandidates = !showImages
              ? const <EntryAttachment>[]
              : entries
                  .map((entry) =>
                      attachmentsProvider.getCoverCandidatesForEntry(entry.id!))
                  .firstWhere((candidates) => candidates.isNotEmpty,
                      orElse: () => const []);

          final displayDayNum =
              isJalali ? TimeManager.jalaliDayNumber(day) : day.day;

          return SizedBox(
            width: cellSize,
            height: cellSize,
            child: EntryDayCell(
              date: day,
              today: today,
              entries: entries,
              coverCandidates: coverCandidates,
              cellSize: cellSize,
              dayNumber: dayNumberCache[displayDayNum],
              showImages: showImages,
              showMood: showMood,
              isJalali: isJalali,
              calendarTagOverride: calendarTagOverride,
              calendarTagEntryMap: calendarTagEntryMap,
              onSelectDay: onSelectDay,
            ),
          );
        }).toList(),
      ),
    );
  }
}
