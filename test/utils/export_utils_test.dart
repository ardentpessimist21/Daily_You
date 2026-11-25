// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

// Update D: the Markdown, CSV, JSON and Day One exports, and that the JSON
// and Day One exports import back in.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:daily_you/utils/exports/export_writers.dart';
import 'package:daily_you/utils/imports/import_dayone.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/utils/imports/import_json.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' show join;

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  late Directory sources;
  setUp(() => sources = Directory.systemTemp.createTempSync('export_test'));
  tearDown(() => sources.deleteSync(recursive: true));

  String sourceFile(String name, List<int> bytes) {
    final file = File(join(sources.path, name))..writeAsBytesSync(bytes);
    return file.path;
  }

  ExportSnapshot snapshot() {
    final morning = DateTime(2026, 3, 4, 8, 30);
    final evening = DateTime(2026, 3, 4, 20, 5);
    final photo = sourceFile('a.jpg', [1, 2, 3]);
    return ExportSnapshot(
      locale: 'en',
      exportedAt: DateTime(2026, 3, 5),
      moodNames: const {2: 'Great', 1: 'Pleasant'},
      moodColors: const {2: 0xFF00FF00, 1: 0xFF00AA00},
      tags: [
        Tag(
            id: 1,
            name: 'Plants',
            tagType: TagType.label,
            timeCreate: morning,
            timeModified: morning),
        Tag(
            id: 2,
            name: 'Steps',
            tagType: TagType.tracker,
            timeCreate: morning,
            timeModified: morning),
      ],
      savedPlaces: const [Place('Home', 'geo:1.00000,2.00000')],
      entries: [
        ExportEntry(
          Entry(
              id: 10,
              text: 'Repotted the calamansi.\n\n'
                  '📍 [Home](geo:1.00000,2.00000) · [Park](geo:3.00000,4.00000)',
              mood: 2,
              timeCreate: morning,
              timeModified: morning),
          favourite: true,
          tags: const [
            ExportEntryTag(name: 'Plants', tagType: TagType.label),
            ExportEntryTag(
                name: 'Steps', tagType: TagType.tracker, value: 4200),
          ],
          attachments: [
            ExportAttachment(
                type: AttachmentType.image,
                rank: 0,
                timeCreate: morning,
                sourcePath: photo),
          ],
        ),
        ExportEntry(
          Entry(
              id: 11,
              text: 'See [this morning](entry:10).',
              mood: 1,
              timeCreate: evening,
              timeModified: DateTime(2026, 3, 6)),
        ),
      ],
    );
  }

  group('Markdown', () {
    test('header block, time, ⭐, tags, places and links to notes', () async {
      final store = InMemoryFileStore();
      final attachments = await writeMarkdown(snapshot(), store);
      expect(await store.list(),
          unorderedEquals(['log_2026-03-04.md', 'log_2026-03-04_2.md']));
      final first = utf8.decode((await store.read('log_2026-03-04.md'))!);
      expect(first, startsWith('---\ndate: "2026-03-04T08:30:00.000"\n'));
      expect(first, contains('moodLabel: "Great"'));
      expect(first, contains('favourite: true'));
      expect(first, contains('tags: ["Plants"]'));
      expect(first, contains('trackers: {"Steps":4200}'));
      expect(first, contains('places: ["Home","Park"]'));
      // intl puts a narrow space before AM
      expect(first, contains('Wed, Mar 4, 2026 · 8:30'));
      expect(first, contains('AM ⭐'));
      expect(first, contains('#Plants'));
      expect(first, contains('![](Images/image_2026-03-04_0.jpg)'));
      expect(attachments.keys, ['Images/image_2026-03-04_0.jpg']);

      final second = utf8.decode((await store.read('log_2026-03-04_2.md'))!);
      expect(second, contains('See [this morning](log_2026-03-04.md).'));
    });
  });

  test('CSV has a row per entry and a column per tracker', () async {
    final store = InMemoryFileStore();
    await writeCsv(snapshot(), store);
    final csv = utf8.decode((await store.read(csvDocumentName))!);
    final lines = csv.split('\r\n');
    expect(lines.first, contains('favourite'));
    expect(lines.first, endsWith('tracker:Steps'));
    expect(lines[1], contains('Home, Park'));
    expect(lines[1], endsWith('4200'));
    expect(lines.length, 3);
  });

  group('JSON', () {
    test('writes everything and imports back in, links and all', () async {
      final folder = Directory(join(sources.path, 'json'))..createSync();
      final attachments =
          await writeJson(snapshot(), LocalFileStore(folder.path));
      // Put the attachment beside it, as the zip would
      for (final MapEntry(:key, :value) in attachments.entries) {
        File(join(folder.path, key))
          ..createSync(recursive: true)
          ..writeAsBytesSync(File(value).readAsBytesSync());
      }
      final document = File(join(folder.path, jsonDocumentName));
      final root = jsonDecode(document.readAsStringSync()) as Map;
      expect(root['format'], forkJsonFormatMarker);
      expect(root['moodScale'], hasLength(2));
      expect(root['savedPlaces'], [
        {'name': 'Home', 'address': 'geo:1.00000,2.00000'}
      ]);

      final parsed = parseJsonDocument(document.readAsBytesSync(), folder.path);
      expect(parsed.entries, hasLength(2));
      final first = parsed.entries.first;
      expect(first.entry.mood, 2);
      expect(first.entry.text, contains('📍 [Home]'));
      expect(first.sourceId, '10');
      expect(first.tags.map((tag) => tag.name),
          containsAll(['Favourite', 'Plants', 'Steps']));
      expect(first.tags.firstWhere((tag) => tag.name == 'Steps').value, '4200');
      expect(first.files.single.type, AttachmentType.image);
      expect(File(first.files.single.path).existsSync(), isTrue);
      expect(parsed.savedPlaces.single.name, 'Home');
      // The link is pointed at the new entry
      expect(
          rewriteEntryLinks(
              parsed.entries[1].entry.text, (id) => id == '10' ? 99 : null),
          'See [this morning](entry:99).');
    });

    test('reads upstream JSON, whose moods run 1 to 5', () {
      final parsed = parseJsonDocument(
          utf8.encode(jsonEncode({
            'format': 'daily-you',
            'version': 2,
            'entries': [
              {
                'text': 'Hi',
                'mood': 5,
                'timeCreate': '2026-01-01T09:00:00.000',
                'timeModified': '2026-01-01T09:00:00.000',
              }
            ],
          })),
          sources.path);
      expect(parsed.entries.single.entry.mood, 2);
    });

    test('attachment paths may not leave the export', () {
      final parsed = parseJsonDocument(
          utf8.encode(jsonEncode({
            'format': forkJsonFormatMarker,
            'version': 1,
            'entries': [
              {
                'text': 'Hi',
                'timeCreate': '2026-01-01T09:00:00.000',
                'attachments': [
                  {'type': 'image', 'path': '../../etc/passwd'}
                ],
              }
            ],
          })),
          sources.path);
      expect(parsed.entries.single.files, isEmpty);
    });
  });

  group('Day One', () {
    test('first place is the location, the rest stay; imports back', () async {
      final folder = Directory(join(sources.path, 'dayone'))..createSync();
      final media = await writeDayOne(snapshot(), LocalFileStore(folder.path));
      for (final MapEntry(:key, :value) in media.entries) {
        File(join(folder.path, key))
          ..createSync(recursive: true)
          ..writeAsBytesSync(File(value).readAsBytesSync());
      }
      final journal = File(join(folder.path, dayOneDocumentName));
      final root = jsonDecode(journal.readAsStringSync()) as Map;
      final first = (root['entries'] as List).first as Map;
      expect(first['location'],
          {'placeName': 'Home', 'latitude': 1.0, 'longitude': 2.0});
      expect(first['starred'], isTrue);
      expect(first['text'], contains('📍 [Park]'));
      expect(first['text'], isNot(contains('[Home]')));
      expect((first['photos'] as List).single['type'], 'jpg');
      final second = (root['entries'] as List)[1] as Map;
      expect(
          second['text'], contains('dayone://view?entryId=${first['uuid']}'));

      final entries = await parseDayOne(journal, sources.path);
      expect(entries, hasLength(2));
      final back = entries.first;
      expect(back.entry.text, contains('Repotted the calamansi.'));
      expect(back.entry.text, isNot(contains('dayone-moment')));
      // Location first, then the place that stayed in the text
      expect(back.entry.text, contains('📍'));
      expect(back.tags.any((tag) => tag.favourite), isTrue);
      expect(back.files.single.type, AttachmentType.image);
      expect(back.entry.timeCreate, DateTime(2026, 3, 4, 8, 30));
      expect(
          rewriteDayOneLinks(
              entries[1].entry.text, (id) => id == first['uuid'] ? 7 : null),
          contains('(entry:7)'));
    });

    test('a location without coordinates is a typed place', () {
      final place = dayOnePlace({'placeName': 'Cafe'});
      expect(place!.name, 'Cafe');
      expect(place.address, startsWith('geo:0,0?q='));
      expect(dayOnePlace({'latitude': 0, 'longitude': 0}), isNull);
    });
  });

  test('entries dated after today are skipped, unless allowed', () {
    ImportGuard.reset();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(ImportGuard.skip(DateTime.now()), isFalse);
    expect(ImportGuard.skip(tomorrow), isTrue);
    expect(ImportGuard.skip(tomorrow, allowFuture: true), isFalse);
    expect(ImportGuard.skippedFuture, 1);
  });
}
