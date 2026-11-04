// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/formatted_copy.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/layouts/fast_page_view_scroll_physics.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entry_view_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class EntriesListPage extends StatefulWidget {
  final int index;
  final List<Entry> Function() getEntries;

  /// Gallery search text to highlight in each entry.
  final String? searchQuery;

  /// Whether the list runs newest first. Swiping right-to-left always goes
  /// forward in time, so a newest-first list is laid out back to front and
  /// an oldest-first one front to back.
  final bool newestFirst;

  const EntriesListPage({
    super.key,
    required this.index,
    required this.getEntries,
    this.searchQuery,
    this.newestFirst = true,
  });

  @override
  State<EntriesListPage> createState() => _EntriesListPageState();
}

class _EntriesListPageState extends State<EntriesListPage> {
  late PageController _pageController;

  /// What's selected right now, for copying with formatting kept.
  String? _selectedText;

  /// The entries to swipe through, fixed when the page opens (3.7.0.42).
  /// Editing an entry so it leaves a Gallery filter, unstarring it or
  /// changing its date used to shrink or reorder the list underneath,
  /// landing on another entry or a black screen. The list now stays as it
  /// was until you go back, and the Gallery refreshes then.
  late final List<int> _ids;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _ids = widget.getEntries().map((entry) => entry.id).nonNulls.toList();
    _pageController = PageController(initialPage: widget.index);
  }

  /// The fixed list as it is now: up-to-date entries, without any that
  /// were deleted.
  List<Entry> _currentEntries() {
    final byId = {
      for (final entry in EntriesProvider.instance.entries) entry.id: entry
    };
    return [
      for (final id in _ids)
        if (byId[id] case final entry?) entry
    ];
  }

  /// Nothing left to show: go back instead of showing a blank screen.
  void _leaveWhenEmpty() {
    if (_leaving) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      final navigator = Navigator.of(context);
      if (route == null) return;
      if (route.isCurrent) {
        navigator.maybePop();
      } else if (route.isActive) {
        navigator.removeRoute(route);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// The text of the entry on screen, without its hidden places line.
  String? _shownBody(List<Entry> entries) {
    if (entries.isEmpty) return null;
    final page = _pageController.hasClients
        ? (_pageController.page ?? widget.index.toDouble()).round()
        : widget.index;
    if (page < 0 || page >= entries.length) return null;
    return EntryLocations.split(entries[page].text).$1;
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<EntriesProvider>(context);
    final entries = _currentEntries();
    if (entries.isEmpty) {
      _leaveWhenEmpty();
      return const Scaffold();
    }

    // SelectionArea for entry text sits above the page so it loses to swipe gestures.
    return SelectionArea(
      onSelectionChanged: (content) => _selectedText = content?.plainText,
      contextMenuBuilder: (context, region) => FormattedCopy.contextMenu(
        context,
        region,
        selectedText: () => _selectedText,
        body: () => _shownBody(entries),
      ),
      child: PageView.builder(
          hitTestBehavior: HitTestBehavior.translucent,
          controller: _pageController,
          physics: FastPageViewScrollPhysics(),
          reverse: widget.newestFirst,
          itemCount: entries.length,
          onPageChanged: null,
          itemBuilder: (context, index) {
            return EntryViewPage(
              entryId: entries[index].id!,
              searchQuery: widget.searchQuery,
              // The list is fixed, so the edited entry stays where it is
              onEntryEdited: (_) {},
            );
          }),
    );
  }
}
