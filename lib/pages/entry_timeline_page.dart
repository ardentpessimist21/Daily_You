// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

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
  });

  final String header;
  final List<Entry> Function() getEntries;
  final String Function(BuildContext, Entry) labelBuilder;

  /// When set, an add button creates a new entry on this day. Left null for
  /// timelines that span several days, such as "On this day".
  final DateTime? addEntryDate;

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
    final showFullEntries = configProvider.get(Settings.timelineShowFullEntries);
    final oldestFirst = configProvider.get(Settings.timelineOldestFirst);
    final addEntryDate = widget.addEntryDate;

    final entries = List<Entry>.from(widget.getEntries())
      ..sort((a, b) => oldestFirst
          ? a.timeCreate.compareTo(b.timeCreate)
          : b.timeCreate.compareTo(a.timeCreate));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entries.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.header),
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
      body: ListView.builder(
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

          if (showFullEntries) {
            return _FullEntryTimelineRow(
              isFirst: index == 0,
              isLast: index == entries.length - 1,
              onTap: openEntry,
              child: FullEntryCardWidget(
                title: label,
                entry: entry,
                attachments: entryAttachments,
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
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
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
                      onTap: openEntry,
                      child: LargeEntryCardWidget(
                        title: label,
                        entry: entry,
                        attachments: entryAttachments,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
    required this.child,
  });

  static const double _railWidth = 36;
  static const double _lineWidth = 3;
  static const double _dotSize = 14;
  static const double _dotTop = 12;

  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
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
          left: (_railWidth - _dotSize) / 2,
          top: _dotTop,
          width: _dotSize,
          height: _dotSize,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: railColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _railWidth, right: 8, bottom: 8),
          child: GestureDetector(onTap: onTap, child: child),
        ),
      ],
    );
  }
}
