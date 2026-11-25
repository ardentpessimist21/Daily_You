// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

// Day One import (Update D), ported from upstream Daily You: Day One's
// export (a .zip with Journal.json and media folders, or the .json alone).
// Dates are read in each entry's own time zone, Day One's Markdown is
// cleaned up, starred entries get ⭐, the location becomes a 📍 place and
// links between entries point at the new entries.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_dayone_text.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/utils/imports/import_time.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const _mediaKinds = [
  (name: 'photos', type: AttachmentType.image),
  (name: 'videos', type: AttachmentType.video),
  (name: 'audios', type: AttachmentType.audio),
];

Future<OperationOutcome> importFromDayOne(Function(String) updateStatus) async {
  updateStatus("0%");
  var outcome = const OperationOutcome.succeeded();
  Directory? work;
  try {
    final selectedFile = await StoragePicker.pickFile(
        allowedExtensions: ['zip', 'json'],
        mimeTypes: ['application/zip', 'application/json']);
    if (selectedFile == null) return const OperationOutcome.cancelled();

    work = await (await getTemporaryDirectory()).createTemp('dayone_import_');
    const copied = 'picked';
    if (!await selectedFile.copyInto(work.path, copied)) {
      return const OperationOutcome.failed();
    }
    final entries = await parseDayOne(File(join(work.path, copied)), work.path);
    await addImportedEntries(entries, updateStatus,
        rewriteLinks: rewriteDayOneLinks);
  } catch (error) {
    outcome = OperationOutcome.failed(error);
  } finally {
    if (work != null && await work.exists()) {
      await work.delete(recursive: true);
    }
  }
  return finishImport(updateStatus, outcome);
}

/// `dayone://view?entryId=…` links to another entry in the same import.
final _dayOneLink =
    RegExp(r'\]\(dayone2?://view\?(?:[^)]*&)?entryId=([0-9A-Fa-f]+)[^)]*\)');

String rewriteDayOneLinks(
        String text, int? Function(String sourceId) newIdOf) =>
    text.replaceAllMapped(_dayOneLink, (match) {
      final id = newIdOf(match[1]!.toUpperCase());
      return id == null ? match[0]! : '](entry:$id)';
    });

/// The entries in [file], a Day One .zip (unpacked into [workPath]) or one
/// of its .json journals.
Future<List<ImportedEntry>> parseDayOne(File file, String workPath) async {
  final handle = await file.open();
  final List<int> header;
  try {
    header = await handle.read(4);
  } finally {
    await handle.close();
  }
  final isZip = header.length == 4 &&
      header[0] == 0x50 &&
      header[1] == 0x4B &&
      header[2] == 0x03 &&
      header[3] == 0x04;

  final List<File> journalFiles;
  if (isZip) {
    final extracted = join(workPath, 'dayone');
    await ZipUtils.extract(file.path, extracted);
    journalFiles = Directory(extracted)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => extension(file.path).toLowerCase() == '.json')
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  } else {
    journalFiles = [file];
  }

  final journals = <(String, List<ImportedEntry>)>[];
  for (final journalFile in journalFiles) {
    final Object? root;
    try {
      root = json.decode(utf8.decode(await journalFile.readAsBytes()));
    } on FormatException {
      continue;
    }
    if (root is! Map || root['entries'] is! List) continue;
    final entries = <ImportedEntry>[];
    for (final entry in root['entries'] as List) {
      if (entry is! Map || entry['creationDate'] is! String) continue;
      entries.add(await _parseEntry(entry, dirname(journalFile.path)));
    }
    journals.add(
        (sanitizeTagName(basenameWithoutExtension(journalFile.path)), entries));
  }
  if (journals.isEmpty) throw const FormatException('Not a Day One export');

  // With several journals, each entry gets its journal's name as a tag
  final labelJournals = journals.length > 1;
  final entries = [
    for (final (journalName, journalEntries) in journals)
      for (final entry in journalEntries)
        labelJournals && journalName.isNotEmpty
            ? ImportedEntry(entry.entry,
                files: entry.files,
                sourceId: entry.sourceId,
                tags: [...entry.tags, ImportedEntryTag(name: journalName)])
            : entry,
  ];
  entries.sort((a, b) => a.entry.timeCreate.compareTo(b.entry.timeCreate));
  return entries;
}

Future<ImportedEntry> _parseEntry(Map entry, String mediaPath) async {
  final timeZoneName = entry['timeZone'] as String?;
  final timeCreate = wallClockIn(
      DateTime.parse(entry['creationDate'] as String), timeZoneName);
  final modifiedDate = entry['modifiedDate'] as String?;
  final timeModified = modifiedDate == null
      ? timeCreate
      : wallClockIn(DateTime.parse(modifiedDate), timeZoneName);

  final place = dayOnePlace(entry['location']);
  final text = dayOneText(entry['text'] as String? ?? '');
  final uuid = entry['uuid'] as String?;

  return ImportedEntry(
    Entry(
      text: place == null ? text : EntryLocations.join(text, [place]),
      timeCreate: timeCreate,
      timeModified: timeModified,
    ),
    sourceId: uuid?.toUpperCase(),
    tags: [
      for (final tag in entry['tags'] as List? ?? const [])
        if (tag is String && sanitizeTagName(tag).isNotEmpty)
          ImportedEntryTag(name: tag),
      if (entry['starred'] == true) const ImportedEntryTag.favourite(),
    ],
    files: await _parseMedia(entry, mediaPath, timeCreate),
  );
}

/// Day One's location as a 📍 place: its name, with the spot on the map
/// when it has coordinates.
Place? dayOnePlace(Object? location) {
  if (location is! Map) return null;
  final latitude = (location['latitude'] as num?)?.toDouble();
  final longitude = (location['longitude'] as num?)?.toDouble();
  final hasSpot = latitude != null &&
      longitude != null &&
      !(latitude == 0 && longitude == 0);
  final name = [
    location['placeName'],
    location['localityName'],
    location['administrativeArea'],
  ].whereType<String>().map((part) => part.trim()).firstWhere(
      (part) => part.isNotEmpty,
      orElse: () => hasSpot
          ? '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'
          : '');
  if (name.isEmpty) return null;
  if (!hasSpot) return Places.typedPlace(name);
  return Place(name,
      'geo:${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}');
}

Future<List<ImportedFile>> _parseMedia(
    Map entry, String mediaPath, DateTime timeCreate) async {
  final media =
      <({int order, int position, AttachmentType type, String path})>[];
  for (final kind in _mediaKinds) {
    for (final item in entry[kind.name] as List? ?? const []) {
      if (item is! Map) continue;
      final folder = join(mediaPath, kind.name);
      final path = normalize(join(folder, '${item['md5']}.${item['type']}'));
      if (!isWithin(folder, path)) {
        throw FormatException('Media path leaves the export', path);
      }
      if (!await File(path).exists()) continue;
      media.add((
        order: item['orderInEntry'] as int? ?? 0,
        position: media.length,
        type: kind.type,
        path: path,
      ));
    }
  }
  media.sort((a, b) {
    final byOrder = a.order.compareTo(b.order);
    return byOrder != 0 ? byOrder : a.position.compareTo(b.position);
  });
  // The first item shows first: the highest rank
  return [
    for (final (index, item) in media.indexed)
      ImportedFile(
          type: item.type,
          rank: media.length - 1 - index,
          timeCreate: timeCreate,
          path: item.path),
  ];
}
