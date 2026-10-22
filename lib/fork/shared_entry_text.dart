// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/places.dart';
import 'package:intl/intl.dart';

/// Text shared into Daily You, tidied: an entry shared from Daily You
/// itself ("😊 Thu, Oct 22, 2026\nText…\n\n📍 Place https://maps…") comes
/// back as its text and places, without the date line.
class SharedEntryText {
  static final RegExp _placeLine = RegExp(
      '^${RegExp.escape(Places.pin)}\\s*(.+?)(?:\\s+(https?://\\S+))?\\s*\$');

  /// Splits [shared] into its text and the 📍 places at its end. The first
  /// line is dropped when it's a date in [locale]'s format (with or without
  /// a mood emoji before it).
  static (String, List<Place>) parse(String shared, {String locale = 'en'}) {
    final lines = shared.trimRight().split('\n');

    // 📍 lines at the end become places
    final places = <Place>[];
    while (lines.isNotEmpty) {
      final last = lines.last.trim();
      if (last.isEmpty) {
        lines.removeLast();
        continue;
      }
      final match = _placeLine.firstMatch(last);
      if (match == null) break;
      places.insert(0, Place(match[1]!.trim(), match[2] ?? ''));
      lines.removeLast();
    }

    if (lines.length > 1 && isDateLine(lines.first, locale: locale)) {
      lines.removeAt(0);
    }
    return (lines.join('\n').trim(), places);
  }

  /// Whether [line] is a date as Daily You shares it, e.g. "Thu, Oct 22,
  /// 2026", optionally after a mood emoji.
  static bool isDateLine(String line, {String locale = 'en'}) {
    var text = line.trim();
    if (text.isEmpty || text.length > 60) return false;
    // A leading mood emoji: a first word with no letters or digits
    final space = text.indexOf(' ');
    if (space > 0 &&
        !RegExp(r'[\p{L}\p{N}]', unicode: true)
            .hasMatch(text.substring(0, space))) {
      text = text.substring(space + 1).trim();
    }
    for (final candidate in {locale, 'en'}) {
      try {
        DateFormat.yMMMEd(candidate).parseStrict(text);
        return true;
      } catch (_) {
        // not a date in this locale
      }
    }
    return false;
  }
}
