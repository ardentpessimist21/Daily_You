// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

// Update D: the export formats. Each writes its documents into a store and
// returns the attachments to put beside them (path in the export → file).

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:daily_you/utils/imports/import_json.dart'
    show forkJsonFormatMarker, forkJsonFormatVersion;
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:intl/intl.dart';

typedef ExportWriter = Future<Map<String, String>> Function(
    ExportSnapshot snapshot, FileStore store);

// ---- Markdown ----------------------------------------------------------------

/// One note per entry, `log_2026-03-04.md`. Each starts with a header block
/// (date, mood, ⭐, tags, tracker values, places), then the date and time,
/// what you wrote, its places and its attachments. Links to other entries
/// point at their notes.
Future<Map<String, String>> writeMarkdown(
    ExportSnapshot snapshot, FileStore store) async {
  final named = nameExportEntries(snapshot);
  final noteById = {
    for (final entry in named)
      entry.exported.entry.id: 'log_${entry.fileStem}.md'
  };
  for (final entry in named) {
    await store.write(noteById[entry.exported.entry.id]!,
        utf8.encode(markdownNote(snapshot, entry, noteById)));
  }
  return attachmentSourcesOf(named);
}

String markdownNote(ExportSnapshot snapshot, NamedExportEntry named,
    Map<int?, String> noteById) {
  final exported = named.exported;
  final entry = exported.entry;
  final mood = entry.mood;
  final labels = [
    for (final tag in exported.tags)
      if (tag.tagType == TagType.label) tag.name
  ];
  final trackers = {
    for (final tag in exported.tags)
      if (tag.tagType == TagType.tracker && tag.value != null)
        tag.name: tag.value
  };
  final places = exported.places;
  final fields = <String, Object?>{
    'date': entry.timeCreate.toIso8601String(),
    if (mood != null) 'mood': mood,
    if (mood != null) 'moodLabel': snapshot.moodNameOf(mood),
    if (exported.favourite) 'favourite': true,
    if (labels.isNotEmpty) 'tags': labels,
    if (trackers.isNotEmpty) 'trackers': trackers,
    if (places.isNotEmpty) 'places': [for (final place in places) place.name],
  };

  final note = StringBuffer()
    ..writeln('---')
    ..writeAll([
      for (final MapEntry(:key, :value) in fields.entries)
        '$key: ${jsonEncode(value)}\n'
    ])
    ..writeln('---')
    ..writeln();

  final moodText = mood != null ? '${MoodIcon.getMoodIcon(mood)} ' : '';
  final star = exported.favourite ? ' ⭐' : '';
  final when = '${DateFormat.yMMMEd(snapshot.locale).format(entry.timeCreate)}'
      ' · ${DateFormat.jm(snapshot.locale).format(entry.timeCreate)}';
  note.writeln('$moodText$when$star');
  final body =
      replaceEntryLinks(exported.body, (id) => noteById[id]).trimRight();
  if (body.isNotEmpty) note.writeln(body);
  if (labels.isNotEmpty) {
    note
      ..writeln()
      ..writeln(
          labels.map((name) => '#${name.replaceAll(' ', '_')}').join(' '));
  }
  if (places.isNotEmpty) {
    note
      ..writeln()
      ..writeln(EntryLocations.join('', places));
  }
  if (named.attachments.isNotEmpty) note.writeln();
  for (final attachment in named.attachments) {
    note.writeln(attachment.attachment.type == AttachmentType.image
        ? '![](${attachment.path})'
        : '[${attachment.fileName}](${attachment.path})');
  }
  return note.toString();
}

// ---- CSV -------------------------------------------------------------------

const csvDocumentName = 'daily_you_export.csv';

