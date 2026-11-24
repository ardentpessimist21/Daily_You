// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/gallery_filters.dart';
import 'package:daily_you/fork/moods.dart';
import 'package:daily_you/fork/place_filter.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/fork/selection_actions.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/future_entries.dart';
import 'package:daily_you/fork/jump_picker.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:daily_you/widgets/action_pill.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// What a Gallery opened from Statistics starts with (3.7.0.48): a tag, a
/// place or a word to search. It keeps its own search, so the Gallery tab
/// isn't changed.
class GalleryPreset {
  const GalleryPreset({this.tagId, this.place, this.search});

  final int? tagId;
  final String? place;
  final String? search;
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, this.preset});

  final GalleryPreset? preset;

  /// Bumped when the Gallery tab is tapped while already open (3.7.0.59):
  /// the list goes back to the top, whichever way it's sorted.
  static final ValueNotifier<int> tabRetapped = ValueNotifier(0);

  /// Back on the Gallery tab (3.7.0.64): while entries are selected it
  /// clears the selection instead of going to Home. True when it did.
  static bool Function()? _backHandler;
  static bool handleBack() => _backHandler?.call() ?? false;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

/// One day (Timeline view) or month (Grid view) of the Gallery, with where
/// its entries start in the flat list.
class _GallerySection {
  _GallerySection(this.date, this.start);

  final DateTime date;
  final int start;
  final List<Entry> entries = [];
}

enum _ItemKind { space, upcoming, monthLabel, pill, row, gridRow }

/// One row of the Gallery's list, with its height.
class _Item {
  _Item(this.kind, this.extent,
      {this.entry,
      this.index = 0,
      this.first = false,
      this.last = false,
      this.timeOnly = false,
      this.date,
      this.count = 0,
      this.tiles,
      this.tileSize = 0,
      this.columns = 1});

  _Item.space(double extent) : this(_ItemKind.space, extent);

  final _ItemKind kind;
  final double extent;
  final Entry? entry;

  /// Where the row's (first) entry sits in the Gallery's list.
  final int index;
  final bool first;
  final bool last;
  final bool timeOnly;
  final DateTime? date;
  final int count;
  final List<Entry>? tiles;
  final double tileSize;
  final int columns;
}

