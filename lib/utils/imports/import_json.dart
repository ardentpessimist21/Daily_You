// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// This fork's JSON export (Update D).
const forkJsonFormatMarker = 'daily-you-dev';
const forkJsonFormatVersion = 1;

/// Upstream Daily You's JSON export (3.9.0+), whose moods run 1 to 5.
const upstreamJsonFormatMarker = 'daily-you';
const upstreamJsonFormatVersion = 2;

/// Daily You JSON: the old list of entries, this fork's JSON export (a
/// .json, or a .zip with its attachments), or upstream's JSON export.
Future<OperationOutcome> importFromJson(Function(String) updateStatus) async {
  updateStatus("0%");

  var outcome = const OperationOutcome.succeeded();
  Directory? work;

  try {
    final selectedFile = await StoragePicker.pickFile(
        allowedExtensions: ['json', 'zip'],
        mimeTypes: ['application/json', 'application/zip']);
    if (selectedFile == null) return const OperationOutcome.cancelled();

    work = await (await getTemporaryDirectory()).createTemp('json_import_');
    const copied = 'picked';
    if (!await selectedFile.copyInto(work.path, copied)) {
      return const OperationOutcome.failed();
    }
    final picked = File(join(work.path, copied));
    final parsed = await parseJsonImport(picked, work.path);

    final tagMaker = ImportTagMaker();
    for (final category in parsed.categories) {
      await tagMaker.defineCategory(category.name,
          icon: category.icon,
          iconType: category.iconType,
          color: category.color);
    }
    await tagMaker.define(parsed.tags);
    if (parsed.savedPlaces.isNotEmpty) {
      await Places.addSavedPlaces(parsed.savedPlaces);
    }
    await addImportedEntries(parsed.entries, updateStatus,
        // Daily You's own JSON can hold upcoming entries
        allowFuture: true,
        rewriteLinks: rewriteEntryLinks,
        tagMaker: tagMaker);
  } catch (error) {
    outcome = OperationOutcome.failed(error);
  } finally {
    if (work != null && await work.exists()) {
      await work.delete(recursive: true);
    }
  }

  return finishImport(updateStatus, outcome);
}

class ParsedJsonImport {
  const ParsedJsonImport({
    this.entries = const [],
    this.categories = const [],
    this.tags = const [],
    this.savedPlaces = const [],
  });

  final List<ImportedEntry> entries;
  final List<({String name, String? icon, TagIconType iconType, int? color})>
      categories;
  final List<ImportedEntryTag> tags;
  final List<Place> savedPlaces;
}

/// Reads [file] (a .json, or a .zip holding one .json and its attachment
/// folders), unpacking a zip into [workPath].
Future<ParsedJsonImport> parseJsonImport(File file, String workPath) async {
  final header = await _header(file);
  String contentsPath = dirname(file.path);
  File document = file;
  if (_isZip(header)) {
    contentsPath = join(workPath, 'contents');
    await ZipUtils.extract(file.path, contentsPath);
    final documents = [
      for (final entity in Directory(contentsPath).listSync(recursive: true))
        if (entity is File && extension(entity.path).toLowerCase() == '.json')
          entity
    ];
    if (documents.length != 1) {
      throw const FormatException('Expected one JSON file in the zip');
    }
    document = documents.single;
    contentsPath = dirname(document.path);
  }
  return parseJsonDocument(await document.readAsBytes(), contentsPath);
}

/// [bytes] of a Daily You JSON document; attachment paths are read from
/// [contentsPath].
ParsedJsonImport parseJsonDocument(Uint8List bytes, String contentsPath) {
  final root = json.decode(utf8.decode(bytes));
  if (root is List) {
    return ParsedJsonImport(entries: _legacyEntries(root));
  }
  if (root is Map && root['format'] == forkJsonFormatMarker) {
    return _parseCurrent(root, contentsPath, moodOffset: 0);
  }
  if (root is Map &&
      root['format'] == upstreamJsonFormatMarker &&
      root['version'] == upstreamJsonFormatVersion) {
    // Upstream stores moods as 1 to 5; here they're -2 to 2
    return _parseCurrent(root, contentsPath, moodOffset: -3);
  }
  throw const FormatException('Not a Daily You JSON file');
}