/// One row per entry, with a column for each tracker.
Future<Map<String, String>> writeCsv(
    ExportSnapshot snapshot, FileStore store) async {
  final named = nameExportEntries(snapshot);
  final trackerNames = [
    for (final tag in snapshot.tags)
      if (tag.tagType == TagType.tracker) tag.name
  ];
  final rows = <List<Object?>>[
    [
      'date',
      'modified',
      'mood',
      'moodLabel',
      'favourite',
      'text',
      'tags',
      'places',
      'attachments',
      for (final name in trackerNames) 'tracker:$name',
    ],
    for (final entry in named)
      () {
        final exported = entry.exported;
        final mood = exported.entry.mood;
        final values = {
          for (final tag in exported.tags)
            if (tag.tagType == TagType.tracker) tag.name: tag.value
        };
        return <Object?>[
          exported.entry.timeCreate.toIso8601String(),
          exported.entry.timeModified.toIso8601String(),
          mood,
          mood == null ? null : snapshot.moodNameOf(mood),
          exported.favourite,
          exported.body,
          [
            for (final tag in exported.tags)
              if (tag.tagType == TagType.label) tag.name
          ].join(', '),
          exported.places.map((place) => place.name).join(', '),
          entry.attachments.map((attachment) => attachment.path).join(', '),
          for (final name in trackerNames) values[name],
        ];
      }()
  ];
  await store.write(csvDocumentName,
      utf8.encode(const CsvEncoder(addBom: true).convert(rows)));
  return attachmentSourcesOf(named);
}

// ---- JSON ------------------------------------------------------------------

const jsonDocumentName = 'daily_you_export.json';

/// A full copy that imports back in: your mood names and colours,
/// categories, tags, saved places and every entry (its text keeps its 📍
/// line), with attachments beside it in a zip.
Future<Map<String, String>> writeJson(
    ExportSnapshot snapshot, FileStore store) async {
  final named = nameExportEntries(snapshot);
  final document = {
    'format': forkJsonFormatMarker,
    'version': forkJsonFormatVersion,
    'exportedAt': snapshot.exportedAt.toIso8601String(),
    'moodScale': [
      for (final mood in snapshot.moodNames.keys)
        {
          'mood': mood,
          'label': snapshot.moodNameOf(mood),
          'icon': MoodIcon.getMoodIcon(mood),
          'color': snapshot.moodColors[mood],
        }
    ],
    'categories': [
      for (final category in snapshot.categories)
        {
          'name': category.name,
          'icon': category.icon,
          'iconType': category.iconType.name,
          'color': category.color,
          'sortOrder': category.sortOrder,
        }
    ],
    'tags': [
      for (final tag in snapshot.tags)
        {
          'name': tag.name,
          'type': tag.tagType.name,
          'category': snapshot.categoryNameOf(tag.categoryId),
          'icon': tag.icon,
          'iconType': tag.iconType.name,
          'color': tag.color,
          'sortOrder': tag.sortOrder,
        }
    ],
    'savedPlaces': [for (final place in snapshot.savedPlaces) place.toJson()],
    'entries': [
      for (final entry in named)
        {
          'id': entry.exported.entry.id,
          'text': entry.exported.entry.text,
          'mood': entry.exported.entry.mood,
          'timeCreate': entry.exported.entry.timeCreate.toIso8601String(),
          'timeModified': entry.exported.entry.timeModified.toIso8601String(),
          'favourite': entry.exported.favourite,
          'places': [for (final place in entry.exported.places) place.toJson()],
          'tags': [
            for (final tag in entry.exported.tags)
              {
                'name': tag.name,
                'type': tag.tagType.name,
                if (tag.categoryName != null) 'category': tag.categoryName,
                'value': tag.value,
              }
          ],
          'attachments': [
            for (final attachment in entry.attachments)
              {
                'type': attachment.attachment.type.name,
                'path': attachment.path,
                'rank': attachment.attachment.rank,
                'timeCreate':
                    attachment.attachment.timeCreate.toIso8601String(),
              }
          ],
        }
    ],
  };
  await store.write(jsonDocumentName,
      utf8.encode(const JsonEncoder.withIndent('  ').convert(document)));
  return attachmentSourcesOf(named);
}

