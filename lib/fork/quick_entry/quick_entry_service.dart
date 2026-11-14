// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where a quick entry goes (Update Q).
enum QuickEntryTarget {
  /// A new entry for today.
  newEntry('new'),

  /// The end of today's most recent entry, under a time stamp line.
  lastEntry('last');

  const QuickEntryTarget(this.key);
  final String key;

  static QuickEntryTarget fromKey(String? key) =>
      key == lastEntry.key ? lastEntry : newEntry;
}

/// What a quick save did, for the "Saved" / "Added" message.
class QuickEntryResult {
  const QuickEntryResult({
    required this.entry,
    required this.added,
    required this.wantedLast,
  });

  final Entry entry;

  /// True when the text went at the end of an existing entry.
  final bool added;

  /// True when "Last entry" was asked for but there was no entry today, so
  /// it was saved as a new entry instead.
  final bool wantedLast;

  bool get fellBackToNew => wantedLast && !added;
}

/// Saving quick entries, shared by the quick-entry sheet, the notification's
/// reply box and the main app (which saves any reply left waiting).
class QuickEntryService {
  static final Logger _logger = Logger('QuickEntry');

  /// SharedPreferences keys. The queue is also written by the Android side
  /// (as "flutter.quickEntryQueue"), so a reply is never lost if saving it
  /// takes too long.
  static const String targetKey = 'quickEntryTarget';
  static const String revisionKey = 'quickEntryRevision';
  static const String queueKey = 'quickEntryQueue';

  /// Today's most recent entry, if there is one.
  static Entry? lastEntryToday() {
    final today = EntriesProvider.instance.getEntriesForDate(DateTime.now());
    if (today.isEmpty) return null;
    return today.reduce((a, b) => b.timeCreate.isAfter(a.timeCreate) ? b : a);
  }

  /// "6:10 PM" for [entry], in the phone's language.
  static String timeLabel(DateTime time, [String? locale]) =>
      DateFormat.jm(locale).format(time);

  /// Saves [text] as a new entry for today, or adds it to the end of today's
  /// most recent entry under a "— 7:24 PM" line. Without an entry today,
  /// "Last entry" saves a new entry.
  ///
  /// [mood] is the mood to save. With [keepMood] (a notification reply,
  /// which has no mood row) a new entry gets no mood and an added-to entry
  /// keeps its own.
  static Future<QuickEntryResult> save({
    required String text,
    required QuickEntryTarget target,
    int? mood,
    bool keepMood = false,
    List<EntryTag> tags = const [],
    List<Place> places = const [],
    DateTime? at,
    String? timeText,
  }) async {
    final now = at ?? DateTime.now();
    final writing = text.trim();
    final last = target == QuickEntryTarget.lastEntry ? lastEntryToday() : null;

    late final EntryDraft draft;
    if (last == null) {
      draft = EntryDraft(
        entry: Entry(
          text: EntryLocations.join(writing, places),
          mood: keepMood ? null : mood,
          timeCreate: now,
          timeModified: now,
        ),
        tags: tags,
      );
    } else {
      final (body, oldPlaces) = EntryLocations.split(last.text);
      final stamp = '— ${timeText ?? timeLabel(now)}';
      final above = body.trimRight();
      final added = '$stamp\n$writing';
      final newBody = above.isEmpty ? added : '$above\n\n$added';

      final knownPlaces =
          oldPlaces.map((place) => place.name.trim().toLowerCase()).toSet();
      final allPlaces = [
        ...oldPlaces,
        ...places
            .where((place) => knownPlaces.add(place.name.trim().toLowerCase())),
      ];

      final oldTags = TagsProvider.instance.getEntryTagsForEntry(last.id!);
      final knownTags = oldTags.map((entryTag) => entryTag.tagId).toSet();

      draft = EntryDraft(
        entry: last.copy(
          text: EntryLocations.join(newBody, allPlaces),
          mood: keepMood ? last.mood : mood,
          timeModified: now,
        ),
        tags: [
          ...oldTags,
          for (final entryTag in tags)
            if (knownTags.add(entryTag.tagId)) entryTag.copy(entryId: last.id!),
        ],
        // The draft replaces the entry's attachments, so keep them all.
        attachments: [
          for (final attachment
              in EntryAttachmentsProvider.instance.getForEntry(last))
            attachment.copy()
        ],
      );
    }

    final saved = await EntryStore.instance.beginDraft().save((_) => draft);
    await markChanged();
    return QuickEntryResult(
      entry: saved,
      added: last != null,
      wantedLast: target == QuickEntryTarget.lastEntry,
    );
  }

