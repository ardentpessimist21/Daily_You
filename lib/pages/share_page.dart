// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/share_return.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/day_menu.dart';
import 'package:daily_you/widgets/entry_attachment_actions.dart';
import 'package:daily_you/widgets/attachment_tile_background.dart';
import 'package:daily_you/widgets/attachment_grid.dart';
import 'package:daily_you/widgets/video_thumbnail_cache.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:daily_you/widgets/vertical_calendar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_receiver/share_receiver.dart';

class SharePage extends StatefulWidget {
  final SharePayload payload;

  const SharePage({super.key, required this.payload});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final ScrollController _scrollController = ScrollController();
  bool _opening = false;

  /// Search (Update 68): words and an optional day, as in Link to entry.
  final TextEditingController _search = TextEditingController();
  DateTime? _searchDay;

  bool get _searching => _search.text.trim().isNotEmpty || _searchDay != null;

  @override
  void dispose() {
    widget.payload.deleteMedia();
    _scrollController.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _selectDay(BuildContext dayContext, DateTime day) async {
    if (_opening) return;
    final entries = EntriesProvider.instance.getEntriesForDate(day);
    Entry? entry;
    if (entries.isNotEmpty) {
      final choice = await _showDayChoiceMenu(dayContext, day, entries);
      if (choice == null) return;
      entry = choice.entry;
    }
    if (!mounted) return;
    await _openEditor(day, entry);
  }

  Future<({Entry? entry})?> _showDayChoiceMenu(
      BuildContext dayContext, DateTime day, List<Entry> entries) {
    final locale = TimeManager.currentLocale(dayContext);
    final timeFormat = TimeManager.localizedTimeFormat(dayContext, locale);
    return showDayMenu<({Entry? entry})>(
      dayContext,
      items: [
        for (final entry in entries)
          PopupMenuItem(
            value: (entry: entry),
            child: _entryChoice(dayContext, entry, timeFormat, day),
          ),
        PopupMenuItem(
          value: (entry: null),
          child: Row(
            children: [
              const Icon(Icons.add_rounded),
              const SizedBox(width: 12),
              Text(TimeManager.formatDate(day, dayContext)),
            ],
          ),
        ),
      ],
    );
  }

  /// [title] cut to [maxChars] letters (spaces don't count), with "…".
  static String _clip(String title, int maxChars) {
    var count = 0;
    for (var i = 0; i < title.length; i++) {
      if (title[i].trim().isEmpty) continue;
      if (++count > maxChars) {
        return '${title.substring(0, i).trimRight()}…';
      }
    }
    return title;
  }

  /// A log in the day menu: its heading or first words, no longer than the
  /// day's date below it, with its time underneath.
  Widget _entryChoice(
      BuildContext context, Entry entry, DateFormat timeFormat, DateTime day) {
    final theme = Theme.of(context);
    final time = timeFormat.format(entry.timeCreate);
    final dateLength = TimeManager.formatDate(day, context)
        .replaceAll(RegExp(r'\s'), '')
        .length;
    final title = _clip(EntryLinks.titleOf(entry), dateLength);
    return Row(
      children: [
        const Icon(Icons.edit_note_rounded),
        const SizedBox(width: 12),
        Flexible(
          child: title.isEmpty
              ? Text(time)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openEditor(DateTime day, Entry? entry) async {
    setState(() => _opening = true);
    final newAttachments = <NewAttachment>[];
    try {
      final payload = widget.payload;
      newAttachments
        ..addAll(
            await EntryAttachmentActions.importSharedImages(payload.imagePaths))
        ..addAll(
            await EntryAttachmentActions.importSharedVideos(payload.videoPaths))
        ..addAll(
            await EntryAttachmentActions.importSharedAudio(payload.audioPaths));
    } catch (_) {
      await EntryAttachmentActions.deleteStoredAttachments(newAttachments);
      if (mounted) setState(() => _opening = false);
      rethrow;
    }
    if (!mounted) {
      await EntryAttachmentActions.deleteStoredAttachments(newAttachments);
      return;
    }

    // Leaving the editor goes back through the entry view and the day's
    // Timeline, not straight to the calendar (3.7.0.39)
    final navigator = Navigator.of(context);
    final share = ShareReturn.currentShare;
    void onShareExit(Entry? kept, int? removedId) => ShareReturn.show(navigator,
        kept: kept, day: day, removedId: removedId, share: share);
    final page = entry == null
        ? AddEditEntryPage(
            overrideCreateDate: TimeManager.currentTimeOnDifferentDate(day)
                .copyWith(isUtc: false),
            attachments: EntryAttachment.appendRanked(const [], newAttachments,
                entryId: -1),
            sharedText: widget.payload.text,
            onLeave: onShareExit,
          )
        : AddEditEntryPage(
            entry: entry,
            attachments: EntryAttachment.appendRanked(
                EntryAttachmentsProvider.instance.getForEntry(entry),
                newAttachments,
                entryId: entry.id!),
            sharedText: widget.payload.text,
            onLeave: onShareExit,
          );
    await navigator.pushReplacement(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => page,
    ));
  }

  Widget _previewTile(String path) {
    final payload = widget.payload;
    if (payload.videoPaths.contains(path)) {
      final cache = VideoThumbnailCache.instance;
      return VideoTileBackground(
        id: path,
        peek: () => cache.peekForPath(path),
        load: () => cache.getThumbnailForPath(path),
      );
    }
    if (payload.audioPaths.contains(path)) {
      return AudioTileBackground(seed: path.hashCode);
    }
    return Image.file(File(path), fit: BoxFit.cover, cacheWidth: 500);
  }

  Widget _buildPreview() {
    final payload = widget.payload;
    final text = payload.text;
    final hasText = text != null && text.isNotEmpty;
    final mediaPaths = [
      ...payload.imagePaths,
      ...payload.videoPaths,
      ...payload.audioPaths,
    ];
    final card = LargeCard(
      media: mediaPaths.isEmpty
          ? null
          : AttachmentGrid.fromPaths(
              attachmentPaths: mediaPaths,
              pathTileBuilder: _previewTile,
            ),
      body: hasText ? LargeCard.markdownBody(text) : null,
    );
    if (mediaPaths.isEmpty || hasText) return card;
    return Center(child: AspectRatio(aspectRatio: 1, child: card));
  }

  Future<void> _pickSearchDay() async {
    final entries = EntriesProvider.instance.entries;
    final picked = await TimeManager.pickDate(
      context,
      initialDate: _searchDay ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: entries.isEmpty
          ? DateTime.now()
          : entries
              .map((entry) => entry.timeCreate)
              .reduce((a, b) => a.isAfter(b) ? a : b),
      selectableDayPredicate: (date) =>
          EntriesProvider.instance.getEntriesForDate(date).isNotEmpty,
    );
    if (picked != null && mounted) setState(() => _searchDay = picked);
  }

  Widget _searchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final day = _searchDay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBar(
          key: const ValueKey('share-search'),
          controller: _search,
          elevation: const WidgetStatePropertyAll(0),
          leading: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.search_rounded),
          ),
          trailing: [
            if (_search.text.isNotEmpty)
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(_search.clear),
              ),
          ],
          hintText: l10n.searchLogsHint,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        InputChip(
          avatar: const Icon(Icons.calendar_month_rounded),
          label: Text(day == null
              ? l10n.linkAnyDate
              : TimeManager.formatDateWithWeekday(day, context)),
          onPressed: _pickSearchDay,
          onDeleted:
              day == null ? null : () => setState(() => _searchDay = null),
        ),
      ],
    );
  }

  /// Logs matching the search; tapping one adds what's shared to it.
  Widget _searchResults(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _search.text.trim().toLowerCase();
    final day = _searchDay;
    final entries = EntriesProvider.instance.entries.where((entry) {
      if (entry.id == null) return false;
      if (day != null && !TimeManager.isSameDay(entry.timeCreate, day)) {
        return false;
      }
      return query.isEmpty || entry.text.toLowerCase().contains(query);
    }).toList();
    if (entries.isEmpty) return Center(child: Text(l10n.noResults));
    final timeFormat = TimeManager.localizedTimeFormat(
        context, TimeManager.currentLocale(context));
    return ListView.builder(
      key: const ValueKey('share-search-results'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final title = EntryLinks.titleOf(entry);
        final when =
            '${TimeManager.formatDateWithWeekday(entry.timeCreate, context)} · '
            '${timeFormat.format(entry.timeCreate)}';
        final snippet = matchSnippet(entry.body, query);
        return ListTile(
          title: Text(
            title.isEmpty ? l10n.writeSomethingHint : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: snippet == null
              ? Text(when)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EntrySnippetText(snippet: snippet, query: query),
                    Text(when),
                  ],
                ),
          isThreeLine: snippet != null,
          onTap: _opening
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  _openEditor(entry.timeCreate, entry);
                },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendar = VerticalCalendar(
      scrollController: _scrollController,
      onDaySelected: _selectDay,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(AppLocalizations.of(context)!.shareAddToLogPickerTitle),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Column(
                children: [
                  // Smaller while searching, to leave room for results
                  SizedBox(
                      height: _searching ? 96 : 200, child: _buildPreview()),
                  const SizedBox(height: 8),
                  _searchBar(context),
                  const SizedBox(height: 4),
                  Expanded(
                      child: _searching ? _searchResults(context) : calendar),
                ],
              ),
            ),
            if (_opening)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
