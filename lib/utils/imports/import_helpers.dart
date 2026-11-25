// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/database/entry_tag_dao.dart';
import 'package:daily_you/database/tag_category_dao.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/utils/operation_outcome.dart';

class ImportedEntry {
  const ImportedEntry(
    this.entry, {
    this.attachments = const [],
    this.files = const [],
    this.tags = const [],
    this.sourceId,
  });

  final Entry entry;

  /// Attachments already in storage, by file name (old Daily You JSON).
  final List<EntryAttachment> attachments;

  /// Attachment files to copy in (Day One, new JSON with attachments).
  final List<ImportedFile> files;

  final List<ImportedEntryTag> tags;

  /// The entry's id in the app it came from, so links between entries can
  /// be pointed at the new entries (Update D).
  final String? sourceId;
}

/// An attachment file waiting to be copied into the journal.
class ImportedFile {
  const ImportedFile(
      {required this.type,
      required this.rank,
      required this.timeCreate,
      required this.path});

  final AttachmentType type;
  final int rank;
  final DateTime timeCreate;
  final String path;
}

/// A tag to put on an imported entry; made if there's none by that name.
class ImportedEntryTag {
  const ImportedEntryTag(
      {required this.name,
      this.tagType = TagType.label,
      this.value,
      this.categoryName,
      this.icon,
      this.iconType = TagIconType.character,
      this.color,
      this.favourite = false});

  /// The ⭐ Favourite tag (starred in Day One, favourite in JSON).
  const ImportedEntryTag.favourite()
      : name = Favourites.tagName,
        tagType = TagType.label,
        value = null,
        categoryName = null,
        icon = Favourites.tagIcon,
        iconType = TagIconType.character,
        color = null,
        favourite = true;

  final String name;
  final TagType tagType;
  final String? value;
  final String? categoryName;

  /// How a new tag looks, when the source says (Daily You JSON).
  final String? icon;
  final TagIconType iconType;
  final int? color;
  final bool favourite;
}

/// Update D: an entry dated after today is skipped on import, since it's
/// almost always a wrong date or time zone in the source. Daily You's own
/// JSON can carry upcoming entries, so it lets them in.
class ImportGuard {
  ImportGuard._();

  /// Entries skipped by the last import.
  static int skippedFuture = 0;

  static void reset() => skippedFuture = 0;

  /// True (and counted) when [time] is after today.
  static bool skip(DateTime time, {bool allowFuture = false}) {
    if (allowFuture) return false;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    if (!time.isBefore(endOfToday)) {
      skippedFuture++;
      return true;
    }
    return false;
  }
}

/// Finds or makes tags (and their categories) by name during one import.
class ImportTagMaker {
  final Map<String, Tag> _tags = {};
  final Map<String, TagCategory> _categories = {};
  int _nextSortOrder = 0;
  bool _loaded = false;

  static String _key(TagType type, String name) =>
      '${type.name}:${name.toLowerCase()}';

  void _load() {
    if (_loaded) return;
    _loaded = true;
    for (final tag in TagsProvider.instance.tags) {
      _tags.putIfAbsent(_key(tag.tagType, tag.name), () => tag);
      if (tag.sortOrder >= _nextSortOrder) _nextSortOrder = tag.sortOrder + 1;
    }
    for (final category in TagsProvider.instance.categories) {
      _categories.putIfAbsent(category.name.toLowerCase(), () => category);
    }
  }

  Future<Tag?> tagFor(ImportedEntryTag wanted) async {
    _load();
    if (wanted.favourite) {
      final existing = Favourites.tag ??
          TagsProvider.instance.tags
              .where(Favourites.isFavouriteTag)
              .firstOrNull;
      if (existing != null) return existing;
    }
    final name = sanitizeTagName(wanted.name);
    if (name.isEmpty) return null;
    final key = _key(wanted.tagType, name);
    final known = _tags[key];
    if (known != null) return known;
    final now = DateTime.now();
    final tag = await TagDao.add(Tag(
      name: name,
      tagType: wanted.tagType,
      icon: wanted.favourite ? Favourites.tagIcon : wanted.icon,
      iconType: wanted.favourite ? TagIconType.character : wanted.iconType,
      color: wanted.color,
      categoryId: (await _categoryFor(wanted.categoryName))?.id,
      sortOrder: _nextSortOrder++,
      timeCreate: now,
      timeModified: now,
    ));
    _tags[key] = tag;
    return tag;
  }

  Future<TagCategory?> _categoryFor(String? name,
      {String? icon,
      TagIconType iconType = TagIconType.character,
      int? color}) async {
    final clean = name?.trim() ?? '';
    if (clean.isEmpty) return null;
    _load();
    final known = _categories[clean.toLowerCase()];
    if (known != null) return known;
    final now = DateTime.now();
    final category = await TagCategoryDao.add(TagCategory(
        name: clean,
        icon: icon,
        iconType: iconType,
        color: color,
        sortOrder: _categories.length,
        timeCreate: now,
        timeModified: now));
    _categories[clean.toLowerCase()] = category;
    return category;
  }

  /// Makes a category the source lists, with its look, if there's none by
  /// that name.
  Future<void> defineCategory(String name,
          {String? icon,
          TagIconType iconType = TagIconType.character,
          int? color}) =>
      _categoryFor(name, icon: icon, iconType: iconType, color: color);

  /// Makes the categories and tags a source lists, even unused ones.
  Future<void> define(Iterable<ImportedEntryTag> tags) async {
    for (final tag in tags) {
      await tagFor(tag);
    }
  }
}

