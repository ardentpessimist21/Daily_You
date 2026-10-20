// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';

/// Entries dated after today ("upcoming"). Off by default. While on, the
/// calendar and date pickers reach 12 months ahead. Upcoming entries stay out
/// of stats, streaks and flashbacks until their day arrives.
class FutureEntries {
  static const int monthsAhead = 12;

  static bool get enabled =>
      ConfigProvider.instance.get(Settings.allowFutureEntries);

  /// Whether [entry] is dated after today.
  static bool isUpcoming(Entry entry, {DateTime? now}) =>
      !entry.timeCreate.isBefore(_startOfTomorrow(now));

  /// [entries] without upcoming ones, keeping their order.
  static List<Entry> past(List<Entry> entries, {DateTime? now}) {
    final cutoff = _startOfTomorrow(now);
    if (!entries.any((entry) => !entry.timeCreate.isBefore(cutoff))) {
      return entries;
    }
    return entries.where((entry) => entry.timeCreate.isBefore(cutoff)).toList();
  }

  /// Upcoming entries, soonest first.
  static List<Entry> upcoming(List<Entry> entries, {DateTime? now}) {
    final cutoff = _startOfTomorrow(now);
    return entries.where((entry) => !entry.timeCreate.isBefore(cutoff)).toList()
      ..sort((a, b) => a.timeCreate.compareTo(b.timeCreate));
  }

  /// The last day a date picker should offer.
  static DateTime lastPickableDate() {
    final now = DateTime.now();
    if (!enabled) return now;
    return DateTime(now.year, now.month + monthsAhead + 1, 0);
  }

  static DateTime _startOfTomorrow(DateTime? now) {
    final today = TimeManager.startOfDay(now ?? DateTime.now());
    return DateTime(today.year, today.month, today.day + 1);
  }
}
