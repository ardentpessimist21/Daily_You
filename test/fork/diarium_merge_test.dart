// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/imports/import_diarium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final created = DateTime(2025, 6, 2, 9, 30);
  final modified = DateTime(2025, 6, 3, 18, 5);
  const place = Place('16.22171, 120.45906', 'geo:16.22171,120.45906');

  late Database database;
  late InMemoryFileStore imageFiles;

  Future<void> reloadEverything() async {
    await EntryStore.instance.load();
    await TagsProvider.instance.load();
    await EntryAttachmentsProvider.instance.load();
  }

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
    imageFiles = InMemoryFileStore();
    AttachmentStorage.instance.overrideStores(imageFiles, InMemoryFileStore());
    await reloadEverything();
  });

  tearDown(() async {
    AttachmentStorage.instance.clearStoreOverrides();
    AppDatabase.instance.database = null;
    await database.close();
  });

  test('re-import adds the location and keeps everything else', () async {
    final tag = await TagDao.add(Tag(
        name: 'night shift',
        tagType: TagType.label,
        timeCreate: created,
        timeModified: created));
    await TagsProvider.instance.load();
    await imageFiles.write('photo.jpg', Uint8List.fromList([1, 2, 3]));

    final saved = await EntryStore.instance.beginDraft().save((_) => EntryDraft(
          entry: Entry(
              text: '# Test\n\nEdited in Daily You',
              mood: 1,
              timeCreate: created,
              timeModified: modified),
          tags: [EntryTag(entryId: 0, tagId: tag.id!, timeCreate: created)],
          attachments: [
            EntryAttachment(
                entryId: null,
                type: AttachmentType.image,
                filePath: 'photo.jpg',
                rank: 0,
                timeCreate: created)
          ],
        ));

    await addPlaceToImportedEntries(created, place);
    await reloadEverything();

    final entry =
        EntriesProvider.instance.entries.singleWhere((e) => e.id == saved.id);
    expect(entry.body, '# Test\n\nEdited in Daily You');
    expect(entry.places, [place]);
    expect(entry.mood, 1);
    expect(entry.timeModified, modified);
    expect(TagsProvider.instance.getEntryTagsForEntry(entry.id!).length, 1);
    expect(EntryAttachmentsProvider.instance.getForEntry(entry).length, 1);

    // Importing again doesn't add it twice.
    await addPlaceToImportedEntries(created, place);
    await reloadEverything();
    expect(
        EntriesProvider.instance.entries
            .singleWhere((e) => e.id == saved.id)
            .places,
        [place]);
  });

  test('entries at other times are left alone', () async {
    final saved = await EntryStore.instance.beginDraft().save((_) => EntryDraft(
          entry: Entry(
              text: 'Another day',
              timeCreate: created.add(const Duration(minutes: 1)),
              timeModified: modified),
          tags: const [],
          attachments: const [],
        ));
    await addPlaceToImportedEntries(created, place);
    await reloadEverything();
    expect(
        EntriesProvider.instance.entries
            .singleWhere((e) => e.id == saved.id)
            .text,
        'Another day');
  });
}
