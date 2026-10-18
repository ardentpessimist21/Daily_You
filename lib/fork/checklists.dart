// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';

/// Ticking checklist items ("- [ ] task") while reading an entry.
class Checklists {
  // A list item followed by a checkbox: "- [ ]", "* [x]", "1. [ ]"...
  static final RegExp _box =
      RegExp(r'^(\s*(?:[-*+]|\d+[.)])\s+)\[([ xX])\]', multiLine: true);

  static int count(String text) => _box.allMatches(text).length;

  /// Flips the [index]th checkbox in [text] (0 = first).
  static String toggle(String text, int index) {
    final matches = _box.allMatches(text).toList();
    if (index < 0 || index >= matches.length) return text;
    final match = matches[index];
    final ticked = match.group(2) != ' ';
    final boxStart = match.start + match.group(1)!.length;
    return text.replaceRange(boxStart, boxStart + 3, ticked ? '[ ]' : '[x]');
  }

  /// Ticks or unticks a checkbox in a saved entry. "Last modified" is left
  /// alone, since ticking a box isn't really editing the entry.
  static Future<void> toggleInEntry(Entry entry, int index) async {
    final id = entry.id;
    if (id == null) return;
    final text = toggle(entry.text, index);
    if (text == entry.text) return;
    await EntryStore.instance.beginDraft().save((_) => EntryDraft(
          entry: entry.copy(text: text),
          tags: TagsProvider.instance.getEntryTagsForEntry(id),
          attachments: EntryAttachmentsProvider.instance.getForEntry(entry),
        ));
  }
}
