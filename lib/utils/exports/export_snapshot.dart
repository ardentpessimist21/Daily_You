// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

// Update D: every export works from one frozen copy of the journal, taken
// before anything is written, so nothing shifts mid-export (as upstream).

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/moods.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

class ExportSnapshot {
  const ExportSnapshot({
    required this.locale,
    required this.exportedAt,
    this.moodNames = const {},
    this.moodColors = const {},
    this.categories = const [],
    this.tags = const [],
    this.savedPlaces = const [],
    this.entries = const [],
  });

  final String locale;
  final DateTime exportedAt;

  /// Your names and colours for each mood, -2 to 2.
  final Map<int, String> moodNames;
  final Map<int, int> moodColors;
  final List<TagCategory> categories;

  /// Every tag except ⭐ Favourite, which exports as `favourite`.
  final List<Tag> tags;
  final List<Place> savedPlaces;
  final List<ExportEntry> entries;

  String moodNameOf(int mood) => moodNames[mood] ?? Moods.defaultNames[mood]!;

  String? categoryNameOf(int? id) =>
      categories.where((category) => category.id == id).firstOrNull?.name;
}

class ExportEntryTag {
  const ExportEntryTag(
      {required this.name,
      required this.tagType,
      this.categoryName,
      this.value});

  final String name;
  final TagType tagType;
  final String? categoryName;
  final num? value;
}

class ExportAttachment {
  const ExportAttachment(
      {required this.type,
      required this.rank,
      required this.timeCreate,
      required this.sourcePath});

  final AttachmentType type;
  final int rank;
  final DateTime timeCreate;
  final String sourcePath;
}

class ExportEntry {
  const ExportEntry(
    this.entry, {
    this.tags = const [],
    this.favourite = false,
    this.attachments = const [],
  });

  final Entry entry;
  final List<ExportEntryTag> tags;
  final bool favourite;

  /// Shown first, first.
  final List<ExportAttachment> attachments;

  /// What you wrote, without the 📍 line.
  String get body => EntryLocations.bodyOf(entry.text);

  List<Place> get places => EntryLocations.placesOf(entry.text);
}

Future<ExportSnapshot> buildExportSnapshot({
  required String locale,
  required Set<AttachmentType> includedTypes,
  List<Entry>? entries,
  void Function(double fraction)? onProgress,
}) async {
  final tagsProvider = TagsProvider.instance;
  final favouriteId = Favourites.tag?.id;
  final categoryNameById = {
    for (final category in tagsProvider.categories) category.id: category.name
  };
  final tagById = {for (final tag in tagsProvider.tags) tag.id: tag};
  final tagPosition = {
    for (final (position, tag) in tagsProvider.tags.indexed) tag.id: position
  };

  final attachmentsByEntry = <int, List<EntryAttachment>>{};
  for (final attachment in EntryAttachmentsProvider.instance.attachments) {
    final entryId = attachment.entryId;
    if (entryId == null || !includedTypes.contains(attachment.type)) continue;
    (attachmentsByEntry[entryId] ??= []).add(attachment);
  }

  final sorted = [...entries ?? EntriesProvider.instance.entries]..sort((a, b) {
      final byTime = a.timeCreate.compareTo(b.timeCreate);
      return byTime != 0 ? byTime : (a.id ?? 0).compareTo(b.id ?? 0);
    });

  final exported = <ExportEntry>[];
  for (final entry in sorted) {
    final entryTags = [...tagsProvider.getEntryTagsForEntry(entry.id!)]..sort(
        (a, b) =>
            (tagPosition[a.tagId] ?? 0).compareTo(tagPosition[b.tagId] ?? 0));
    final attachments = [...?attachmentsByEntry[entry.id!]]
      ..sort((a, b) => b.rank.compareTo(a.rank));
    exported.add(ExportEntry(
      entry,
      favourite: entryTags.any((entryTag) => entryTag.tagId == favouriteId),
      tags: [
        for (final entryTag in entryTags)
          if (entryTag.tagId != favouriteId)
            if (tagById[entryTag.tagId] case final tag?)
              ExportEntryTag(
                name: tag.name,
                tagType: tag.tagType,
                categoryName: categoryNameById[tag.categoryId],
                value: _finite(entryTag.value),
              )
      ],
      attachments: [
        for (final attachment in attachments)
          if (await AttachmentStorage.instance
                  .getLocalPath(attachment.filePath, attachment.type)
              case final sourcePath?)
            ExportAttachment(
              type: attachment.type,
              rank: attachment.rank,
              timeCreate: attachment.timeCreate,
              sourcePath: sourcePath,
            )
      ],
    ));
    onProgress?.call(exported.length / sorted.length);
  }

  return ExportSnapshot(
    locale: locale,
    exportedAt: DateTime.now(),
    moodNames: {for (final mood in Moods.values) mood: Moods.nameOf(mood)},
    moodColors: {
      for (final mood in Moods.values) mood: Moods.colorOf(mood).toARGB32()
    },
    categories: tagsProvider.categories,
    tags: [
      for (final tag in tagsProvider.tags)
        if (tag.id != favouriteId) tag
    ],
    savedPlaces: Places.savedPlaces(),
    entries: exported,
  );
}

num? _finite(String? text) {
  final number = num.tryParse(text ?? '');
  return number != null && number.isFinite ? number : null;
}

// ---- Names -----------------------------------------------------------------

class NamedExportAttachment {
  const NamedExportAttachment(this.attachment, this.fileName, this.path);

  final ExportAttachment attachment;
  final String fileName;

  /// Inside the export: `<type folder>/<fileName>`.
  final String path;
}

class NamedExportEntry {
  const NamedExportEntry(this.exported, this.fileStem, this.attachments);

  final ExportEntry exported;

  /// `2026-03-04`, then `2026-03-04_2` for the day's second entry.
  final String fileStem;
  final List<NamedExportAttachment> attachments;
}

List<NamedExportEntry> nameExportEntries(ExportSnapshot snapshot) {
  final dayFormat = DateFormat('yyyy-MM-dd', snapshot.locale);
  final countByDay = <String, int>{};
  return [
    for (final exported in snapshot.entries)
      () {
        final day = dayFormat.format(exported.entry.timeCreate);
        final number = countByDay[day] = (countByDay[day] ?? 0) + 1;
        final stem = number > 1 ? '${day}_$number' : day;
        return NamedExportEntry(exported, stem, [
          for (final attachment in exported.attachments)
            () {
              final fileName =
                  '${attachment.type.name}_${stem}_${attachment.rank}${extension(attachment.sourcePath)}';
              return NamedExportAttachment(attachment, fileName,
                  posix.join(attachment.type.folderName, fileName));
            }()
        ]);
      }()
  ];
}

/// Each attachment's path inside the export, and where to copy it from.
Map<String, String> attachmentSourcesOf(Iterable<NamedExportEntry> entries) => {
      for (final named in entries)
        for (final attachment in named.attachments)
          attachment.path: attachment.attachment.sourcePath
    };

/// `[text](entry:12)` links: each turned into what [target] returns for the
/// linked entry's id, or just its text when [target] returns null.
String replaceEntryLinks(String text, String? Function(int id) target) =>
    text.replaceAllMapped(RegExp(r'\[([^\]\n]*)\]\(entry:(\d+)\)'), (match) {
      final address = target(int.parse(match[2]!));
      return address == null ? match[1]! : '[${match[1]}]($address)';
    });
