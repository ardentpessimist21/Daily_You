// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/selection_actions.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class EntryTimelinePage extends StatefulWidget {
  const EntryTimelinePage({
    super.key,
    required this.header,
    required this.getEntries,
    required this.labelBuilder,
    this.addEntryDate,
    this.swipeDays = false,
  });

  final String header;
  final List<Entry> Function() getEntries;
  final String Function(BuildContext, Entry) labelBuilder;

  /// When set, an add button creates a new entry on this day. Left null for
  /// timelines that span several days, such as "On this day".
  final DateTime? addEntryDate;

  /// Day timelines only: swipe left or right to move to the next or previous
  /// day with entries. The header, entries and add button follow the day.
  final bool swipeDays;

  /// Pushes a timeline listing every entry created on [date], with each
  /// entry labeled by its time of day and an add button for that day.
  static Future<void> pushForDay(BuildContext context, DateTime date) {
    final title = TimeManager.formatDate(date, context);
    return Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntryTimelinePage(
        header: title,
        getEntries: () => EntriesProvider.instance.entries
            .where((entry) => TimeManager.isSameDay(entry.timeCreate, date))
            .toList(),
        addEntryDate: date,
        swipeDays: true,
        labelBuilder: (context, entry) => TimeManager.localizedTimeFormat(
                context, TimeManager.currentLocale(context))
            .format(entry.timeCreate),
      ),
    ));
  }

  @override
  State<EntryTimelinePage> createState() => _EntryTimelinePageState();
}

class _EntryTimelinePageState extends State<EntryTimelinePage> {
  // The day shown, for swipeable day timelines.
  late DateTime? _day = widget.swipeDays && widget.addEntryDate != null
      ? DateUtils.dateOnly(widget.addEntryDate!)
      : null;
  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  // Every day with at least one entry, oldest first.
  static List<DateTime> _daysWithEntries() {
    final days = EntriesProvider.instance.entries
        .map((entry) => DateUtils.dateOnly(entry.timeCreate))
        .toSet()
        .toList()
      ..sort();
    return days;
  }

  static List<Entry> _entriesOn(DateTime day) =>
      EntriesProvider.instance.entries
          .where((entry) => TimeManager.isSameDay(entry.timeCreate, day))
          .toList();

  void _onDayChanged(DateTime day) {
    setState(() {
      _day = day;
      _selected.clear();
    });
  }