ParsedJsonImport _parseCurrent(Map root, String contentsPath,
    {required int moodOffset}) {
  TagIconType iconType(Object? name) =>
      TagIconType.values.where((type) => type.name == name).firstOrNull ??
      TagIconType.character;
  TagType tagType(Object? name) =>
      TagType.values.where((type) => type.name == name).firstOrNull ??
      TagType.label;

  return ParsedJsonImport(
    categories: [
      for (final category in root['categories'] as List? ?? const [])
        if (category is Map && category['name'] is String)
          (
            name: category['name'] as String,
            icon: category['icon'] as String?,
            iconType: iconType(category['iconType']),
            color: category['color'] as int?,
          )
    ],
    tags: [
      for (final tag in root['tags'] as List? ?? const [])
        if (tag is Map && tag['name'] is String)
          ImportedEntryTag(
            name: tag['name'] as String,
            tagType: tagType(tag['type']),
            categoryName: tag['category'] as String?,
            icon: tag['icon'] as String?,
            iconType: iconType(tag['iconType']),
            color: tag['color'] as int?,
          )
    ],
    savedPlaces: [
      for (final place in root['savedPlaces'] as List? ?? const [])
        if (Place.fromJson(place) case final saved?) saved
    ],
    entries: [
      for (final entry in root['entries'] as List? ?? const [])
        if (entry is Map) _parseEntry(entry, contentsPath, tagType, moodOffset)
    ],
  );
}

ImportedEntry _parseEntry(Map entry, String contentsPath,
    TagType Function(Object?) tagType, int moodOffset) {
  final timeCreate = DateTime.parse(entry['timeCreate'] as String);
  final modified = entry['timeModified'] as String?;
  final mood = entry['mood'] as int?;
  final sourceId = entry['id'];
  return ImportedEntry(
    Entry(
      text: entry['text'] as String? ?? '',
      mood: mood == null ? null : (mood + moodOffset).clamp(-2, 2),
      timeCreate: timeCreate,
      timeModified: modified == null ? timeCreate : DateTime.parse(modified),
    ),
    sourceId: sourceId == null ? null : '$sourceId',
    tags: [
      if (entry['favourite'] == true) const ImportedEntryTag.favourite(),
      for (final tag in entry['tags'] as List? ?? const [])
        if (tag is Map && tag['name'] is String)
          ImportedEntryTag(
            name: tag['name'] as String,
            tagType: tagType(tag['type']),
            categoryName: tag['category'] as String?,
            value: tag['value']?.toString(),
          )
    ],
    files: [
      for (final attachment in entry['attachments'] as List? ?? const [])
        if (attachment is Map &&
            attachment['path'] is String &&
            _insideContents(contentsPath, attachment['path'] as String))
          ImportedFile(
            type: AttachmentType.values
                    .where((type) => type.name == attachment['type'])
                    .firstOrNull ??
                AttachmentType.image,
            rank: attachment['rank'] as int? ?? 0,
            timeCreate:
                DateTime.tryParse(attachment['timeCreate'] as String? ?? '') ??
                    timeCreate,
            path: join(contentsPath, attachment['path'] as String),
          )
    ],
  );
}

/// Attachment paths may not climb out of the export's folder.
bool _insideContents(String contentsPath, String relative) =>
    isWithin(contentsPath, normalize(join(contentsPath, relative)));

const _zipSignature = [0x50, 0x4B, 0x03, 0x04];

Future<List<int>> _header(File file) async {
  final handle = await file.open();
  try {
    return await handle.read(_zipSignature.length);
  } finally {
    await handle.close();
  }
}

bool _isZip(List<int> header) =>
    header.length == _zipSignature.length &&
    [for (final (index, byte) in _zipSignature.indexed) header[index] == byte]
        .every((matches) => matches);

/// The old JSON: a list of entries whose images are already in storage.
List<ImportedEntry> decodeJsonEntries(Uint8List bytes) =>
    _legacyEntries(json.decode(utf8.decode(bytes.toList())) as List);

List<ImportedEntry> _legacyEntries(List jsonData) {
  return [
    for (var entry in jsonData)
      ImportedEntry(
        Entry(
            text: entry['text'],
            mood: entry['mood'] as int?,
            timeCreate: DateTime.parse(entry['timeCreated']),
            timeModified: DateTime.parse(entry['timeModified'])),
        sourceId: entry['id'] == null ? null : '${entry['id']}',
        attachments: [
          // Support old imgPath field
          if (entry['imgPath'] != null)
            EntryAttachment(
                entryId: null,
                type: AttachmentType.image,
                filePath: entry['imgPath'],
                rank: 0,
                timeCreate: DateTime.now()),
          if (entry['images'] != null)
            for (var image in entry['images'])
              EntryAttachment(
                  entryId: null,
                  type: AttachmentType.image,
                  filePath: image['imgPath'],
                  rank: image['imgRank'] as int,
                  timeCreate: DateTime.parse(image['timeCreated'])),
        ],
      ),
  ];
}
