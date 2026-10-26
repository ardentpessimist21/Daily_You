// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

/// The years and months the Jump to month picker offers.
///
/// Years start at the first entry's year (2000 if there are none) and end
/// at the last month the calendar shows, which runs ahead of today when
/// future entries are on. Works on plain year/month numbers so the same
/// logic serves both the Gregorian and Jalali pickers.
class YearMonthRange {
  final int firstYear;
  final int lastYear;
  final int lastMonth;

  YearMonthRange({
    required int firstYear,
    required this.lastYear,
    required this.lastMonth,
  }) : firstYear = firstYear > lastYear ? lastYear : firstYear;

  static const int fallbackFirstYear = 2000;

  /// First year to offer: the earliest entry's year, or 2000 with no entries
  static int firstYearFor(Iterable<DateTime> entryDates) {
    int? earliest;
    for (final date in entryDates) {
      if (earliest == null || date.year < earliest) earliest = date.year;
    }
    return earliest ?? fallbackFirstYear;
  }

  List<int> get years =>
      List.generate(lastYear - firstYear + 1, (i) => firstYear + i);

  /// How many months to offer in [year] (1 to this number)
  int monthCount(int year) => year >= lastYear ? lastMonth : 12;

  /// Nearest year/month inside the range, so the picker never shows blank
  (int, int) clamp(int year, int month) {
    if (year < firstYear) return (firstYear, 1);
    if (year > lastYear) return (lastYear, lastMonth);
    final count = monthCount(year);
    if (month > count) return (year, count);
    if (month < 1) return (year, 1);
    return (year, month);
  }
}