  /// Short message for the toast, the notification and the snack bar.
  static String messageFor(QuickEntryResult result, [String? locale]) {
    if (result.added) {
      return 'Added to the ${timeLabel(result.entry.timeCreate, locale)} entry';
    }
    if (result.fellBackToNew) return 'No entry today yet, saved as a new entry';
    return 'Saved as a new entry';
  }

  /// Tells the main app (another engine) to reload its entries, and writes
  /// the external copy now rather than after the usual one-second wait.
  static Future<void> markChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(revisionKey, DateTime.now().microsecondsSinceEpoch);
    } catch (error, stackTrace) {
      _logger.warning('Could not mark the change', error, stackTrace);
    }
  }

  static Future<void> flushExternalCopy() async {
    try {
      await AppDatabase.instance.writeExternalDatabaseNow();
    } catch (error, stackTrace) {
      _logger.warning('External copy not written', error, stackTrace);
    }
  }

  /// The remembered "Save to" choice.
  static Future<QuickEntryTarget> rememberedTarget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return QuickEntryTarget.fromKey(prefs.getString(targetKey));
  }

  static Future<void> rememberTarget(QuickEntryTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(targetKey, target.key);
  }

  /// Saves every notification reply still waiting. Returns the last result,
  /// or null when there was nothing to save.
  static Future<QuickEntryResult?> saveWaitingReplies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final waiting = _decodeQueue(prefs.getString(queueKey));
    if (waiting.isEmpty) return null;

    QuickEntryResult? lastResult;
    final done = <String>{};
    for (final reply in waiting) {
      try {
        if (reply.text.trim().isNotEmpty) {
          lastResult = await save(
            text: reply.text,
            target: reply.target,
            keepMood: true,
            at: reply.at,
          );
        }
        done.add(reply.id);
      } catch (error, stackTrace) {
        _logger.severe('Saving a notification reply failed', error, stackTrace);
        break;
      }
    }

    // Drop only what was saved: a reply may have come in meanwhile.
    await prefs.reload();
    final left = _decodeQueue(prefs.getString(queueKey))
        .where((reply) => !done.contains(reply.id))
        .toList();
    if (left.isEmpty) {
      await prefs.remove(queueKey);
    } else {
      await prefs.setString(
          queueKey, jsonEncode([for (final reply in left) reply.toJson()]));
    }
    return lastResult;
  }

  static List<_WaitingReply> _decodeQueue(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(_WaitingReply.fromJson)
          .whereType<_WaitingReply>()
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class _WaitingReply {
  const _WaitingReply(this.id, this.text, this.target, this.at);

  final String id;
  final String text;
  final QuickEntryTarget target;
  final DateTime at;

  static _WaitingReply? fromJson(Map json) {
    final text = json['text'];
    if (text is! String) return null;
    final at = json['at'];
    return _WaitingReply(
      '${json['id'] ?? at ?? text.hashCode}',
      text,
      QuickEntryTarget.fromKey(json['target'] as String?),
      at is int ? DateTime.fromMillisecondsSinceEpoch(at) : DateTime.now(),
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'text': text,
        'target': target.key,
        'at': at.millisecondsSinceEpoch,
      };
}
