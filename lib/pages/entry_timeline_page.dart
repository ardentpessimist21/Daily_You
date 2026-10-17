// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
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
  });

  final String header;
  final List<Entry> Function() getEntries;
  final String Function(BuildContext, Entry) labelBuilder;

  /// Pushes a timeline listing every entry created on [date], ordered
  /// newest first, with each entry labeled by its time of day.
  static Future<void> pushForDay(BuildContext context, DateTime date) {
    final title = TimeManager.formatDate(date, context);
    return Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntryTimelinePage(
        header: title,
        getEntries: () => EntriesProvider.instance.entries
            .where((entry) => TimeManager.isSameDay(entry.timeCreate, date))
            .toList()
            .reversed
            .toList(),
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
  @override
  Widget build(BuildContext context) {
    Provider.of<EntriesProvider>(context);
    final entryAttachmentsProvider =
        Provider.of<EntryAttachmentsProvider>(context);

    final showFullEntries = Provider.of<ConfigProvider>(context)
        .get(Settings.timelineShowFullEntries);

    final entries = widget.getEntries();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entries.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.header)),
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
