// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

/// Opening the editor from the entry view starts where you were reading.
class ReadingPosition {
  /// Off for now: opening the keyboard while the editor fades in made it
  /// stutter. The code stays so it can be turned back on later.
  static const bool enabled = false;

  /// The start of the line [fraction] (0–1) of the way through [body].
  static int lineStart(String body, double fraction) {
    final rough =
        (body.length * fraction.clamp(0.0, 1.0)).round().clamp(0, body.length);
    if (rough == 0) return 0;
    final lineStart = body.lastIndexOf('\n', rough - 1);
    return lineStart == -1 ? 0 : lineStart + 1;
  }
}
