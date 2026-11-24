// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

/// Code blocks with no language name ("```" on its own line) make
/// markdown_widget print "get language error" every time the block is drawn.
/// Labelling them "plaintext" for display only looks the same and stops it.
/// The saved entry text is never changed.
class MarkdownFences {
  static String labelBare(String text) {
    if (!text.contains('```') && !text.contains('~~~')) return text;

    final lines = text.split('\n');
    String? fenceChar;
    var fenceLength = 0;
    var changed = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      final indent = line.length - trimmed.length;

      if (fenceChar != null) {
        // Inside a block: look for its closing fence.
        if (indent <= 3) {
          final run = _leadingRun(trimmed, fenceChar);
          if (run >= fenceLength && trimmed.substring(run).trim().isEmpty) {
            fenceChar = null;
          }
        }
        continue;
      }

      if (indent > 3) continue;
      final char = trimmed.startsWith('```')
          ? '`'
          : trimmed.startsWith('~~~')
              ? '~'
              : null;
      if (char == null) continue;

      fenceChar = char;
      fenceLength = _leadingRun(trimmed, char);
      // Nothing after the fence but spaces, a non-breaking space or the \r
      // of a Windows line ending (pasted text often has these)
      if (trimmed.substring(fenceLength).trim().isEmpty) {
        lines[i] = '${line.substring(0, indent + fenceLength)}plaintext'
            '${line.endsWith('\r') ? '\r' : ''}';
        changed = true;
      }
    }

    return changed ? lines.join('\n') : text;
  }

  static int _leadingRun(String s, String char) {
    var n = 0;
    while (n < s.length && s[n] == char) {
      n++;
    }
    return n;
  }
}
