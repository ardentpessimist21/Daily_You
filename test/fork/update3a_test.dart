// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/future_entries.dart';
import 'package:daily_you/fork/search_highlight.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Entry _entry(int id, DateTime time, [String text = '']) =>
    Entry(id: id, text: text, timeCreate: time, timeModified: time);

void main() {
  group('FutureEntries', () {
    final now = DateTime(2026, 10, 20, 10, 15);
    final entries = [
      _entry(1, DateTime(2026, 11, 2, 9)),
      _entry(2, DateTime(2026, 10, 21, 0, 0)),
      _entry(3, DateTime(2026, 10, 20, 23, 59)),
      _entry(4, DateTime(2026, 10, 19, 8)),
    ];

    test('later today is not upcoming, tomorrow is', () {
      expect(FutureEntries.isUpcoming(entries[2], now: now), isFalse);
      expect(FutureEntries.isUpcoming(entries[1], now: now), isTrue);
    });

    test('past keeps order and drops upcoming entries', () {
      expect(FutureEntries.past(entries, now: now).map((e) => e.id), [3, 4]);
    });

    test('past returns the same list when nothing is upcoming', () {
      final pastOnly = entries.sublist(2);
      expect(
          identical(FutureEntries.past(pastOnly, now: now), pastOnly), isTrue);
    });

    test('upcoming is soonest first', () {
      expect(
          FutureEntries.upcoming(entries, now: now).map((e) => e.id), [2, 1]);
    });
  });

  group('On this day', () {
    test('only matches past years', () {
      final today = DateTime(2026, 10, 20);
      expect(TimeManager.isOnThisDayMatch(DateTime(2025, 10, 20), today, false),
          isTrue);
      expect(TimeManager.isOnThisDayMatch(DateTime(2027, 10, 20), today, false),
          isFalse);
      expect(TimeManager.isOnThisDayMatch(today, today, false), isFalse);
    });
  });

  group('SearchHighlight', () {
    test('counts case-insensitively', () {
      expect(SearchHighlight.count('Meds round. MEDS again, meds.', 'meds'), 3);
      expect(SearchHighlight.count('nothing here', 'meds'), 0);
      expect(SearchHighlight.count('anything', ''), 0);
    });

    test('preview keeps the start when the match is near the top', () {
      const text = 'Night shift and meds round.';
      expect(SearchHighlight.preview(text, 'meds'), text);
    });

    test('preview starts near a match further down', () {
      final text =
          '${'Long day on the ward. ' * 12}\nFinally did the meds round.';
      final preview = SearchHighlight.preview(text, 'meds');
      expect(preview, startsWith('…'));
      expect(preview, contains('meds round'));
      expect(preview.length, lessThan(text.length));
    });
  });

  group('SearchMatchCounter', () {
    test('wraps each match and numbers them in order', () {
      final counter = SearchMatchCounter('tea', current: 1);
      final (marked, found) = counter.mark(const TextSpan(
          text: 'Tea break, more tea', children: [TextSpan(text: ' and TEA')]));
      expect(found, 3);
      final plain = marked.toPlainText();
      expect(plain, 'Tea break, more tea and TEA');
    });

    test('leaves spans without matches untouched', () {
      const span = TextSpan(text: 'Coffee first');
      final (marked, found) = SearchMatchCounter('tea').mark(span);
      expect(found, 0);
      expect(identical(marked, span), isTrue);
    });
  });

  testWidgets('markdown reports one block key per match', (tester) async {
    final keys = <GlobalKey>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScaledMarkdown(
          data: 'Meds round\n\nNo match here\n\nmeds and **MEDS**',
          searchQuery: 'meds',
          matchKeys: keys,
          selectable: false,
        ),
      ),
    ));
    expect(keys.length, 3);
    // The last two share a paragraph, so they share a block.
    expect(identical(keys[1], keys[2]), isTrue);
    expect(keys[0].currentContext, isNotNull);
  });
}
