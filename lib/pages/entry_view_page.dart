// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/locations.dart';
import 'dart:io';

import 'package:daily_you/fork/checklists.dart';
import 'package:daily_you/fork/double_tap_to_edit.dart';
import 'package:daily_you/fork/hyphenation.dart';
import 'package:daily_you/fork/entry_share.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/search_highlight.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/pages/edit_entry_page.dart';
import 'package:daily_you/pages/attachment_view_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/attachment_tile_background.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:daily_you/widgets/entry_tag_chips.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class EntryViewPage extends StatefulWidget {
  const EntryViewPage({
    super.key,
    required this.entryId,
    required this.onEntryEdited,
    this.searchQuery,
  });

  final int entryId;
  final Function(int entryId) onEntryEdited;

  /// Gallery search text: highlighted, with ▲▼ to move between matches.
  final String? searchQuery;

  @override
  State<EntryViewPage> createState() => _EntryViewPageState();
}

class _EntryViewPageState extends State<EntryViewPage> {
  late String _query = widget.searchQuery ?? '';
  int _currentMatch = 0;
  final List<GlobalKey> _matchKeys = [];
  bool _jumpedToFirst = false;

  void _showMatch(int index) {
    if (_matchKeys.isEmpty) return;
    final count = _matchKeys.length;
    setState(() => _currentMatch = (index % count + count) % count);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentMatch >= _matchKeys.length) return;
      final matchContext = _matchKeys[_currentMatch].currentContext;
      if (matchContext == null) return;
      Scrollable.ensureVisible(matchContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    });
  }

  Widget? _matchNavigator(int total) {
    if (_query.isEmpty || total == 0) return null;
    if (!_jumpedToFirst) {
      _jumpedToFirst = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMatch(0);
      });
    }
    return SearchMatchNavigator(
      current: _currentMatch.clamp(0, total - 1),
      total: total,
      onPrevious: () => _showMatch(_currentMatch - 1),
      onNext: () => _showMatch(_currentMatch + 1),
      onClose: () => setState(() => _query = ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final entryAttachmentsProvider =
        Provider.of<EntryAttachmentsProvider>(context);

    final entry = entriesProvider.entries
        .where((e) => e.id == widget.entryId)
        .firstOrNull;
    if (entry == null) return const Scaffold();

    final attachments = entryAttachmentsProvider.getForEntry(entry);
    final (body, places) = EntryLocations.split(entry.text);
    final matchTotal = SearchHighlight.count(body, _query);
    // Justified text gets a little more width, so lines hold more words.
    final justify = JustifyText.enabled;
    final side = justify ? 4.0 : 8.0;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _matchNavigator(matchTotal),
      appBar: AppBar(
        actions: [
          _shareButton(context, entry, attachments),
          _editButton(context, entry, attachments),
          _addEntryButton(context, entry),
          _favouriteButton(context, entry),
        ],
      ),
      body: DoubleTapToEdit(
        onDoubleTap: () => _openEditor(context, entry, attachments),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.only(left: side, right: side),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (attachments.isNotEmpty && attachments.length > 1)
                        _attachmentsList(context, attachments),
                      if (attachments.isNotEmpty && attachments.length == 1)
                        GestureDetector(
                          child: Center(
                            child: SizedBox(
                              height: 220,
                              width: 220,
                              child: Card.filled(
                                  clipBehavior: Clip.antiAlias,
                                  child: AttachmentTileBackground(
                                      attachment: attachments.first)),
                            ),
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                                AttachmentViewPage.route(
                                    attachments: attachments, index: 0));
                          },
                        ),
                      Card.filled(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 8, top: 4, bottom: 4, right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    IntrinsicHeight(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            TimeManager.formatDateWithWeekday(
                                              entry.timeCreate,
                                              context,
                                            ),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          VerticalDivider(
                                            width: 16,
                                            thickness: 2,
                                            radius: BorderRadius.circular(4),
                                          ),
                                          Text(
                                            TimeManager.localizedTimeFormat(
                                                    context,
                                                    TimeManager.currentLocale(
                                                        context))
                                                .format(entry.timeCreate),
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: theme.dividerColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    MoodIcon(
                                      moodValue: entry.mood,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                              EntryTagChips(
                                entryId: entry.id!,
                                padding:
                                    const EdgeInsets.only(top: 2, bottom: 2),
                                chipBuilder: (tag, entryTag) =>
                                    TagChip(tag: tag, value: entryTag.value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (body.isNotEmpty)
                        Card.filled(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            child: Padding(
                                padding: EdgeInsets.only(
                                    left: side + 2,
                                    top: 4,
                                    bottom: 4,
                                    right: side + 2),
                                child: ScaledMarkdown(
                                  data: body,
                                  selectable: false,
                                  justify: justify,
                                  onCheckboxTap: (index) =>
                                      Checklists.toggleInEntry(entry, index),
                                  searchQuery: _query,
                                  currentMatch: _currentMatch,
                                  matchKeys: _matchKeys,
                                ))),
                      LocationButtons(places: places),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 8, top: 4, bottom: 18, right: 8),
                        child: Text(
                          "${AppLocalizations.of(context)!.lastModified}: ${TimeManager.formatDateWithWeekday(entry.timeModified, context)} ${TimeManager.localizedTimeFormat(context, TimeManager.currentLocale(context)).format(entry.timeModified)}",
                          style: TextStyle(
                              fontSize: 12, color: theme.disabledColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editButton(
      BuildContext context, entry, List<EntryAttachment> attachments) {
    return IconButton(
        icon: const Icon(Icons.edit_rounded),
        onPressed: () => _openEditor(context, entry, attachments));
  }

  bool _editorOpen = false;

  Future<void> _openEditor(BuildContext context, Entry entry,
      List<EntryAttachment> attachments) async {
    if (_editorOpen) return;
    _editorOpen = true;
    try {
      await Navigator.of(context).push(PageRouteBuilder(
        allowSnapshotting: false,
        fullscreenDialog: true,
        pageBuilder: (context, _, __) =>
            AddEditEntryPage(entry: entry, attachments: attachments),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ));

      widget.onEntryEdited(entry.id!);
    } finally {
      _editorOpen = false;
    }
  }

  /// Adds a new entry on the same day as the entry being viewed.
  Widget _addEntryButton(BuildContext context, Entry entry) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.timelineAddEntry,
      icon: const Icon(Icons.add_rounded),
      onPressed: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          allowSnapshotting: false,
          builder: (context) => AddEditEntryPage(
            overrideCreateDate:
                TimeManager.currentTimeOnDifferentDate(entry.timeCreate)
                    .copyWith(isUtc: false),
          ),
        ));
      },
    );
  }

  Widget _favouriteButton(BuildContext context, Entry entry) {
    final id = entry.id;
    if (id == null) return const SizedBox.shrink();
    return Consumer<TagsProvider>(builder: (context, _, __) {
      final localizations = AppLocalizations.of(context)!;
      final isFavourite = Favourites.isFavourite(id);
      return IconButton(
        tooltip: isFavourite
            ? localizations.favouriteRemove
            : localizations.favouriteAdd,
        icon: isFavourite
            ? const Icon(Icons.star_rounded, color: Color(0xFFF2B33D))
            : const Icon(Icons.star_outline_rounded),
        onPressed: () => Favourites.toggle(id),
      );
    });
  }

  Widget _shareButton(
      BuildContext context, Entry entry, List<EntryAttachment> attachments) {
    final canShare =
        Platform.isAndroid && (attachments.isNotEmpty || entry.text.isNotEmpty);
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.share_rounded),
      tooltip: l10n.shareEntry,
      onSelected: (choice) async {
        if (choice == 'copy') {
          await EntryLinks.copyLink(context, entry);
        } else {
          await _shareEntry(context, entry, attachments);
        }
      },
      itemBuilder: (context) => [
        if (canShare)
          PopupMenuItem(
            value: 'share',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.share_rounded),
              title: Text(l10n.shareEntry),
            ),
          ),
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link_rounded),
            title: Text(l10n.linkCopyToEntry),
          ),
        ),
      ],
    );
  }

  Future<void> _shareEntry(BuildContext context, Entry entry,
          List<EntryAttachment> attachments) =>
      EntryShare.share(context, [entry]);

  Widget _attachmentsList(
      BuildContext context, List<EntryAttachment> attachments) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const tileSize = 160.0;
        final fits = attachments.length * tileSize <= constraints.maxWidth;

        if (fits) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: attachments
                  .map(
                    (attachment) => SizedBox(
                      width: tileSize,
                      child: GestureDetector(
                        child: Center(
                          child: SizedBox(
                            height: tileSize,
                            width: tileSize,
                            child: Card.filled(
                                clipBehavior: Clip.antiAlias,
                                child: AttachmentTileBackground(
                                    attachment: attachment)),
                          ),
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                              AttachmentViewPage.route(
                                  attachments: attachments,
                                  index: attachments.indexWhere(
                                      (x) => x.id == attachment.id)));
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return SizedBox(
          height: tileSize,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  child: Center(
                    child: SizedBox(
                      height: tileSize,
                      width: tileSize,
                      child: Card.filled(
                          clipBehavior: Clip.antiAlias,
                          child: AttachmentTileBackground(
                              attachment: attachments[index])),
                    ),
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(AttachmentViewPage.route(
                        attachments: attachments, index: index));
                  },
                );
              }),
        );
      },
    );
  }
}