  // Entry ids picked in select mode (started by long-pressing a card)
  final Set<int> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelected(Entry entry) {
    final id = entry.id;
    if (id == null) return;
    setState(() =>
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  }

  List<Entry> _selectedEntries(List<Entry> entries) =>
      entries.where((entry) => _selected.contains(entry.id)).toList();

  PreferredSizeWidget _selectionAppBar(List<Entry> entries) {
    // Captured now: deleting a day's last entries closes the timeline,
    // and the message should still show
    final messenger = ScaffoldMessenger.of(context);
    return SelectionAppBar(
      selected: _selectedEntries(entries),
      all: entries,
      onClear: () => setState(_selected.clear),
      onSelectAll: () => setState(
          () => _selected.addAll(entries.map((entry) => entry.id).nonNulls)),
      onDone: (message) {
        if (mounted) setState(_selected.clear);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
          ));
      },
    );
  }

  void _showStatus(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ));
  }

  Future<void> _addEntry(DateTime date) async {
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => AddEditEntryPage(
        overrideCreateDate:
            TimeManager.currentTimeOnDifferentDate(date).copyWith(isUtc: false),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<EntriesProvider>(context);
    final entryAttachmentsProvider =
        Provider.of<EntryAttachmentsProvider>(context);

    final configProvider = Provider.of<ConfigProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    final showFullEntries =
        configProvider.get(Settings.timelineShowFullEntries);
    final oldestFirst = configProvider.get(Settings.timelineOldestFirst);
    final day = _day;
    final addEntryDate = day ?? widget.addEntryDate;
    final header =
        day != null ? TimeManager.formatDate(day, context) : widget.header;

    List<Entry> sorted(List<Entry> list) => List<Entry>.from(list)
      ..sort((a, b) => oldestFirst
          ? a.timeCreate.compareTo(b.timeCreate)
          : b.timeCreate.compareTo(a.timeCreate));

    final entries = sorted(day != null ? _entriesOn(day) : widget.getEntries());

    final days = day != null ? _daysWithEntries() : const <DateTime>[];
    final dayIndex = days.indexOf(day ?? DateTime(0));
    if (day != null && dayIndex >= 0) {
      final controller =
          _pageController ??= PageController(initialPage: dayIndex);
      // Keep the pager on this day if days were added or removed elsewhere.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !controller.hasClients) return;
        final page = controller.page?.round();
        if (page != null &&
            page != dayIndex &&
            !controller.position.isScrollingNotifier.value) {
          controller.jumpToPage(dayIndex);
        }
      });
    }

    _selected.removeWhere((id) => !entries.any((entry) => entry.id == id));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entries.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    });

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: _selecting
            ? _selectionAppBar(entries)
            : AppBar(
                title: Text(header),
                actions: [
                  IconButton(
                    tooltip: oldestFirst
                        ? localizations.timelineOldestFirst
                        : localizations.timelineNewestFirst,
                    icon: Transform.flip(
                      flipY: oldestFirst,
                      child: const Icon(Icons.sort_rounded),
                    ),
                    onPressed: () async {
                      await configProvider.set(
                          Settings.timelineOldestFirst, !oldestFirst);
                      if (!mounted) return;
                      _showStatus(!oldestFirst
                          ? localizations.timelineOldestFirst
                          : localizations.timelineNewestFirst);
                    },
                  ),
                  IconButton(
                    tooltip: showFullEntries
                        ? localizations.timelineShowPreviews
                        : localizations.timelineShowFullEntries,
                    isSelected: showFullEntries,
                    icon: const Icon(Icons.open_in_full_rounded),
                    selectedIcon: const Icon(Icons.close_fullscreen_rounded),
                    onPressed: () async {
                      await configProvider.set(
                          Settings.timelineShowFullEntries, !showFullEntries);
                      if (!mounted) return;
                      _showStatus(!showFullEntries
                          ? localizations.timelineShowFullEntries
                          : localizations.timelineShowPreviews);
                    },
                  ),
                  if (addEntryDate != null)
                    IconButton(
                      tooltip: localizations.timelineAddEntry,
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => _addEntry(addEntryDate),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
        body: day != null && dayIndex >= 0
            ? PageView.builder(
                controller: _pageController,
                itemCount: days.length,
                onPageChanged: (index) => _onDayChanged(days[index]),
                itemBuilder: (context, index) => days[index] == day
                    ? _entryList(
                        entries, showFullEntries, entryAttachmentsProvider)
                    : _entryList(sorted(_entriesOn(days[index])),
                        showFullEntries, entryAttachmentsProvider),
              )
            : _entryList(entries, showFullEntries, entryAttachmentsProvider),
      ),
    );
  }

  Widget _entryList(List<Entry> entries, bool showFullEntries,
      EntryAttachmentsProvider entryAttachmentsProvider) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final entryAttachments = entryAttachmentsProvider
            .getForEntry(entry)
            .where((attachment) => attachment.type.isVisual)
            .toList();
        final label = widget.labelBuilder(context, entry);
        void openEntry() {
          final id = entry.id;
          if (id == null) return;
          Navigator.of(context).push(MaterialPageRoute(
            allowSnapshotting: false,
            builder: (context) => EntriesListPage(
              index: EntriesProvider.instance.getIndexOfEntry(id),
              getEntries: () => EntriesProvider.instance.entries,
            ),
          ));
        }

        final isSelected = _selected.contains(entry.id);
        void onTap() => _selecting ? _toggleSelected(entry) : openEntry();
        void onLongPress() => _toggleSelected(entry);

        if (showFullEntries) {
          return _FullEntryTimelineRow(
            isFirst: index == 0,
            isLast: index == entries.length - 1,
            selecting: _selecting,
            selected: isSelected,
            onTap: onTap,
            onLongPress: onLongPress,
            child: SelectionOutline(
              selected: isSelected,
              child: FullEntryCardWidget(
                title: label,
                entry: entry,
                attachments: entryAttachments,
                locationsEnabled: !_selecting,
              ),
            ),
          );
        }

        return AspectRatio(
          aspectRatio: 2.2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Container(
                      width: 3,
                      height: 12,
                      color: index == 0
                          ? Colors.transparent
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    _RailDot(selecting: _selecting, selected: isSelected),
                    Expanded(
                      child: Container(
                        width: 3,
                        color: index == entries.length - 1
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: GestureDetector(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: SelectionOutline(
                      selected: isSelected,
                      child: LargeEntryCardWidget(
                        title: label,
                        entry: entry,
                        attachments: entryAttachments,
                        showLocations: true,
                        locationsEnabled: !_selecting,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A timeline row that grows to fit its card, drawing the rail (line and
/// dot) down the left side to match whatever height the card ends up.
class _FullEntryTimelineRow extends StatelessWidget {
  const _FullEntryTimelineRow({
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
    required this.selecting,
    required this.selected,
    required this.child,
  });

  static const double _railWidth = 36;
  static const double _lineWidth = 3;
  static const double _dotSize = 14;
  static const double _dotTop = 12;

  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selecting;
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final railColor = Theme.of(context).colorScheme.outlineVariant;
    const lineLeft = (_railWidth - _lineWidth) / 2;
    const dotCenter = _dotTop + _dotSize / 2;
    return Stack(
      children: [
        if (!isFirst)
          Positioned(
            left: lineLeft,
            top: 0,
            width: _lineWidth,
            height: dotCenter,
            child: ColoredBox(color: railColor),
          ),
        if (!isLast)
          Positioned(
            left: lineLeft,
            top: dotCenter,
            bottom: 0,
            width: _lineWidth,
            child: ColoredBox(color: railColor),
          ),
        Positioned(
          left: 0,
          width: _railWidth,
          top: _dotTop + _dotSize / 2 - _RailDot.selectingSize / 2,
          height: _RailDot.selectingSize,
          child:
              Center(child: _RailDot(selecting: selecting, selected: selected)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _railWidth, right: 8, bottom: 8),
          child: GestureDetector(
              onTap: onTap, onLongPress: onLongPress, child: child),
        ),
      ],
    );
  }
}

/// The dot on the timeline rail; becomes a checkbox in select mode.
class _RailDot extends StatelessWidget {
  const _RailDot({required this.selecting, required this.selected});

  static const double size = 14;
  static const double selectingSize = 22;

  final bool selecting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!selecting) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: colorScheme.outlineVariant),
      );
    }
    return Container(
      width: selectingSize,
      height: selectingSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colorScheme.primary : colorScheme.surface,
        border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline,
            width: 2),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 15, color: colorScheme.onPrimary)
          : null,
    );
  }
}