/// Points links between entries at the new entries once they're all in:
/// [rewrite] gets an entry's text and the new id for each source id.
typedef ImportLinkRewriter = String Function(
    String text, int? Function(String sourceId) newIdOf);

/// `[text](entry:12)` links from Daily You's own JSON.
String rewriteEntryLinks(String text, int? Function(String sourceId) newIdOf) =>
    text.replaceAllMapped(RegExp(r'\]\(entry:(\d+)\)'), (match) {
      final id = newIdOf(match[1]!);
      return id == null ? match[0]! : '](entry:$id)';
    });

Future<void> addImportedEntries(
    List<ImportedEntry> importedEntries, Function(String) updateStatus,
    {bool allowFuture = false,
    ImportLinkRewriter? rewriteLinks,
    ImportTagMaker? tagMaker}) async {
  final totalEntries = importedEntries.length;
  var processedEntries = 0;
  tagMaker ??= ImportTagMaker();
  final newIdBySource = <String, int>{};
  final added = <Entry>[];
  final takenNames = <String>{};

  for (final imported in importedEntries) {
    final time = imported.entry.timeCreate;
    if (!ImportGuard.skip(time, allowFuture: allowFuture) &&
        !EntriesProvider.instance.hasEntryAtTimestamp(time)) {
      final addedEntry =
          await EntriesProvider.instance.add(imported.entry, skipUpdate: true);
      added.add(addedEntry);
      if (imported.sourceId != null) {
        newIdBySource[imported.sourceId!] = addedEntry.id!;
      }
      for (final attachment in imported.attachments) {
        await EntryAttachmentsProvider.instance
            .add(attachment.copy(entryId: addedEntry.id), skipUpdate: true);
      }
      for (final file in imported.files) {
        final source = File(file.path);
        if (!await source.exists()) continue;
        final filePath = await AttachmentStorage.instance.create(
            null, await source.readAsBytes(), file.type,
            currTime: file.timeCreate,
            skipExternalUpload: true,
            takenNames: takenNames);
        if (filePath == null) continue;
        await EntryAttachmentsProvider.instance.add(
            EntryAttachment(
                entryId: addedEntry.id,
                type: file.type,
                filePath: filePath,
                rank: file.rank,
                timeCreate: file.timeCreate),
            skipUpdate: true);
      }
      final tagIds = <int>{};
      for (final wanted in imported.tags) {
        final tag = await tagMaker.tagFor(wanted);
        if (tag == null || !tagIds.add(tag.id!)) continue;
        final value = tag.tagType == TagType.tracker ? wanted.value : null;
        if (tag.tagType == TagType.tracker &&
            !(double.tryParse(value ?? '')?.isFinite ?? false)) {
          continue;
        }
        await EntryTagDao.add(EntryTag(
            entryId: addedEntry.id!,
            tagId: tag.id!,
            value: value,
            timeCreate: time));
      }
    }
    processedEntries += 1;
    updateStatus("${((processedEntries / totalEntries) * 100).round()}%");
  }

  if (rewriteLinks != null && newIdBySource.isNotEmpty) {
    for (final entry in added) {
      final text = rewriteLinks(entry.text, (id) => newIdBySource[id]);
      if (text != entry.text) await EntryDao.update(entry.copy(text: text));
    }
  }
}

Future<void> addImportedImage(int entryId, Uint8List bytes, int rank,
    DateTime timeCreate, Set<String> takenNames) async {
  final filePath = await AttachmentStorage.instance.create(
      null, bytes, AttachmentType.image,
      currTime: timeCreate, skipExternalUpload: true, takenNames: takenNames);
  if (filePath == null) return;
  await EntryAttachmentsProvider.instance.add(
      EntryAttachment(
        entryId: entryId,
        type: AttachmentType.image,
        filePath: filePath,
        rank: rank,
        timeCreate: timeCreate,
      ),
      skipUpdate: true);
}

Future<OperationOutcome> finishImport(
    Function(String) updateStatus, OperationOutcome outcome) async {
  await EntriesProvider.instance.load();
  await EntryAttachmentsProvider.instance.load();
  await TagsProvider.instance.load();
  if (AttachmentStorage.instance.usingExternalLocation()) {
    try {
      await AttachmentStorage.instance.syncAttachmentFolders(true,
          onProgress: (progress) => updateStatus(progress.counts ?? ''));
    } catch (error) {
      return outcome.failed ? outcome : OperationOutcome.failed(error);
    }
  }
  return outcome;
}

DateTime diariumIdToDateTime(int ticks) {
  const int ticksAtUnixEpoch = 621355968000000000;
  final usSinceEpoch = ((ticks - ticksAtUnixEpoch) / 10).round();
  // Wall-clock time the entry was written, with no zone attached
  final wallClock =
      DateTime.fromMicrosecondsSinceEpoch(usSinceEpoch, isUtc: true);
  return DateTime(
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
      wallClock.millisecond,
      wallClock.microsecond);
}

DateTime convertWithOffset(int millisUtc, String tzOffset) {
  final utc = DateTime.fromMillisecondsSinceEpoch(millisUtc, isUtc: true);
  final sign = tzOffset.startsWith('-') ? -1 : 1;
  final parts = tzOffset.substring(1).split(':');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  final offsetDuration = Duration(
    hours: hours * sign,
    minutes: minutes * sign,
  );
  return utc.add(offsetDuration);
}

DateTime parseDaybookLocal(String s) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})-(\d{2}):(\d{2})$',
  ).firstMatch(s);

  if (match == null) {
    throw FormatException("Invalid Daybook date: $s");
  }

  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
  );
}
