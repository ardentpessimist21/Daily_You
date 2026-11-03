// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/pages/entry_timeline_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:material_ui/material_ui.dart';

/// Where leaving the editor goes after sharing into Daily You (3.7.0.39).
enum ShareReturnStop { timeline, entryView }

/// After sharing media or a link into an entry, leaving the editor goes back
/// the way a calendar tap would have come in: that entry's view, then the
/// day's Timeline when the day has other entries, then the calendar.
class ShareReturn {
  ShareReturn._();

  // Bumped by each incoming share, so an editor closed by a newer share
  // doesn't put its pages back on top of the new one.
  static int _share = 0;

  /// Call when a new share arrives, before clearing back to the calendar.
  static void newShare() => _share++;

  /// The current share, to pass back to [show].
  static int get currentShare => _share;

  /// The pages to put back, bottom first. [kept] is the entry still there
  /// after the editor closed (null when it was discarded or deleted), [day]
  /// the day it was shared to, and [removedId] an entry being deleted.
  static List<ShareReturnStop> stops({
    required Entry? kept,
    required DateTime day,
    required List<Entry> entries,
    int? removedId,
  }) {
    final shownDay = kept?.timeCreate ?? day;
    final sameDay = entries
        .where((e) => e.id != removedId)
        .where((e) => TimeManager.isSameDay(e.timeCreate, shownDay))
        .toList();
    if (kept != null) {
      return [
        if (sameDay.length >= 2) ShareReturnStop.timeline,
        ShareReturnStop.entryView,
      ];
    }
    return [if (sameDay.isNotEmpty) ShareReturnStop.timeline];
  }

  /// Puts the pages back on [navigator] without a slide-in, so they look
  /// like they were underneath the editor all along. Back still animates.
  static void show(
    NavigatorState navigator, {
    required Entry? kept,
    required DateTime day,
    int? removedId,
    int? share,
  }) {
    if (!navigator.mounted) return;
    if (share != null && share != _share) return;
    final entries = EntriesProvider.instance.entries;
    final shownDay = DateUtils.dateOnly(kept?.timeCreate ?? day);
    for (final stop in stops(
        kept: kept, day: day, entries: entries, removedId: removedId)) {
      switch (stop) {
        case ShareReturnStop.timeline:
          navigator.push(_InstantRoute(
            builder: (context) => EntryTimelinePage.forDay(context, shownDay),
          ));
        case ShareReturnStop.entryView:
          final id = kept!.id!;
          navigator.push(_InstantRoute(
            builder: (context) => EntriesListPage(
              index: EntriesProvider.instance.getIndexOfEntry(id),
              getEntries: () => EntriesProvider.instance.entries,
            ),
          ));
      }
    }
  }
}

/// Appears at once, leaves with the usual page animation.
class _InstantRoute<T> extends MaterialPageRoute<T> {
  _InstantRoute({required super.builder}) : super(allowSnapshotting: false);

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);
}
