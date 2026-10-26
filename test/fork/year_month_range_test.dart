// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/year_month_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YearMonthRange', () {
    test('years start at the first entry and run to the last month', () {
      final range =
          YearMonthRange(firstYear: 2019, lastYear: 2027, lastMonth: 4);
      expect(range.years.first, 2019);
      expect(range.years.last, 2027);
      expect(range.years.length, 9);
    });

    test('future months are offered when the calendar runs ahead', () {
      // Today is Oct 2026, calendar shows up to Dec 2026
      final range =
          YearMonthRange(firstYear: 2020, lastYear: 2026, lastMonth: 12);
      expect(range.monthCount(2026), 12);
      expect(range.clamp(2026, 11), (2026, 11));
    });

    test('a visible month past the range clamps instead of going blank', () {
      final range =
          YearMonthRange(firstYear: 2020, lastYear: 2026, lastMonth: 10);
      expect(range.clamp(2026, 11), (2026, 10));
      expect(range.clamp(2027, 1), (2026, 10));
      expect(range.clamp(2018, 5), (2020, 1));
    });

    test('earlier years always offer all 12 months', () {
      final range =
          YearMonthRange(firstYear: 2020, lastYear: 2026, lastMonth: 10);
      expect(range.monthCount(2025), 12);
      expect(range.clamp(2025, 12), (2025, 12));
    });

    test('first year comes from the oldest entry, 2000 with none', () {
      expect(
          YearMonthRange.firstYearFor([
            DateTime(2024, 3, 1),
            DateTime(2019, 7, 2),
            DateTime(2026, 1, 1),
          ]),
          2019);
      expect(YearMonthRange.firstYearFor([]), 2000);
    });

    test('a first year after the last year collapses to one year', () {
      final range =
          YearMonthRange(firstYear: 2030, lastYear: 2026, lastMonth: 10);
      expect(range.years, [2026]);
    });
  });
}
