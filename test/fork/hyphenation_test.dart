// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/hyphenation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

String _split(String word) {
  final breaks = Hyphenation.enUs.breaks(word);
  final out = StringBuffer();
  var from = 0;
  for (final point in breaks) {
    out
      ..write(word.substring(from, point))
      ..write('-');
    from = point;
  }
  out.write(word.substring(from));
  return out.toString();
}

/// Each line of [span] laid out at [width] (Ahem test font: every
/// character is exactly one font size wide).
List<String> _lines(InlineSpan span, double width) {
  final painter = TextPainter(
    text: TextSpan(style: const TextStyle(fontSize: 10), children: [span]),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final text = painter.plainText;
  final lines = <String>[];
  var offset = 0;
  while (offset < text.length) {
    final line = painter.getLineBoundary(TextPosition(offset: offset));
    lines.add(text.substring(line.start, line.end));
    offset = line.end > offset ? line.end : offset + 1;
    while (offset < text.length && text[offset] == ' ') {
      offset++;
    }
  }
  painter.dispose();
  return lines;
}

void main() {
  group('Hyphenation', () {
    test('splits words where a hyphen reads naturally', () {
      expect(_split('hyphenation'), 'hy-phen-ation');
      expect(_split('documentation'), 'doc-u-men-ta-tion');
      expect(_split('pharmacokinetics'), contains('-'));
    });

    test('short words and the ends of words stay whole', () {
      expect(_split('night'), 'night');
      expect(_split('shift'), 'shift');
      for (final word in ['medication', 'glomerular', 'intimidating']) {
        final parts = _split(word).split('-');
        expect(parts.first.length, greaterThanOrEqualTo(2), reason: word);
        expect(parts.last.length, greaterThanOrEqualTo(3), reason: word);
      }
    });

    test('known exceptions use their own breaks', () {
      expect(_split('associate'), 'as-so-ciate');
    });
  });

  group('Hyphenated layout', () {
    const style = TextStyle(fontSize: 10);

    InlineSpan layout(InlineSpan span, double width) => HyphenatedLayout.apply(
          span,
          maxWidth: width,
          style: style,
          textScaler: TextScaler.noScaling,
        );

    test('a split word gets a visible hyphen at the line end', () {
      final result = layout(const TextSpan(text: 'aa medication round'), 90);
      final text = result.toPlainText();
      expect(text.contains(Hyphenation.softHyphen), isFalse);
      final lines = _lines(result, 90);
      expect(lines.first, endsWith('-'));
      // Hyphens only ever at a line end
      for (final line in lines.skip(1)) {
        expect(line.contains('-'), isFalse, reason: line);
      }
      expect(text.replaceAll('-', ''), 'aa medication round');
    });

    test('text that fits is left exactly as it was', () {
      const span = TextSpan(text: 'medication round');
      final result = layout(span, 1000);
      expect(result.toPlainText(), 'medication round');
    });

    test('styles and links survive', () {
      final result = layout(
          const TextSpan(children: [
            TextSpan(text: 'aa '),
            TextSpan(
                text: 'medication',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' round'),
          ]),
          90);
      var boldText = '';
      result.visitChildren((span) {
        if (span is TextSpan && span.style?.fontWeight == FontWeight.bold) {
          boldText += span.text ?? '';
        }
        return true;
      });
      expect(boldText.replaceAll('-', ''), 'medication');
    });

    test('never leaves a hyphen in the middle of a line', () {
      const sentence = 'Reviewed the pharmacokinetics notes for renal '
          'clearance during my break. Understanding glomerular filtration '
          'makes the dosage adjustments feel less intimidating.';
      var splits = 0;
      for (final width in [120.0, 160.0, 200.0, 260.0, 330.0]) {
        final result = layout(const TextSpan(text: sentence), width);
        final lines = _lines(result, width);
        for (final line in lines) {
          final inner = line.trimRight();
          final hyphen = inner.indexOf('-');
          expect(hyphen == -1 || hyphen == inner.length - 1, isTrue,
              reason: 'width $width: "$line"');
        }
        expect(result.toPlainText().replaceAll('-', ''), sentence);
        splits += lines.where((line) => line.trimRight().endsWith('-')).length;
      }
      // Long words really do get split across lines.
      expect(splits, greaterThan(0));
    });
  });
}
