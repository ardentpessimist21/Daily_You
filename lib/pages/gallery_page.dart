// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/fork/selection_actions.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/future_entries.dart';
import 'package:daily_you/fork/gallery_month_pill.dart';
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
import 'package:daily_you/widgets/hiding_widget.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:provider/provider.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode = FocusNode();
  double _searchElevation = 0.0;

  List<int> _filterTagIds = [];
  TagFilterMode _filterTagMode = TagFilterMode.any;
  bool _filterNoTags = false;

  bool get _hasTagFilter => _filterTagIds.isNotEmpty || _filterNoTags;

  // Entry ids picked in select mode (started by long-pressing a tile)
  final Set<int> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelected(Entry entry) {
    final id = entry.id;
    if (id == null) return;
    setState(() =>
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  }

  Widget _selectionBar(List<Entry> entries) {
    final messenger = ScaffoldMessenger.of(context);
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
            onClear: () => setState(_selected.clear),
            onSelectAll: () => setState(() =>
                _selected.addAll(entries.map((entry) => entry.id).nonNulls)),
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
          ),
        ),
      ),
    );
  }

  // Month pill: the month at the top while scrolling, fading 3s after.
  final _pill = ValueNotifier<(DateTime?, bool)>((null, false));
  Timer? _pillTimer;
  // What the grid last showed, for working out which entry is at the top.
  List<Entry> _gridEntries = const [];
  int _gridColumns = 1;
  double _gridRowExtent = 1;
  double _gridTop = _listTopPadding;
  bool _pillAllowed = false;

  // Space under the floating search bar, above and below the list.
  static const double _listTopPadding = 70;
  static const double _upcomingRowHeight = 60;
  static const double _gridSpacing = 1.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.text = EntriesProvider.instance.searchText;
    _scrollController.addListener(() {
      _onScrollForPill();
      final elevation = _scrollController.position.pixels > 0 ? 1.0 : 0.0;

      if (_searchElevation != elevation) {
        setState(() {
          _searchElevation = elevation;
        });
      }
    });
  }

  // The entry under the search bar, given the grid's row size.
  Entry? _entryAtTop() {
    if (_gridEntries.isEmpty || !_scrollController.hasClients) return null;
    final y =
        _scrollController.position.pixels + _listTopPadding - _gridTop + 1;
    final row = (y / _gridRowExtent).floor().clamp(0, 1 << 30);
    final index = (row * _gridColumns).clamp(0, _gridEntries.length - 1);
    return _gridEntries[index];
  }

  void _onScrollForPill() {
    if (!_pillAllowed) {
      if (_pill.value.$2) _pill.value = (_pill.value.$1, false);
      return;
    }
    final entry = _entryAtTop();
    if (entry == null) return;
    _showPill(DateTime(entry.timeCreate.year, entry.timeCreate.month));
  }

  void _showPill(DateTime month) {
    if (_pill.value != (month, true)) _pill.value = (month, true);
    _pillTimer?.cancel();
    _pillTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _pill.value = (_pill.value.$1, false);
    });
  }

  Future<void> _pickMonthAndJump() async {
    final current = _pill.value.$1;
    if (current == null) return;
    _pillTimer?.cancel();
    final entries = _gridEntries;
    final month = await GalleryMonthPill.pickMonth(context, entries, current);
    if (month == null || !mounted || !_scrollController.hasClients) {
      if (mounted) _showPill(current);
      return;
    }
    final index = entries.indexWhere((entry) =>
        entry.timeCreate.year == month.year &&
        entry.timeCreate.month == month.month);
    if (index < 0) return;
    final row = index ~/ _gridColumns;
    final target = _gridTop + row * _gridRowExtent - _listTopPadding;
    final position = _scrollController.position;
    _scrollController.jumpTo(target.clamp(0.0, position.maxScrollExtent));
    _showPill(month);
  }

  Future<void> _openUpcoming() async {
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
    _pillTimer?.cancel();
    _pill.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Entry> _getVisibleEntries(
      EntriesProvider entriesProvider, TagsProvider tagsProvider) {
    final filtered =
        _applyTagFilter(entriesProvider.getFilteredEntries(), tagsProvider);
    return _applyTrackerSort(filtered, entriesProvider, tagsProvider);
  }

  List<Entry> _applyTagFilter(List<Entry> entries, TagsProvider tagsProvider) {
    if (_filterNoTags) {
      return entries
          .where((entry) =>
              tagsProvider.getEntryTagsForEntry(entry.id ?? -1).isEmpty)
          .toList();
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
    showAppDialog(
      context: context,
      builder: (_) => TagPickerDialog(
        mode: TagPickerMode.filter,
        initialSelectedTagIds: List.from(_filterTagIds),
        initialFilterMode: _filterTagMode,
        initialNoTagsOnly: _filterNoTags,
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
                        value: OrderBy.edited,
                        title: Text(AppLocalizations.of(context)!
                            .sortRecentlyEditedTitle),
                        subtitle: Text(AppLocalizations.of(context)!
                            .sortRecentlyEditedHint),
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
    _pillAllowed = entriesProvider.orderBy == OrderBy.date;
    final bool showClear = _searchController.text.isNotEmpty || _hasTagFilter;
    // Entries deleted or filtered away drop out of the selection
    _selected.removeWhere((id) => !entries.any((entry) => entry.id == id));
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Center(
        child: Stack(alignment: Alignment.topCenter, children: [
          buildEntries(context, listView, entries, tagsProvider, upcoming),
          Positioned(
            top: _listTopPadding,
            child: ValueListenableBuilder<(DateTime?, bool)>(
              valueListenable: _pill,
              builder: (context, pill, _) => GalleryMonthPill(
                month: pill.$1,
                visible: pill.$2 && _pillAllowed && entries.isNotEmpty,
                onTap: _pickMonthAndJump,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_selecting)
                _selectionBar(entries)
              else
                Padding(
                  padding: const EdgeInsets.only(
                      top: 4, bottom: 8, left: 8, right: 8),
                  child: SearchBar(
                    focusNode: _focusNode,
                    controller: _searchController,
                    elevation: WidgetStatePropertyAll(_searchElevation),
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
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          final rotationAnimation =
                              Tween<double>(begin: 0.0, end: 0.5).animate(
                            CurvedAnimation(
                                parent: animation, curve: Curves.easeOut),
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
                        child: showClear
                            ? IconButton(
                                visualDensity: VisualDensity(
                                    horizontal: VisualDensity.minimumDensity),
                                key: ValueKey('clearButton'),
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  entriesProvider.searchText = "";
                                  setState(() {
                                    _filterTagIds = [];
                                    _filterTagMode = TagFilterMode.any;
                                    _filterNoTags = false;
                                  });
                                },
                              )
                            : SizedBox.shrink(key: ValueKey('empty')),
                      ),
                      if (entriesProvider.searchText.isNotEmpty ||
                          _hasTagFilter)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(AppLocalizations.of(context)!
                              .logCount(entries.length)),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.filter_alt_rounded,
                          color: _hasTagFilter
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        onPressed: () => _showTagFilterDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sort_rounded),
                        onPressed: () => _showSortSelectionPopup(context),
                      ),
                    ],
                    hintText: AppLocalizations.of(context)!.searchLogsHint,
                    padding: WidgetStateProperty.all(
                        const EdgeInsets.only(left: 4, right: 4)),
                    backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.secondaryContainer),
                    onChanged: (queryText) => EasyDebounce.debounce(
                        'search-debounce', const Duration(milliseconds: 300),
                        () {
                      entriesProvider.searchText = queryText;
                    }),
                  ),
                ),
              if (entries.isNotEmpty)
                HidingWidget(
                  scrollController: _scrollController,
                  duration: Duration(milliseconds: 200),
                  hideDirection: HideDirection.down,
                  shouldShow: () {
                    return _scrollController.hasClients &&
                        _scrollController.position.pixels >= 500;
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FloatingActionButton(
                          heroTag: "gallery-jump-to-top-button",
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          elevation: 1,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          onPressed: () async {
                            _scrollController.position.animateTo(0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ]),
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

  Widget buildEntries(BuildContext context, bool listView, List<Entry> entries,
      TagsProvider tagsProvider, List<Entry> upcoming) {
    final entryAttachmentsProvider =
        Provider.of<EntryAttachmentsProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final searchQuery = EntriesProvider.instance.searchText;
    if (entries.isEmpty && upcoming.isEmpty) {
      _gridEntries = const [];
      return Center(
        child: Text(
          _searchController.text.isNotEmpty || _hasTagFilter
              ? AppLocalizations.of(context)!.noResults
              : AppLocalizations.of(context)!.noLogs,
        ),
      );
    }

    final maxExtent = listView ? 500.0 : 300.0;
    final aspectRatio = listView ? 2.0 : 1.0;
    return LayoutBuilder(builder: (context, constraints) {
      // Same sizing as SliverGridDelegateWithMaxCrossAxisExtent, kept here
      // so the month pill knows which entry sits at the top.
      final width = constraints.maxWidth;
      final columns =
          (width / (maxExtent + _gridSpacing)).ceil().clamp(1, 1 << 20);
      final tileWidth = (width - _gridSpacing * (columns - 1)) / columns;
      _gridEntries = entries;
      _gridColumns = columns;
      _gridRowExtent = tileWidth / aspectRatio + _gridSpacing;
      _gridTop =
          _listTopPadding + (upcoming.isNotEmpty ? _upcomingRowHeight : 0);

      return CustomScrollView(
        controller: _scrollController,
        physics: const ScrollPhysics(),
        shrinkWrap: true,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: _listTopPadding)),
          if (upcoming.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: _upcomingRowHeight,
                child:
                    _UpcomingRow(count: upcoming.length, onTap: _openUpcoming),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 70),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxExtent,
                  crossAxisSpacing: _gridSpacing,
                  mainAxisSpacing: _gridSpacing,
                  childAspectRatio: aspectRatio),
              delegate: SliverChildBuilderDelegate(
                childCount: entries.length,
                (context, index) {
                  final entry = entries[index];
                  final isSelected = _selected.contains(entry.id);
                  return GestureDetector(
                    onLongPress: () => _toggleSelected(entry),
                    onTap: () async {
                      if (_selecting) {
                        _toggleSelected(entry);
                        return;
                      }
                      await Navigator.of(context).push(MaterialPageRoute(
                          allowSnapshotting: false,
                          builder: (context) => EntriesListPage(
                                index: index,
                                searchQuery:
                                    EntriesProvider.instance.searchText,
                                newestFirst:
                                    EntriesProvider.instance.sortOrder !=
                                        SortOrder.ascending,
                                getEntries: () =>
                                    FutureEntries.past(_getVisibleEntries(
                                  EntriesProvider.instance,
                                  TagsProvider.instance,
                                )),
                              )));
                    },
                    child: SelectionOutline(
                      selected: isSelected,
                      showTick: true,
                      child: listView
                          ? LargeEntryCardWidget(
                              entry: entry,
                              attachments: _visualAttachmentsOf(
                                  entryAttachmentsProvider, entry),
                              hideImage: configProvider
                                  .get(Settings.hideImagesInGallery),
                              searchQuery: searchQuery,
                            )
                          : EntryCardWidget(
                              entry: entry,
                              attachments: _visualAttachmentsOf(
                                  entryAttachmentsProvider, entry),
                              hideImage: configProvider
                                  .get(Settings.hideImagesInGallery),
                              searchQuery: searchQuery,
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
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
