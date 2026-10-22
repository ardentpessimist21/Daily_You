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

  const EntriesListPage({
    super.key,
    required this.index,
    required this.getEntries,
    this.searchQuery,
  });

  @override
  State<EntriesListPage> createState() => _EntriesListPageState();
}

class _EntriesListPageState extends State<EntriesListPage> {
  late PageController _pageController;

  /// What's selected right now, for copying with formatting kept.
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.index);
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
    final entries = widget.getEntries();

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
          reverse: true,
          itemCount: entries.length,
          onPageChanged: null,
          itemBuilder: (context, index) {
            return EntryViewPage(
              entryId: entries[index].id!,
              searchQuery: widget.searchQuery,
              onEntryEdited: (editedEntryId) {
                final updatedEntries = widget.getEntries();
                final newIndex =
                    updatedEntries.indexWhere((e) => e.id == editedEntryId);
                if (newIndex != -1 && mounted) {
                  _pageController.jumpToPage(newIndex);
                }
              },
            );
          }),
    );
  }
}
