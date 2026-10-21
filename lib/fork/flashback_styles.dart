// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/flashback_manager.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// How flashbacks appear on Home: the original tall cards, a slim row of
/// chips, or a ✨ button in the top bar that opens a short list.
class FlashbackStyle {
  static const String cards = 'cards';
  static const String chips = 'chips';
  static const String icon = 'icon';

  static String get current =>
      ConfigProvider.instance.get(Settings.flashbackStyle);
}

/// Opens the timeline of entries written on [referenceDate]'s day in past
/// years.
Future<void> openOnThisDayTimeline(
    BuildContext context, DateTime referenceDate) async {
  final isJalali = TimeManager.isJalaliCalendar(context);
  final refYear = TimeManager.calendarYearOf(referenceDate, isJalali);

  final hasEntries = EntriesProvider.instance.entries.any((e) =>
      TimeManager.isOnThisDayMatch(e.timeCreate, referenceDate, isJalali));
  if (!hasEntries || !context.mounted) return;

  await Navigator.of(context).push(MaterialPageRoute(
    allowSnapshotting: false,
    builder: (context) => EntryTimelinePage(
      header: AppLocalizations.of(context)!.flashbackOnThisDay,
      getEntries: () => EntriesProvider.instance.entries
          .where((e) => TimeManager.isOnThisDayMatch(
              e.timeCreate, referenceDate, isJalali))
          .toList(),
      labelBuilder: (_, e) => AppLocalizations.of(context)!.flashbackYear(
          refYear - TimeManager.calendarYearOf(e.timeCreate, isJalali)),
    ),
  ));
}

/// Opens a flashback the same way whichever style it's shown in: a single
/// entry opens directly, several open as a timeline.
Future<void> openFlashback(BuildContext context, Flashback flashback) async {
  if (flashback.isMultiEntry && flashback.isOnThisDay) {
    await NotificationManager.instance.dismissOnThisDayNotification();
    if (!context.mounted) return;
    await openOnThisDayTimeline(context, DateTime.now());
  } else if (flashback.isMultiEntry) {
    final flashbackEntryIds = flashback.entries.map((e) => e.id).toList();
    final title = flashback.title;
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntryTimelinePage(
        header: title,
        getEntries: () => EntriesProvider.instance.entries
            .where((e) => flashbackEntryIds.contains(e.id))
            .toList()
            .reversed
            .toList(),
        labelBuilder: (context, e) => TimeManager.localizedTimeFormat(
                context, TimeManager.currentLocale(context))
            .format(e.timeCreate),
      ),
    ));
  } else {
    await Navigator.of(context).push(MaterialPageRoute(
      allowSnapshotting: false,
      builder: (context) => EntriesListPage(
          index: EntriesProvider.instance
              .getIndexOfEntry(flashback.firstEntry.id!),
          getEntries: () => EntriesProvider.instance.entries),
    ));
  }
}

IconData _iconFor(BuildContext context, Flashback flashback) {
  final l10n = AppLocalizations.of(context)!;
  if (flashback.isOnThisDay) return Icons.history_rounded;
  if (flashback.title == l10n.flashbackGoodDay) {
    return Icons.sentiment_very_satisfied_rounded;
  }
  if (flashback.title == l10n.flashbackRandomDay) return Icons.shuffle_rounded;
  return Icons.event_rounded;
}

String _subtitleFor(BuildContext context, Flashback flashback) {
  if (flashback.isOnThisDay) {
    final isJalali = TimeManager.isJalaliCalendar(context);
    return flashback.entries
        .map((e) => TimeManager.calendarYearOf(e.timeCreate, isJalali))
        .toSet()
        .join(', ');
  }
  final firstLine = flashback.firstEntry.body
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[#*_=~>`\[\]]'), '').trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  final date = TimeManager.formatDate(flashback.firstEntry.timeCreate, context);
  return firstLine.isEmpty ? date : '$date · $firstLine';
}

/// One slim row of tappable chips, in place of the tall flashback cards.
class FlashbackChipsRow extends StatelessWidget {
  const FlashbackChipsRow({super.key, required this.flashbacks});

  final List<Flashback> flashbacks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: flashbacks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final flashback = flashbacks[index];
          return ActionChip(
            avatar: Icon(_iconFor(context, flashback),
                size: 18, color: colorScheme.primary),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(flashback.title),
                if (flashback.isOnThisDay && flashback.isMultiEntry) ...[
                  const SizedBox(width: 6),
                  _CountBadge(count: flashback.entries.length),
                ],
              ],
            ),
            shape: const StadiumBorder(),
            onPressed: () => openFlashback(context, flashback),
          );
        },
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$count',
          style:
              TextStyle(fontSize: 11, color: colorScheme.onPrimaryContainer)),
    );
  }
}

/// The ✨ top-bar button for the "icon" style. Hidden when there are no
/// flashbacks today; shows a count until the list has been opened today.
class FlashbackIconButton extends StatelessWidget {
  const FlashbackIconButton({super.key});

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context);
    final entries = Provider.of<EntriesProvider>(context).entries;
    if (!config.get(Settings.showFlashbacks) ||
        config.get(Settings.flashbackStyle) != FlashbackStyle.icon) {
      return const SizedBox.shrink();
    }
    final flashbacks = FlashbackManager.getFlashbacks(context, entries);
    if (flashbacks.isEmpty) return const SizedBox.shrink();

    final seenToday = config.get(Settings.flashbackIconSeenDay) == _todayKey();
    final l10n = AppLocalizations.of(context)!;
    return Builder(builder: (buttonContext) {
      return IconButton(
        tooltip: l10n.flashbacksTitle,
        icon: Badge(
          isLabelVisible: !seenToday,
          label: Text('${flashbacks.length}'),
          child: const Icon(Icons.auto_awesome_rounded),
        ),
        onPressed: () => _showList(buttonContext, flashbacks),
      );
    });
  }

  Future<void> _showList(
      BuildContext buttonContext, List<Flashback> flashbacks) async {
    ConfigProvider.instance.set(Settings.flashbackIconSeenDay, _todayKey());

    final box = buttonContext.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final chosen = await showMenu<Flashback>(
      context: buttonContext,
      position: position,
      items: [
        for (final flashback in flashbacks)
          PopupMenuItem<Flashback>(
            value: flashback,
            child: Builder(builder: (context) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_iconFor(context, flashback),
                    color: Theme.of(context).colorScheme.primary),
                title: Text(flashback.title),
                subtitle: Text(_subtitleFor(context, flashback),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: flashback.isOnThisDay && flashback.isMultiEntry
                    ? _CountBadge(count: flashback.entries.length)
                    : null,
              );
            }),
          ),
      ],
    );
    if (chosen != null && buttonContext.mounted) {
      await openFlashback(buttonContext, chosen);
    }
  }
}
