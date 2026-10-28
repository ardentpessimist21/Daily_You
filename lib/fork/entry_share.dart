// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/attachment_mime.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Sharing entries out of Daily You, one from the entry view or several
/// from a selection: "😊 Thu, Oct 22, 2026" then the text, with places as
/// words and a Maps link, and the entries' photos and files attached.
class EntryShare {
  static final RegExp _entryLink = RegExp(r'\[([^\]\n]*)\]\(entry:\d+\)');

  /// One entry as shared text, given its date already written out.
  static String textFor(Entry entry, String date) {
    final mood =
        entry.mood != null ? "${MoodIcon.getMoodIcon(entry.mood)} " : '';
    // Links to other entries only work inside Daily You, so they're shared
    // as their words.
    final (body, places) = EntryLocations.split(entry.text);
    var text = body.replaceAllMapped(_entryLink, (match) => match[1]!);
    // Places are shared as words with a Maps link.
    if (places.isNotEmpty) {
      final line = EntryLocations.shareLine(places);
      text = text.isEmpty ? line : '$text\n\n$line';
    }
    return '$mood$date\n$text';
  }

  /// Several entries, oldest first, separated by a blank line.
  static String textForAll(
          List<Entry> entries, String Function(Entry) dateOf) =>
      (List<Entry>.from(entries)
            ..sort((a, b) => a.timeCreate.compareTo(b.timeCreate)))
          .map((entry) => textFor(entry, dateOf(entry)).trimRight())
          .join('\n\n');

  static Future<void> share(BuildContext context, List<Entry> entries) async {
    if (entries.isEmpty) return;
    final text = textForAll(
        entries,
        (entry) =>
            TimeManager.formatDateWithWeekday(entry.timeCreate, context));

    final files = <XFile>[];
    final fileNames = <String>[];
    final sorted = List<Entry>.from(entries)
      ..sort((a, b) => a.timeCreate.compareTo(b.timeCreate));
    for (final entry in sorted) {
      for (final attachment
          in EntryAttachmentsProvider.instance.getForEntry(entry)) {
        final localPath = await AttachmentStorage.instance
            .getLocalPath(attachment.filePath, attachment.type);
        if (localPath == null) continue;
        files.add(XFile(localPath,
            mimeType:
                attachmentMimeType(attachment.filePath, attachment.type)));
        fileNames.add(attachment.filePath);
      }
    }
    // share_plus rejects an empty file list, so text-only entries pass no
    // files at all.
    await SharePlus.instance.share(files.isEmpty
        ? ShareParams(text: text)
        : ShareParams(files: files, fileNameOverrides: fileNames, text: text));
  }
}