// ---- Day One -----------------------------------------------------------------

const dayOneDocumentName = 'Journal.json';

/// A Day One import: Journal.json with photos/, videos/ and audios/ named
/// by their MD5, as Day One's own export does. The first place becomes the
/// entry's location and any others stay in the text; ⭐ becomes starred;
/// links between entries become Day One links.
Future<Map<String, String>> writeDayOne(
    ExportSnapshot snapshot, FileStore store) async {
  final uuidById = {
    for (final exported in snapshot.entries)
      exported.entry.id: dayOneUuid(exported)
  };
  final sources = <String, String>{};
  final entries = <Map<String, Object?>>[];
  final utc = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

  for (final exported in snapshot.entries) {
    final entry = exported.entry;
    final places = exported.places;
    final first = places.firstOrNull;
    final media = <String, List<Map<String, Object?>>>{};
    final moments = <String>[];
    for (final (index, attachment) in exported.attachments.indexed) {
      final bytes = await File(attachment.sourcePath).readAsBytes();
      final md5Hex = md5.convert(bytes).toString();
      final type = _extensionOf(attachment.sourcePath);
      final identifier = md5Hex.toUpperCase();
      final folder = switch (attachment.type) {
        AttachmentType.image => 'photos',
        AttachmentType.video => 'videos',
        AttachmentType.audio => 'audios',
      };
      sources['$folder/$md5Hex.$type'] = attachment.sourcePath;
      (media[folder] ??= []).add({
        'identifier': identifier,
        'md5': md5Hex,
        'type': type,
        'orderInEntry': index,
      });
      if (attachment.type == AttachmentType.image) {
        moments.add('![](dayone-moment://$identifier)');
      }
    }

    final body = replaceEntryLinks(
        exported.body,
        (id) => uuidById[id] == null
            ? null
            : 'dayone://view?entryId=${uuidById[id]}');
    final rest = places.skip(1).toList();
    final text = [
      ...moments,
      if (body.trim().isNotEmpty) body.trimRight(),
      if (rest.isNotEmpty) EntryLocations.join('', rest),
    ].join('\n\n');

    entries.add({
      'uuid': uuidById[entry.id],
      'creationDate': utc.format(entry.timeCreate.toUtc()),
      'modifiedDate': utc.format(entry.timeModified.toUtc()),
      'starred': exported.favourite,
      'text': text,
      'tags': [
        for (final tag in exported.tags)
          if (tag.tagType == TagType.label) tag.name
      ],
      if (first != null) 'location': dayOneLocation(first),
      ...media,
    });
  }

  await store.write(
      dayOneDocumentName,
      utf8.encode(const JsonEncoder.withIndent('  ').convert({
        'metadata': {'version': '1.0'},
        'entries': entries,
      })));
  return sources;
}

/// A steady 32-character id for an entry, as Day One uses.
String dayOneUuid(ExportEntry exported) => md5
    .convert(utf8.encode(
        'daily-you-${exported.entry.id}-${exported.entry.timeCreate.toIso8601String()}'))
    .toString()
    .toUpperCase();

/// A place as a Day One location: its name, and the spot when the place has
/// coordinates (`geo:lat,lng`).
Map<String, Object?> dayOneLocation(Place place) {
  final match = RegExp(r'^geo:(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)')
      .firstMatch(place.address);
  final latitude = match == null ? null : double.parse(match[1]!);
  final longitude = match == null ? null : double.parse(match[2]!);
  final hasSpot = latitude != null &&
      longitude != null &&
      !(latitude == 0 && longitude == 0);
  return {
    'placeName': place.name,
    if (hasSpot) 'latitude': latitude,
    if (hasSpot) 'longitude': longitude,
  };
}

String _extensionOf(String path) {
  final dot = path.lastIndexOf('.');
  final slash = path.lastIndexOf(RegExp(r'[/\\]'));
  if (dot <= slash + 1) return 'bin';
  return path.substring(dot + 1).toLowerCase();
}
