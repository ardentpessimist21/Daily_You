// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show basename, join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  late Directory root;
  late Directory supportDirectory;
  late Directory temporaryDirectory;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    root = await Directory.systemTemp.createTemp('restore_old_format');
    supportDirectory = await Directory(join(root.path, 'support')).create();
    temporaryDirectory = await Directory(join(root.path, 'temp')).create();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => switch (call.method) {
                  'getApplicationSupportDirectory' => supportDirectory.path,
                  'getTemporaryDirectory' => temporaryDirectory.path,
                  _ => null,
                });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    AttachmentStorage.instance.clearStoreOverrides();
    EntryAttachmentsProvider.instance.isLoaded = false;
    if (AppDatabase.instance.database != null) {
      await AppDatabase.instance.close();
    }
    await root.delete(recursive: true);
  });

  const imagesTable = '''
CREATE TABLE entry_images (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL,
    img_path TEXT NOT NULL,
    img_rank INTEGER NOT NULL,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (entry_id) REFERENCES entries (id)
)''';

  Future<void> createVersion5Database(
      String path, List<(int, int, String, int)> images,
      {required String entryText}) async {
    final db = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 5,
            onCreate: (db, _) async {
              await db.execute('''
CREATE TABLE entries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  text TEXT NOT NULL,
  mood INTEGER,
  time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
  time_modified DATETIME NOT NULL DEFAULT (DATETIME('now'))
)''');
              await db.execute('''
CREATE TABLE templates (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  text TEXT,
  time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
  time_modified DATETIME NOT NULL DEFAULT (DATETIME('now'))
)''');
              await db.execute(imagesTable);
              await db.execute('''
CREATE TABLE tag_categories (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    icon TEXT,
    icon_type INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    color INTEGER,
    sort_order INTEGER NOT NULL DEFAULT 0,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    time_modified DATETIME NOT NULL DEFAULT (DATETIME('now'))
)''');
              await db.execute('''
CREATE TABLE tags (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    icon TEXT,
    icon_type INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    tag_type INTEGER NOT NULL,
    color INTEGER,
    sort_order INTEGER NOT NULL DEFAULT 0,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    time_modified DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (category_id) REFERENCES tag_categories (id)
)''');
              await db.execute('''
CREATE TABLE entry_tags (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    value TEXT,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (entry_id) REFERENCES entries (id),
    FOREIGN KEY (tag_id) REFERENCES tags (id)
)''');
              await db.execute('''
CREATE TABLE template_tags (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    template_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (template_id) REFERENCES templates (id),
    FOREIGN KEY (tag_id) REFERENCES tags (id)
)''');
            }));
    await db.insert('entries', {'id': 1, 'text': entryText});
    for (final (id, entryId, imagePath, rank) in images) {
      await db.insert('entry_images', {
        'id': id,
        'entry_id': entryId,
        'img_path': imagePath,
        'img_rank': rank,
        'time_create': '2025-06-02T09:30:00.000',
      });
    }
    await db.close();
  }

  Future<Directory> startWithCurrentLibrary() async {
    await createVersion5Database(
        join(supportDirectory.path, AppDatabase.databaseFileName),
        [(1, 1, 'current.jpg', 0)],
        entryText: 'current entry');
    final images = await Directory(join(supportDirectory.path, 'Images'))
        .create(recursive: true);
    await File(join(images.path, 'current.jpg')).writeAsString('current');
    final audio =
        await Directory(join(supportDirectory.path, 'Audio')).create();
    await File(join(audio.path, 'voice.m4a')).writeAsString('voice');
    expect(await AppDatabase.instance.init(allowMigration: false), isTrue);
    return images;
  }

  Future<File> backupWith(List<(int, String, int)> images) async {
    final backupSource =
        await Directory(join(root.path, 'backup_source')).create();
    final backupDatabase =
        join(backupSource.path, AppDatabase.databaseFileName);
    await createVersion5Database(backupDatabase,
        [for (final (id, name, rank) in images) (id, 1, name, rank)],
        entryText: 'backed up entry');
    final backedUpImages =
        await Directory(join(backupSource.path, 'Images')).create();
    for (final (_, name, _) in images) {
      await File(join(backedUpImages.path, name))
          .writeAsString('bytes of $name');
    }
    final archive = join(root.path, 'backup.zip');
    await ZipUtils.compress(archive, [backupDatabase], [backedUpImages.path]);
    return File(archive);
  }

  Future<OperationOutcome> restore(File archive) async =>
      BackupRestoreUtils.restoreFromArchive(
          archive,
          Directory(join(temporaryDirectory.path, 'Restore')),
          await AppLocalizations.delegate.load(const Locale('en')),
          (_) {});

  test(
      'restores a backup made by the previous app version and removes what it does not reference',
      () async {
    final images = await startWithCurrentLibrary();
    final audio = Directory(join(supportDirectory.path, 'Audio'));
    final archive = await backupWith(
        [(2, 'first.jpg', 1), (3, 'second.png', 0), (7, 'third.jpg', 0)]);

    final outcome = await restore(archive);

    expect(outcome.succeeded, isTrue);
    final database = AppDatabase.instance.database!;
    expect(await database.getVersion(), AppDatabase.schemaVersion);
    final tables = (await database.query('sqlite_master',
            columns: ['name'], where: "type = 'table'"))
        .map((table) => table['name']);
    expect(tables, isNot(contains('entry_images')));
    expect((await database.query('entries')).single['text'], 'backed up entry');

    final attachments = EntryAttachmentsProvider.instance.attachments;
    expect(
        [for (final a in attachments) (a.id, a.filePath, a.rank, a.type)],
        unorderedEquals([
          (2, 'first.jpg', 1, AttachmentType.image),
          (3, 'second.png', 0, AttachmentType.image),
          (7, 'third.jpg', 0, AttachmentType.image),
        ]));
    for (final name in ['first.jpg', 'second.png', 'third.jpg']) {
      expect(
          File(join(images.path, name)).readAsStringSync(), 'bytes of $name');
    }
    expect(File(join(images.path, 'current.jpg')).existsSync(), isFalse);
    expect(File(join(audio.path, 'voice.m4a')).existsSync(), isFalse);
  });

  test('a backup that fails to migrate leaves the current library untouched',
      () async {
    final images = await startWithCurrentLibrary();
    final backupSource =
        await Directory(join(root.path, 'backup_source')).create();
    final backupDatabase =
        join(backupSource.path, AppDatabase.databaseFileName);
    final unmigratable = await databaseFactory.openDatabase(backupDatabase,
        options: OpenDatabaseOptions(
            version: 5,
            onCreate: (db, _) =>
                db.execute('CREATE TABLE entries (id INTEGER, text TEXT)')));
    await unmigratable.close();
    final archive = join(root.path, 'backup.zip');
    await ZipUtils.compress(archive, [backupDatabase], []);

    await expectLater(restore(File(archive)), throwsA(anything));

    final database = AppDatabase.instance.database!;
    expect((await database.query('entries')).single['text'], 'current entry');
    expect(EntryAttachmentsProvider.instance.attachments.single.filePath,
        'current.jpg');
    expect(File(join(images.path, 'current.jpg')).existsSync(), isTrue);
    expect(
        supportDirectory
            .listSync()
            .whereType<File>()
            .map((file) => basename(file.path)),
        [AppDatabase.databaseFileName]);
  });

  test('a backup file that cannot be copied keeps the files already held',
      () async {
    final images = await startWithCurrentLibrary();
    await Directory(join(images.path, 'first.jpg')).create();
    final archive =
        await backupWith([(2, 'first.jpg', 0), (3, 'second.png', 0)]);

    final outcome = await restore(archive);

    expect(outcome.succeeded, isFalse);
    expect(File(join(images.path, 'second.png')).readAsStringSync(),
        'bytes of second.png');
    expect(File(join(images.path, 'current.jpg')).existsSync(), isTrue);
    expect(File(join(supportDirectory.path, 'Audio', 'voice.m4a')).existsSync(),
        isTrue);
  });

  group('Update S: settings in backups', () {
    Future<File> backupWithSettings(Map<String, Object?> settings) async {
      final archive = await backupWith([(2, 'first.jpg', 0)]);
      // Rebuild the archive with a settings file next to the database
      final staged = await Directory(join(root.path, 'with_settings')).create();
      await ZipUtils.extract(archive.path, staged.path);
      final settingsFile =
          File(join(staged.path, ConfigProvider.backupSettingsFileName));
      await settingsFile.writeAsString(json.encode(settings));
      final rebuilt = join(root.path, 'backup_with_settings.zip');
      await ZipUtils.compress(
          rebuilt,
          [join(staged.path, AppDatabase.databaseFileName), settingsFile.path],
          [join(staged.path, 'Images')]);
      return File(rebuilt);
    }

    Future<OperationOutcome> restoreAsking(File archive, bool answer) async {
      var asked = false;
      final outcome = await BackupRestoreUtils.restoreFromArchive(
          archive,
          Directory(join(temporaryDirectory.path, 'Restore')),
          await AppLocalizations.delegate.load(const Locale('en')),
          (_) {}, restoreSettings: () async {
        asked = true;
        return answer;
      });
      expect(asked, isTrue, reason: 'should ask before restoring settings');
      return outcome;
    }

    test('a backup leaves out passwords and device folders', () async {
      final config = ConfigProvider.instance;
      await config.set(Settings.theme, 'dark');
      await config.set(Settings.autoBackupLocationUri, 'content://folder');
      await config.set(Settings.logSyncFolderUri, 'content://sync');
      final saved = config.settingsForBackup();
      expect(saved[Settings.theme.key], 'dark');
      expect(saved.containsKey(Settings.autoBackupLocationUri.key), isFalse);
      expect(saved.containsKey(Settings.logSyncFolderUri.key), isFalse);
      expect(saved.containsKey(Settings.requirePassword.key), isFalse);
      expect(saved.containsKey(Settings.passwordHash.key), isFalse);
      expect(saved.containsKey(Settings.backupPassword.key), isFalse);
    });

    test('restores settings when you choose to', () async {
      await startWithCurrentLibrary();
      final archive = await backupWithSettings({
        Settings.theme.key: 'dark',
        Settings.veryHappyIcon.key: '🤩',
        Settings.requirePassword.key: true,
        Settings.autoBackupLocationUri.key: 'content://old-phone',
        'notARealSetting': 1,
      });

      final outcome = await restoreAsking(archive, true);

      expect(outcome.succeeded, isTrue);
      final config = ConfigProvider.instance;
      expect(config.get(Settings.theme), 'dark');
      expect(config.get(Settings.veryHappyIcon), '🤩');
      expect(config.get(Settings.requirePassword), isFalse);
      expect(config.get(Settings.autoBackupLocationUri), '');
      expect(
          (await AppDatabase.instance.database!.query('entries'))
              .single['text'],
          'backed up entry');
    });

    test('"Logs only" leaves settings as they are', () async {
      await startWithCurrentLibrary();
      final archive = await backupWithSettings({Settings.theme.key: 'dark'});

      final outcome = await restoreAsking(archive, false);

      expect(outcome.succeeded, isTrue);
      expect(ConfigProvider.instance.get(Settings.theme), 'system');
    });

    test('older backups without settings restore as before', () async {
      await startWithCurrentLibrary();
      final archive = await backupWith([(2, 'first.jpg', 0)]);
      var asked = false;
      final outcome = await BackupRestoreUtils.restoreFromArchive(
          archive,
          Directory(join(temporaryDirectory.path, 'Restore')),
          await AppLocalizations.delegate.load(const Locale('en')),
          (_) {}, restoreSettings: () async {
        asked = true;
        return true;
      });
      expect(outcome.succeeded, isTrue);
      expect(asked, isFalse);
    });
  });
}