class _GalleryPageState extends State<GalleryPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode = FocusNode();

  List<int> _filterTagIds = [];
  TagFilterMode _filterTagMode = TagFilterMode.any;
  bool _filterNoTags = false;

  // Quick filters: Favourite and pinned tags that are on, and Last Edited.
  // Like tag filters they last until the app restarts.
  Set<int> _quickTagIds = {};
  bool _lastEdited = false;

  /// Media Quick filters (3.7.0.59).
  Set<MediaFilter> _media = {};

  /// 📍 Places: the picked place's name (3.7.0.40).
  String? _place;

  /// Date filter (3.7.0.59, by day since 3.7.0.64): the first and last day
  /// shown, or null for every day. Months and years are whole runs of days.
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool get _hasDateFilter => _dateFrom != null;

  /// Mood (3.7.0.64): moods picked, null for No mood.
  Set<int?> _moods = {};

  /// Trackers (3.7.0.64): tracker tags picked.
  Set<int> _trackerIds = {};

  /// Keywords (3.7.0.64).
  KeywordFilter _keywords = const KeywordFilter();

  /// The pill row folded to icons only (remembered).
  bool _iconsOnly = GalleryFilterRow.savedCompact;

  /// Opened from Statistics: this page's own search, apart from the tab's.
  String? _localSearch;
  String get _searchText => _localSearch ?? EntriesProvider.instance.searchText;
  void _setSearchText(String text) {
    if (_localSearch != null) {
      setState(() => _localSearch = text);
    } else {
      EntriesProvider.instance.searchText = text;
    }
  }

  bool get _hasTagFilter =>
      _filterTagIds.isNotEmpty ||
      _filterNoTags ||
      _quickTagIds.isNotEmpty ||
      _lastEdited ||
      _place != null ||
      _media.isNotEmpty ||
      _moods.isNotEmpty ||
      _trackerIds.isNotEmpty ||
      _keywords.isOn ||
      _hasDateFilter;

  // Entry ids picked in select mode (started by long-pressing a tile)
  final Set<int> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelected(Entry entry) {
    final id = entry.id;
    if (id == null) return;
    setState(() =>
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  }

  /// After an action changed or deleted the selection.
  void Function(String) _onSelectionDone() {
    final messenger = ScaffoldMessenger.of(context);
    return (message) {
      if (mounted) setState(_selected.clear);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ));
    };
  }

  /// Select mode (3.7.0.59, like the Timeline): the bar keeps ✕, the count
  /// and Select all; the actions sit in the pill at the bottom.
  Widget _selectionBar(List<Entry> entries) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8, left: 8, right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: SelectionAppBar(
            selected:
                entries.where((entry) => _selected.contains(entry.id)).toList(),
            all: entries,
            showActions: false,
            onClear: () => setState(_selected.clear),
            onSelectAll: () => setState(() =>
                _selected.addAll(entries.map((entry) => entry.id).nonNulls)),
            onDone: _onSelectionDone(),
          ),
        ),
      ),
    );
  }

  // Heights of the floating header: the search (or selection) bar, and the
  // row of filter chips under it when any are on.
  static const double _barHeight = 68;
  static const double _chipRowHeight = GalleryFilterRow.height;
  static const double _upcomingRowHeight = 60;
  static const double _gridSpacing = 1.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    if (preset != null) {
      _localSearch = preset.search ?? '';
      if (preset.tagId != null) _filterTagIds = [preset.tagId!];
      _place = preset.place;
    }
    _searchController.text = _searchText;
    _scrollController.addListener(_onScroll);
    _snap.addListener(_onSnap);
    if (preset == null) {
      GalleryPage.tabRetapped.addListener(_backToTop);
      GalleryPage._backHandler = _onBack;
    }
  }

  bool _onBack() {
    if (!_selecting) return false;
    setState(_selected.clear);
    return true;
  }

  /// Re-tapping the Gallery tab: back to the top of the list, with the
  /// search bar and chips showing again.
  void _backToTop() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  /// Lets go of the search bar before opening something on top, so the
  /// keyboard doesn't come back up on return (3.7.0.39). The typed search
  /// stays; tapping the search bar brings the keyboard back.
  void _dropSearchFocus() => _focusNode.unfocus();

  /// Shows only [fromDay] to [toDay] (null clears it).
  void _setDateFilter(DateTime? fromDay, DateTime? toDay) {
    setState(() {
      _dateFrom = fromDay;
      _dateTo = toDay ?? fromDay;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  /// Whole months [from] to [to].
  void _setMonthFilter(DateTime from, DateTime to) => _setDateFilter(
      DateTime(from.year, from.month), DateTime(to.year, to.month + 1, 0));

  /// The month picker (3.7.0.59): picking a month (or a range) shows only
  /// those months; Show all clears it. A typed date still opens that entry.
  Future<void> _pickMonthFilter(DateTime around) async {
    _dropSearchFocus();
    final unfiltered = FutureEntries.past(_getVisibleEntries(
        EntriesProvider.instance, TagsProvider.instance,
        ignoreMonth: true));
    final from = _dateFrom;
    final to = _dateTo;
    final fromMonth = from == null ? null : DateTime(from.year, from.month);
    final toMonth = to == null ? null : DateTime(to.year, to.month);
    final picked = await JumpPicker.show(context,
        entryDates: unfiltered.map((entry) => entry.timeCreate),
        selected: fromMonth ?? around,
        selectedEnd:
            fromMonth != null && toMonth != null && toMonth != fromMonth
                ? toMonth
                : null,
        allowRange: true,
        filterMode: true,
        showAllButton: _hasDateFilter);
    if (picked == null || !mounted) return;
    if (picked.showAll) {
      _setDateFilter(null, null);
      return;
    }
    if (picked.fromDay != null) {
      _setDateFilter(picked.fromDay, picked.toDay);
      return;
    }
    final day = picked.day;
    if (day != null) {
      final index = unfiltered
          .indexWhere((entry) => TimeManager.isSameDay(entry.timeCreate, day));
      if (index >= 0) {
        await _openEntryAt(index, ignoreMonth: true);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .jumpNoEntriesOnDay(TimeManager.formatDate(day, context))),
          ));
      }
      return;
    }
    _setMonthFilter(picked.month, picked.endMonth ?? picked.month);
  }

  /// Opens the entry at [index] of the Gallery's list, as tapping it does.
  Future<void> _openEntryAt(int index, {bool ignoreMonth = false}) async {
    _dropSearchFocus();
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => EntriesListPage(
              index: index,
              searchQuery: _searchText,
              newestFirst:
                  EntriesProvider.instance.sortOrder != SortOrder.ascending,
              getEntries: () => FutureEntries.past(_getVisibleEntries(
                EntriesProvider.instance,
                TagsProvider.instance,
                ignoreMonth: ignoreMonth,
              )),
            )));
  }

  Future<void> _openUpcoming() async {
    _dropSearchFocus();
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntryTimelinePage(
        header: AppLocalizations.of(context)!.upcomingTitle,
        getEntries: () =>
            FutureEntries.upcoming(EntriesProvider.instance.entries),
        labelBuilder: (context, entry) =>
            '${TimeManager.formatDateWithWeekday(entry.timeCreate, context)} · '
            '${TimeManager.localizedTimeFormat(context, TimeManager.currentLocale(context)).format(entry.timeCreate)}',
      ),
    ));
  }

  @override
  void dispose() {
    GalleryPage.tabRetapped.removeListener(_backToTop);
    if (GalleryPage._backHandler == _onBack) GalleryPage._backHandler = null;
    _snap.dispose();
    _headerHidden.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Entry> _getVisibleEntries(
      EntriesProvider entriesProvider, TagsProvider tagsProvider,
      {bool ignoreMonth = false}) {
    final filtered = _applyTagFilter(
        _localSearch != null
            ? entriesProvider.filteredFor(_localSearch!)
            : entriesProvider.getFilteredEntries(),
        tagsProvider);
    final sorted = _applyTrackerSort(filtered, entriesProvider, tagsProvider);
    // Quick filters and Places also combine with No Tags (3.7.0.40)
    var result = QuickFilters.apply(sorted,
        tagIds: _quickTagIds,
        lastEdited: _lastEdited,
        ascending: entriesProvider.sortOrder == SortOrder.ascending);
    final place = _place;
    if (place != null) {
      result =
          result.where((entry) => PlaceFilter.matches(entry, place)).toList();
    }
    result = MediaFilter.apply(result, _media);
    result = MoodFilter.apply(result, _moods);
    result = TrackerFilter.apply(result, _trackerIds);
    result = _keywords.apply(result);
    final from = _dateFrom;
    final to = _dateTo ?? from;
    if (!ignoreMonth && from != null && to != null) {
      final low = DateTime(from.year, from.month, from.day);
      final high = DateTime(to.year, to.month, to.day + 1);
      result = result.where((entry) {
        final time = entry.timeCreate;
        return !time.isBefore(low) && time.isBefore(high);
      }).toList();
    }
    return result;
  }

  List<Entry> _applyTagFilter(List<Entry> entries, TagsProvider tagsProvider) {
    if (_filterNoTags) {
      // ⭐ Favourite doesn't count as a tag here
      return entries.where(PlaceFilter.isUntagged).toList();
    }
    if (_filterTagIds.isEmpty) return entries;
    return entries.where((entry) {
      final entryTagIds = tagsProvider
          .getEntryTagsForEntry(entry.id ?? -1)
          .map((entryTag) => entryTag.tagId)
          .toSet();
      return _filterTagMode == TagFilterMode.all
          ? _filterTagIds.every((tagId) => entryTagIds.contains(tagId))
          : _filterTagIds.any((tagId) => entryTagIds.contains(tagId));
    }).toList();
  }

  List<Entry> _applyTrackerSort(List<Entry> entries,
      EntriesProvider entriesProvider, TagsProvider tagsProvider) {
    final trackerTagId = entriesProvider.trackerSortTagId;
    if (entriesProvider.orderBy != OrderBy.tracker || trackerTagId == null) {
      return entries;
    }
    final ascending = entriesProvider.sortOrder == SortOrder.ascending;

    double? trackerValue(Entry entry) {
      final rawValue = tagsProvider
          .getEntryTagsForEntry(entry.id ?? -1)
          .where((entryTag) => entryTag.tagId == trackerTagId)
          .firstOrNull
          ?.value;
      return double.tryParse(rawValue ?? '');
    }

    final valuesByEntryId = {
      for (final entry in entries) entry.id: trackerValue(entry)
    };

    final withValue =
        entries.where((entry) => valuesByEntryId[entry.id] != null).toList();
    final withoutValue =
        entries.where((entry) => valuesByEntryId[entry.id] == null).toList();

    withValue.sort((a, b) {
      final comparison = ascending
          ? valuesByEntryId[a.id]!.compareTo(valuesByEntryId[b.id]!)
          : valuesByEntryId[b.id]!.compareTo(valuesByEntryId[a.id]!);
      if (comparison != 0) return comparison;
      return ascending
          ? a.timeCreate.compareTo(b.timeCreate)
          : b.timeCreate.compareTo(a.timeCreate);
    });

    withoutValue.sort((a, b) => ascending
        ? a.timeCreate.compareTo(b.timeCreate)
        : b.timeCreate.compareTo(a.timeCreate));

    // Entries without a numeric tracker value are always listed after those
    // with one, regardless of sort direction.
    return [...withValue, ...withoutValue];
  }

  void _showTagFilterDialog(BuildContext context) {
    _dropSearchFocus();
    showAppDialog(
      context: context,
      builder: (_) => TagPickerDialog(
        mode: TagPickerMode.filter,
        initialSelectedTagIds: List.from(_filterTagIds),
        initialFilterMode: _filterTagMode,
        initialNoTagsOnly: _filterNoTags,
        initialQuickTagIds: _quickTagIds,
        initialLastEdited: _lastEdited,
        onQuickFiltersChanged: (tagIds, lastEdited) => setState(() {
          _quickTagIds = tagIds;
          _lastEdited = lastEdited;
        }),
        initialPlace: _place,
        onPlaceChanged: (place) => setState(() => _place = place),
        placeEntries: EntriesProvider.instance.entries,
        initialMedia: _media,
        onMediaChanged: (media) => setState(() => _media = media),
        resultCount: () => _visibleCount(),
        onFilterChanged: (tagIds, mode, noTagsOnly) {
          setState(() {
            _filterTagIds = tagIds;
            _filterTagMode = mode;
            _filterNoTags = noTagsOnly;
          });
        },
      ),
    );
  }

  void _showSortSelectionPopup(BuildContext context) {
    _dropSearchFocus();
    final entriesProvider =
        Provider.of<EntriesProvider>(context, listen: false);
    final tagsProvider = Provider.of<TagsProvider>(context, listen: false);
    showAppDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final trackerTag = entriesProvider.trackerSortTagId != null
              ? tagsProvider.tags
                  .where((tag) => tag.id == entriesProvider.trackerSortTagId)
                  .firstOrNull
              : null;

          Future<void> handleTrackerTap() async {
            final previousOrderBy = entriesProvider.orderBy;
            setDialogState(() => entriesProvider.orderBy = OrderBy.tracker);

            final tag = await showAppDialog<Tag>(
              context: context,
              builder: (_) => TagPickerDialog(
                mode: TagPickerMode.selectSingle,
                tagTypeFilter: TagType.tracker,
              ),
            );

            if (tag != null) {
              setDialogState(() => entriesProvider.trackerSortTagId = tag.id);
            } else if (previousOrderBy != OrderBy.tracker) {
              setDialogState(() => entriesProvider.orderBy = previousOrderBy);
            }
          }

          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroup<OrderBy>(
                  groupValue: entriesProvider.orderBy,
                  onChanged: (value) {
                    final tappedTracker = value == OrderBy.tracker ||
                        (value == null &&
                            entriesProvider.orderBy == OrderBy.tracker);
                    if (tappedTracker) {
                      handleTrackerTap();
                    } else if (value != null) {
                      setDialogState(() {
                        entriesProvider.orderBy = value;
                        entriesProvider.trackerSortTagId = null;
                      });
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<OrderBy>(
                        value: OrderBy.date,
                        title:
                            Text(AppLocalizations.of(context)!.sortDateTitle),
                      ),
                      RadioListTile<OrderBy>(
                        value: OrderBy.mood,
                        title: Text(AppLocalizations.of(context)!.tagMoodTitle),
                      ),
                      RadioListTile<OrderBy>(
                        value: OrderBy.tracker,
                        toggleable: true,
                        title: Text(
                            AppLocalizations.of(context)!.tagTypeTrackerTitle),
                        subtitle: trackerTag != null
                            ? Text(
                                trackerTag.name,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                RadioGroup<SortOrder>(
                  groupValue: entriesProvider.sortOrder,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => entriesProvider.sortOrder = value);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<SortOrder>(
                        value: SortOrder.ascending,
                        title: Text(AppLocalizations.of(context)!
                            .sortOrderAscendingTitle),
                      ),
                      RadioListTile<SortOrder>(
                        value: SortOrder.descending,
                        title: Text(AppLocalizations.of(context)!
                            .sortOrderDescendingTitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  /// Clears every filter; the search text stays (3.7.0.64).
  void _clearFilters() {
    setState(() {
      _filterTagIds = [];
      _filterTagMode = TagFilterMode.any;
      _filterNoTags = false;
      _quickTagIds = {};
      _lastEdited = false;
      _place = null;
      _media = {};
      _moods = {};
      _trackerIds = {};
      _keywords = const KeywordFilter();
      _dateFrom = null;
      _dateTo = null;
    });
  }

  /// The search bar's ✕: clears the filters, or the search text when no
  /// filter is on.
  void _clearAll() {
    if (_hasTagFilter) {
      _clearFilters();
      return;
    }
    _searchController.clear();
    _setSearchText("");
  }

  /// How many logs the Gallery shows right now, for the pickers' buttons.
  int _visibleCount() => FutureEntries.past(
          _getVisibleEntries(EntriesProvider.instance, TagsProvider.instance))
      .length;

  Widget _searchBar(BuildContext context, EntriesProvider entriesProvider,
      int count, bool showClear) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8, left: 8, right: 8),
      child: SearchBar(
        focusNode: _focusNode,
        controller: _searchController,
        elevation: const WidgetStatePropertyAll(0),
        leading: Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        trailing: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final rotationAnimation =
                  Tween<double>(begin: 0.0, end: 0.5).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );

              final scaleAnimation = TweenSequence([
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

              return RotationTransition(
                turns: rotationAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              );
            },
            // Clears every filter (the search text stays), or the search
            // text when no filter is on
            child: showClear
                ? IconButton(
                    visualDensity:
                        VisualDensity(horizontal: VisualDensity.minimumDensity),
                    key: ValueKey('clearButton'),
                    icon: Icon(Icons.clear),
                    onPressed: _clearAll,
                  )
                : SizedBox.shrink(key: ValueKey('empty')),
          ),
          if (_searchText.isNotEmpty || _hasTagFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(AppLocalizations.of(context)!.logCount(count)),
            ),
          // Shows the direction (3.7.0.41): lines long to short for newest
          // first; flipped and in the accent colour for oldest first
          IconButton(
            tooltip: entriesProvider.sortOrder == SortOrder.ascending
                ? AppLocalizations.of(context)!.sortOrderAscendingTitle
                : AppLocalizations.of(context)!.sortOrderDescendingTitle,
            icon: entriesProvider.sortOrder == SortOrder.ascending
                ? Transform.flip(
                    flipY: true,
                    child: Icon(Icons.sort_rounded,
                        color: Theme.of(context).colorScheme.primary),
                  )
                : const Icon(Icons.sort_rounded),
            onPressed: () => _showSortSelectionPopup(context),
          ),
        ],
        hintText: AppLocalizations.of(context)!.searchLogsHint,
        padding:
            WidgetStateProperty.all(const EdgeInsets.only(left: 4, right: 4)),
        backgroundColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.secondaryContainer),
        onChanged: (queryText) => EasyDebounce.debounce(
            'search-debounce', const Duration(milliseconds: 300), () {
          if (mounted) _setSearchText(queryText);
        }),
      ),
    );
  }

  /// The Date pill: "Oct 2026", "Sep – Nov 2026", "2025", "2024 – 2025",
  /// "Mar 3 – Apr 12, 2026"...
  String _dateFilterLabel(BuildContext context) {
    final from = _dateFrom!;
    final to = _dateTo ?? from;
    final locale = TimeManager.currentLocale(context);
    final wholeFromMonth = from.day == 1;
    final wholeToMonth = to.day == DateUtils.getDaysInMonth(to.year, to.month);
    if (wholeFromMonth && wholeToMonth && from.month == 1 && to.month == 12) {
      return from.year == to.year
          ? '${from.year}'
          : '${from.year} – ${to.year}';
    }
    if (wholeFromMonth && wholeToMonth) {
      final fromMonth = DateTime(from.year, from.month);
      final toMonth = DateTime(to.year, to.month);
      if (fromMonth == toMonth) return DateFormat.yMMM(locale).format(from);
      if (from.year == to.year) {
        return '${DateFormat.MMM(locale).format(from)} – '
            '${DateFormat.yMMM(locale).format(to)}';
      }
      return '${DateFormat.yMMM(locale).format(from)} – '
          '${DateFormat.yMMM(locale).format(to)}';
    }
    if (DateUtils.isSameDay(from, to)) {
      return DateFormat.yMMMd(locale).format(from);
    }
    if (from.year == to.year) {
      return '${DateFormat.MMMd(locale).format(from)} – '
          '${DateFormat.yMMMd(locale).format(to)}';
    }
    return '${DateFormat.yMMMd(locale).format(from)} – '
        '${DateFormat.yMMMd(locale).format(to)}';
  }

  Future<void> _openPicker(String title,
      Widget Function(BuildContext context, VoidCallback refresh) body) {
    _dropSearchFocus();
    return showGalleryFilterPicker(context,
        title: title,
        body: body,
        count: _visibleCount,
        onClearAll: _clearFilters);
  }

  Future<void> _pickPlace() async {
    _dropSearchFocus();
    final picked = await PlaceFilter.pick(
        context, EntriesProvider.instance.entries,
        current: _place);
    if (picked == null || !mounted) return;
    setState(() => _place = picked == PlaceFilter.cleared ? null : picked);
  }

  /// One pill's label while on: what's picked, or "Name · 3".
  String _pickedLabel(AppLocalizations l10n, String name, List<String> picked) {
    if (picked.length == 1) return picked.first;
    return l10n.galleryFilterCount(name, picked.length);
  }

  /// The pill row (3.7.0.64), in its set order; the row moves the ones
  /// that are on to the front.
  List<GalleryPillSpec> _filterPills(
      BuildContext context, TagsProvider tagsProvider) {
    final l10n = AppLocalizations.of(context)!;
    final favouriteId = Favourites.tag?.id;
    final favouriteOn =
        favouriteId != null && _quickTagIds.contains(favouriteId);
    final tagNames = {for (final tag in tagsProvider.tags) tag.id: tag.name};

    final moodNames = [
      for (final mood in [...Moods.values, null])
        if (_moods.contains(mood))
          mood == null ? l10n.galleryFilterNoMood : Moods.nameOf(mood),
    ];
    final mediaNames = [
      for (final filter in MediaFilter.values)
        if (_media.contains(filter)) filter.label(l10n),
    ];
    final trackerNames = [
      for (final id in _trackerIds)
        if (tagNames[id] != null) tagNames[id]!,
    ];
    final customPins = _quickTagIds.where((id) => id != favouriteId).toList();
    final tagCount =
        _filterTagIds.length + customPins.length + (_filterNoTags ? 1 : 0);
    final keywordNames = _keywords.noText
        ? [l10n.keywordsNoText]
        : [for (final word in _keywords.words) '“$word”'];

    return [
      GalleryPillSpec(
        id: 'favourite',
        name: l10n.quickFilterFavourite,
        label: l10n.quickFilterFavourite,
        icon: favouriteOn ? Icons.star_rounded : Icons.star_outline_rounded,
        activeIconColor: const Color(0xFFF4C542),
        active: favouriteOn,
        onTap: favouriteId == null
            ? () {}
            : () => setState(() {
                  _quickTagIds = {..._quickTagIds};
                  if (!_quickTagIds.remove(favouriteId)) {
                    _quickTagIds.add(favouriteId);
                  }
                }),
      ),
      GalleryPillSpec(
        id: 'last-edited',
        name: l10n.quickFilterLastEdited,
        label: l10n.quickFilterLastEdited,
        icon: Icons.history_rounded,
        active: _lastEdited,
        onTap: () => setState(() => _lastEdited = !_lastEdited),
      ),
      GalleryPillSpec(
        id: 'date',
        name: l10n.galleryFilterDate,
        label:
            _hasDateFilter ? _dateFilterLabel(context) : l10n.galleryFilterDate,
        icon: Icons.calendar_month_rounded,
        active: _hasDateFilter,
        opensPicker: true,
        onTap: () => _pickMonthFilter(_dateFrom ?? DateTime.now()),
      ),
      GalleryPillSpec(
        id: 'mood',
        name: l10n.galleryFilterMood,
        label: moodNames.isEmpty
            ? l10n.galleryFilterMood
            : _pickedLabel(l10n, l10n.galleryFilterMood, moodNames),
        icon: Icons.sentiment_satisfied_alt_rounded,
        active: moodNames.isNotEmpty,
        count: moodNames.length,
        opensPicker: true,
        onTap: () => _openPicker(
            l10n.galleryFilterMood,
            (context, refresh) => moodFilterBody(context,
                moods: _moods,
                onChanged: (moods) => setState(() => _moods = moods),
                refresh: refresh)),
      ),
      GalleryPillSpec(
        id: 'media',
        name: l10n.galleryFilterMedia,
        label: mediaNames.isEmpty
            ? l10n.galleryFilterMedia
            : _pickedLabel(l10n, l10n.galleryFilterMedia, mediaNames),
        icon: Icons.perm_media_rounded,
        active: mediaNames.isNotEmpty,
        count: mediaNames.length,
        opensPicker: true,
        onTap: () => _openPicker(
            l10n.galleryFilterMedia,
            (context, refresh) => mediaFilterBody(context,
                media: _media,
                onChanged: (media) => setState(() => _media = media),
                refresh: refresh)),
      ),
      GalleryPillSpec(
        id: 'places',
        name: l10n.quickFilterPlaces,
        label: _place == null
            ? l10n.quickFilterPlaces
            : PlaceFilter.label(context, _place!),
        icon: Icons.place_rounded,
        active: _place != null,
        opensPicker: true,
        onTap: _pickPlace,
      ),
      GalleryPillSpec(
        id: 'trackers',
        name: l10n.tagFilterTrackers,
        label: trackerNames.isEmpty
            ? l10n.tagFilterTrackers
            : _pickedLabel(l10n, l10n.tagFilterTrackers, trackerNames),
        icon: Icons.numbers_rounded,
        active: trackerNames.isNotEmpty,
        count: trackerNames.length,
        opensPicker: true,
        onTap: () => _openPicker(
            l10n.tagFilterTrackers,
            (context, refresh) => trackerFilterBody(context,
                tagIds: _trackerIds,
                onChanged: (ids) => setState(() => _trackerIds = ids),
                refresh: refresh)),
      ),
      GalleryPillSpec(
        id: 'tags',
        name: l10n.galleryFilterTags,
        label: tagCount == 0
            ? l10n.galleryFilterTags
            : l10n.galleryFilterCount(l10n.galleryFilterTags, tagCount),
        icon: Icons.local_offer_rounded,
        active: tagCount > 0,
        count: tagCount,
        opensPicker: true,
        onTap: () => _showTagFilterDialog(context),
      ),
      GalleryPillSpec(
        id: 'keywords',
        name: l10n.galleryFilterKeywords,
        label: keywordNames.isEmpty
            ? l10n.galleryFilterKeywords
            : _pickedLabel(l10n, l10n.galleryFilterKeywords, keywordNames),
        icon: Icons.text_fields_rounded,
        active: _keywords.isOn,
        count: _keywords.count,
        opensPicker: true,
        onTap: () => _openPicker(
            l10n.galleryFilterKeywords,
            (context, refresh) => KeywordFilterBody(
                filter: _keywords,
                onChanged: (filter) => setState(() => _keywords = filter),
                refresh: refresh)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final tagsProvider = Provider.of<TagsProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    String viewMode = configProvider.get(Settings.galleryPageViewMode);
    bool listView = viewMode == 'list';
    final visible = _getVisibleEntries(entriesProvider, tagsProvider);
    // Entries dated after today sit in their own Upcoming row at the top.
    final upcoming = FutureEntries.upcoming(visible);
    final entries = upcoming.isEmpty ? visible : FutureEntries.past(visible);
    final bool showClear = _searchController.text.isNotEmpty || _hasTagFilter;
    // Entries deleted or filtered away drop out of the selection
    _selected.removeWhere((id) => !entries.any((entry) => entry.id == id));
    final pills = _selecting ? null : _filterPills(context, tagsProvider);

    final height = _barHeight + (pills != null ? _chipRowHeight : 0);
    _headerHeight = height;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selecting)
          _selectionBar(entries)
        else
          _searchBar(context, entriesProvider, entries.length, showClear),
        if (pills != null)
          GalleryFilterRow(
            pills: pills,
            compact: _iconsOnly,
            onToggleCompact: () {
              setState(() => _iconsOnly = !_iconsOnly);
              GalleryFilterRow.saveCompact(_iconsOnly);
            },
          ),
      ],
    );

    // On the Gallery tab the app's own Back handler asks [handleBack]; a
    // Gallery opened from Statistics handles Back itself
    return PopScope(
      canPop: widget.preset == null || !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.preset != null) setState(_selected.clear);
      },
      child: Stack(
        children: [
          _buildList(
              context, listView, entries, upcoming, entriesProvider, height),
          AnimatedBuilder(
            animation: Listenable.merge([_scrollController, _headerHidden]),
            builder: (context, _) => Stack(children: [
              _stuckPill(context, listView, background),
            ]),
          ),
          // The search bar and chips: they slide away while you scroll
          // down and come back on a small pull (3.7.0.59)
          ValueListenableBuilder<double>(
            valueListenable: _headerHidden,
            builder: (context, hidden, child) => Positioned(
              top: -hidden,
              left: 0,
              right: 0,
              height: height,
              child: child!,
            ),
            child: ColoredBox(
              color: background,
              child: Align(alignment: Alignment.topCenter, child: header),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: ActionPillSlot(
                visible: _selecting,
                pill: (context) => SelectionActionPill(
                  selected: entries
                      .where((entry) => _selected.contains(entry.id))
                      .toList(),
                  onDone: _onSelectionDone(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<EntryAttachment> _visualAttachmentsOf(
      EntryAttachmentsProvider provider, Entry entry) {
    return provider
        .getForEntry(entry)
        .where((attachment) => attachment.type.isVisual)
        .toList();
  }

  /// [entries] split where the day (Timeline view) or month (Grid view)
  /// changes, keeping their order.
  static List<_GallerySection> _sections(List<Entry> entries,
      {required bool byDay}) {
    final sections = <_GallerySection>[];
    for (var index = 0; index < entries.length; index++) {
      final time = entries[index].timeCreate;
      final key = byDay
          ? DateTime(time.year, time.month, time.day)
          : DateTime(time.year, time.month);
      if (sections.isEmpty || sections.last.date != key) {
        sections.add(_GallerySection(key, index));
      }
      sections.last.entries.add(entries[index]);
    }
    return sections;
  }

  // ---- The list ----------------------------------------------------------
  //
  // One flat list where every row's height is known up front (3.7.0.59
  // fix): only what's on screen is built, so opening the Gallery, clearing
  // filters and switching views stay quick however many entries there are.
  // The search bar and chips sit on top and slide away on scroll; the
  // stuck day or month pill is drawn on top too, worked out from the
  // known heights.

  static const double _pillHeight = 56;
  static const double _monthLabelHeight = 36;

  /// How far the header has slid up, from 0 (showing) to its height.
  final ValueNotifier<double> _headerHidden = ValueNotifier(0);
  double _headerHeight = _barHeight;
  double _lastPixels = 0;
  bool _lastScrollUp = false;
  late final AnimationController _snap = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));
  Animation<double>? _snapTween;

  // What the list last laid out, for the stuck pill.
  List<_Item> _items = const [];
  List<double> _offsets = const [];
  List<int> _pillIndexes = const [];
  double _contentWidth = 0;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;
    final delta = pixels - _lastPixels;
    _lastPixels = pixels;
    if (delta != 0) _lastScrollUp = delta < 0;
    if (_snap.isAnimating) _snap.stop();
    var hidden = (_headerHidden.value + delta).clamp(0.0, _headerHeight);
    // Near the top the header stays with the list
    if (pixels <= 0) hidden = 0;
    if (hidden > pixels) hidden = pixels.clamp(0.0, _headerHeight);
    _headerHidden.value = hidden;
  }

  /// After a scroll stops halfway through the header: finish showing it
  /// after a pull down, or hiding it after a push up.
  bool _onScrollEnd(ScrollEndNotification notification) {
    final hidden = _headerHidden.value;
    if (hidden <= 0 || hidden >= _headerHeight) return false;
    final target =
        _lastScrollUp || _lastPixels < _headerHeight ? 0.0 : _headerHeight;
    _snapTween = Tween(begin: hidden, end: target)
        .animate(CurvedAnimation(parent: _snap, curve: Curves.easeOut));
    _snap
      ..reset()
      ..forward();
    return false;
  }

  void _onSnap() {
    final tween = _snapTween;
    if (tween != null) _headerHidden.value = tween.value;
  }

  /// The rows of the list, with their heights.
  List<_Item> _layoutItems(
      {required bool listView,
      required bool byDate,
      required List<Entry> entries,
      required List<Entry> upcoming,
      required double width,
      required double headerHeight}) {
    final items = <_Item>[_Item.space(headerHeight)];
    if (upcoming.isNotEmpty) {
      items.add(_Item(_ItemKind.upcoming, _upcomingRowHeight));
    }
    if (entries.isEmpty) return items;

    if (listView) {
      final rowWidth = width < 720 ? width : 720.0;
      final rowExtent = rowWidth / 2.2;
      if (!byDate) {
        for (var i = 0; i < entries.length; i++) {
          items.add(_Item(_ItemKind.row, rowExtent,
              entry: entries[i],
              index: i,
              first: i == 0,
              last: i == entries.length - 1));
        }
      } else {
        DateTime? month;
        for (final section in _sections(entries, byDay: true)) {
          final sectionMonth = DateTime(section.date.year, section.date.month);
          if (sectionMonth != month) {
            month = sectionMonth;
            items.add(_Item(_ItemKind.monthLabel, _monthLabelHeight,
                date: sectionMonth));
          }
          items.add(_Item(_ItemKind.pill, _pillHeight,
              date: section.date, count: section.entries.length));
          for (var i = 0; i < section.entries.length; i++) {
            items.add(_Item(_ItemKind.row, rowExtent,
                entry: section.entries[i],
                index: section.start + i,
                first: i == 0,
                last: i == section.entries.length - 1,
                timeOnly: true));
          }
        }
      }
    } else {
      final columns =
          (width / (300 + _gridSpacing)).ceil().clamp(1, 1 << 20).toInt();
      final tile = (width - _gridSpacing * (columns - 1)) / columns;
      void addRows(List<Entry> group, int start, {required bool gap}) {
        for (var i = 0; i < group.length; i += columns) {
          final end = i + columns < group.length ? i + columns : group.length;
          final lastRow = end == group.length;
          items.add(_Item(
              _ItemKind.gridRow, tile + _gridSpacing + (gap && lastRow ? 8 : 0),
              tiles: group.sublist(i, end),
              index: start + i,
              tileSize: tile,
              columns: columns));
        }
      }

      if (!byDate) {
        addRows(entries, 0, gap: false);
      } else {
        for (final section in _sections(entries, byDay: false)) {
          items.add(_Item(_ItemKind.pill, _pillHeight,
              date: section.date, count: section.entries.length));
          addRows(section.entries, section.start, gap: true);
        }
      }
    }
    items.add(_Item.space(_selecting ? ActionPill.clearance : 24));
    return items;
  }

  Widget _buildList(
      BuildContext context,
      bool listView,
      List<Entry> entries,
      List<Entry> upcoming,
      EntriesProvider entriesProvider,
      double headerHeight) {
    final entryAttachmentsProvider =
        Provider.of<EntryAttachmentsProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final searchQuery = _searchText;
    final hideImages = configProvider.get(Settings.hideImagesInGallery);
    // Day and month pills only when entries run by date (not by mood,
    // tracker or last edit)
    final byDate = entriesProvider.orderBy == OrderBy.date && !_lastEdited;
    final locale = TimeManager.currentLocale(context);
    final timeFormat = TimeManager.localizedTimeFormat(context, locale);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final items = _layoutItems(
          listView: listView,
          byDate: byDate,
          entries: entries,
          upcoming: upcoming,
          width: width,
          headerHeight: headerHeight);
      final offsets = <double>[];
      final pills = <int>[];
      var offset = 0.0;
      for (var i = 0; i < items.length; i++) {
        offsets.add(offset);
        offset += items[i].extent;
        if (items[i].kind == _ItemKind.pill) pills.add(i);
      }
      _items = items;
      _offsets = offsets;
      _pillIndexes = pills;
      _contentWidth = listView && width > 720 ? 720 : width;

      Widget buildItem(BuildContext context, int i) {
        final item = items[i];
        switch (item.kind) {
          case _ItemKind.space:
            return const SizedBox.shrink();
          case _ItemKind.upcoming:
            return _UpcomingRow(count: upcoming.length, onTap: _openUpcoming);
          case _ItemKind.monthLabel:
            return _narrow(
                _MonthLabel(text: DateFormat.yMMMM(locale).format(item.date!)));
          case _ItemKind.pill:
            return _narrow(_pillFor(item, locale, listView, stuck: false));
          case _ItemKind.row:
            final entry = item.entry!;
            return _narrow(_entryTap(
              entry,
              item.index,
              _GalleryTimelineRow(
                isFirst: item.first,
                isLast: item.last,
                selecting: _selecting,
                selected: _selected.contains(entry.id),
                mood: entry.mood,
                card: LargeEntryCardWidget(
                  title: item.timeOnly
                      ? timeFormat.format(entry.timeCreate)
                      : null,
                  entry: entry,
                  attachments:
                      _visualAttachmentsOf(entryAttachmentsProvider, entry),
                  hideImage: hideImages,
                  searchQuery: searchQuery,
                  showLocations: true,
                  showMood: false,
                ),
              ),
            ));
          case _ItemKind.gridRow:
            final tiles = item.tiles!;
            return Align(
              alignment: Alignment.topLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var t = 0; t < tiles.length; t++) ...[
                    if (t > 0) const SizedBox(width: _gridSpacing),
                    SizedBox(
                      width: item.tileSize,
                      height: item.tileSize,
                      child: _entryTap(
                        tiles[t],
                        item.index + t,
                        SelectionOutline(
                          selected: _selected.contains(tiles[t].id),
                          showTick: true,
                          child: EntryCardWidget(
                            entry: tiles[t],
                            attachments: _visualAttachmentsOf(
                                entryAttachmentsProvider, tiles[t]),
                            hideImage: hideImages,
                            searchQuery: searchQuery,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
        }
      }

      final empty = entries.isEmpty && upcoming.isEmpty;
      return NotificationListener<ScrollEndNotification>(
        onNotification: _onScrollEnd,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverVariedExtentList.builder(
              itemCount: items.length,
              itemExtentBuilder: (index, _) =>
                  index < items.length ? items[index].extent : null,
              itemBuilder: buildItem,
            ),
            if (empty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(context),
              ),
          ],
        ),
      );
    });
  }

  /// Timeline-view rows, pills and labels keep to the middle on wide
  /// screens.
  Widget _narrow(Widget child) => Center(
        child: SizedBox(
            width: _contentWidth, height: double.infinity, child: child),
      );

  Widget _pillFor(_Item item, String locale, bool listView,
      {required bool stuck}) {
    final date = item.date!;
    if (listView) {
      return _DatePill(
        key: ValueKey(
            '${stuck ? 'stuck' : 'gallery'}-day-${date.year}-${date.month}-${date.day}'),
        title: DateFormat('EEEE d', locale).format(date),
        month: DateFormat.yMMM(locale).format(date),
        showMonth: stuck,
        count: item.count,
        onTap: () => _pickMonthFilter(DateTime(date.year, date.month)),
      );
    }
    return _DatePill(
      key: ValueKey(
          '${stuck ? 'stuck' : 'gallery'}-month-${date.year}-${date.month}'),
      title: DateFormat.yMMMM(locale).format(date),
      showArrow: true,
      count: item.count,
      onTap: () => _pickMonthFilter(date),
    );
  }

  /// The pill stuck under the header: the last day (or month) whose own
  /// pill has scrolled up under it, pushed up by the next one.
  Widget _stuckPill(BuildContext context, bool listView, Color background) {
    if (!_scrollController.hasClients || _pillIndexes.isEmpty) {
      return const SizedBox.shrink();
    }
    final pixels = _scrollController.position.pixels;
    final shown = _headerHeight - _headerHidden.value;
    double screen(int item) => _offsets[item] - pixels;
    // The last pill at or above the header's bottom
    var low = 0;
    var high = _pillIndexes.length - 1;
    var found = -1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (screen(_pillIndexes[mid]) <= shown) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    if (found < 0 || screen(_pillIndexes[found]) > shown - 0.5) {
      return const SizedBox.shrink();
    }
    var top = shown;
    if (found + 1 < _pillIndexes.length) {
      final next = screen(_pillIndexes[found + 1]);
      if (next < shown + _pillHeight) top = next - _pillHeight;
    }
    final item = _items[_pillIndexes[found]];
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: _pillHeight,
      child: ColoredBox(
        color: background,
        child: _narrow(_pillFor(
            item, TimeManager.currentLocale(context), listView,
            stuck: true)),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_hasTagFilter) {
      // Filters left nothing: No Logs Match, with Clear all (3.7.0.64)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off_outlined,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(l10n.galleryNoLogsMatch, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.galleryNoLogsMatchHint,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              key: const ValueKey('gallery-clear-all'),
              onPressed: _clearFilters,
              child: Text(l10n.clearAllFilters),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Text(
        _searchController.text.isNotEmpty ? l10n.noResults : l10n.noLogs,
      ),
    );
  }

  Widget _entryTap(Entry entry, int index, Widget child) {
    return GestureDetector(
      onLongPress: () => _toggleSelected(entry),
      onTap: () async {
        if (_selecting) {
          _toggleSelected(entry);
          return;
        }
        await _openEntryAt(index);
      },
      child: child,
    );
  }
}

/// "Tuesday 28" (Timeline view) or "October 2026" (Grid view), with the
/// entry count on the right. A stuck day pill adds "· Oct 2026 ▾". Tapping
/// opens the month filter.
class _DatePill extends StatelessWidget {
  const _DatePill({
    super.key,
    required this.title,
    required this.count,
    required this.onTap,
    this.month,
    this.showMonth = false,
    this.showArrow = false,
  });

  final String title;
  final String? month;
  final bool showMonth;
  final bool showArrow;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurfaceVariant;
    final month = this.month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (month != null)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: showMonth
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(' · $month',
                                        style: TextStyle(
                                            fontSize: 15, color: muted)),
                                    Icon(Icons.arrow_drop_down_rounded,
                                        size: 20, color: muted),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      if (showArrow)
                        Icon(Icons.arrow_drop_down_rounded,
                            size: 22, color: muted),
                    ],
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.galleryMonthEntries(count),
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "OCTOBER 2026" where a month starts in Timeline view.
class _MonthLabel extends StatelessWidget {
  const _MonthLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A Gallery Timeline-view row: the mood circle on the line, then the
/// card. Each day's line fades out into its pills (3.7.0.59).
class _GalleryTimelineRow extends StatelessWidget {
  const _GalleryTimelineRow({
    required this.isFirst,
    required this.isLast,
    required this.selecting,
    required this.selected,
    required this.mood,
    required this.card,
  });

  static const double _lineWidth = 3;

  final bool isFirst;
  final bool isLast;
  final bool selecting;
  final bool selected;
  final int? mood;
  final Widget card;

  @override
  Widget build(BuildContext context) {
    final railColor = Theme.of(context).colorScheme.outlineVariant;
    final faded = railColor.withValues(alpha: 0);
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: TimelineRailDot.railWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      Container(
                        width: _lineWidth,
                        height: TimelineRailDot.center,
                        decoration: BoxDecoration(
                          gradient: isFirst
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [faded, railColor])
                              : null,
                          color: isFirst ? null : railColor,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: _lineWidth,
                          decoration: BoxDecoration(
                            gradient: isLast
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [railColor, faded])
                                : null,
                            color: isLast ? null : railColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: TimelineRailDot.center - TimelineRailDot.slot / 2,
                  left: 0,
                  right: 0,
                  height: TimelineRailDot.slot,
                  child: Center(
                    child: TimelineRailDot(
                        selecting: selecting, selected: selected, mood: mood),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: SelectionOutline(selected: selected, child: card),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Upcoming · 3 entries" at the top of the Gallery, opening a timeline of
/// entries dated after today.
class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Material(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.event_rounded,
                    color: colorScheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.galleryUpcoming(count),
                    style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onTertiaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
