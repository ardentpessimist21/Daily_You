// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/share_return.dart';
import 'package:daily_you/models/entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

Entry _entry(int id, DateTime time) =>
    Entry(id: id, text: 'entry $id', timeCreate: time, timeModified: time);

void main() {
  group('Share return stops', () {
    final day = DateTime(2026, 11, 3);
    final morning = _entry(1, DateTime(2026, 11, 3, 8));
    final evening = _entry(2, DateTime(2026, 11, 3, 20));
    final otherDay = _entry(3, DateTime(2026, 11, 2, 9));

    test('only entry on the day: entry view, then calendar', () {
      expect(
          ShareReturn.stops(
              kept: morning, day: day, entries: [morning, otherDay]),
          [ShareReturnStop.entryView]);
    });

    test('day with other entries: Timeline under the entry view', () {
      expect(
          ShareReturn.stops(
              kept: evening, day: day, entries: [morning, evening, otherDay]),
          [ShareReturnStop.timeline, ShareReturnStop.entryView]);
    });

    test('discarded on a day with other entries: Timeline', () {
      expect(ShareReturn.stops(kept: null, day: day, entries: [morning]),
          [ShareReturnStop.timeline]);
    });

    test('discarded on an empty day: straight to the calendar', () {
      expect(ShareReturn.stops(kept: null, day: day, entries: [otherDay]),
          isEmpty);
    });

    test('a deleted entry no longer counts for the day', () {
      expect(
          ShareReturn.stops(
              kept: null, day: day, entries: [morning], removedId: 1),
          isEmpty);
    });

    test('follows the entry when its date was changed in the editor', () {
      final moved = _entry(1, DateTime(2026, 11, 2, 18));
      expect(
          ShareReturn.stops(
              kept: moved, day: day, entries: [moved, otherDay, evening]),
          [ShareReturnStop.timeline, ShareReturnStop.entryView]);
    });

    test('a newer share stops an older editor putting pages back', () {
      final before = ShareReturn.currentShare;
      ShareReturn.newShare();
      expect(ShareReturn.currentShare, isNot(before));
    });
  });

  group('Saved place description', () {
    test('round-trips through saved JSON', () {
      const place = Place('Work', 'https://maps.app.goo.gl/x', 'Level 2');
      final back = Place.fromJson(jsonDecode(jsonEncode(place.toJson())));
      expect(back?.description, 'Level 2');
      expect(back?.name, 'Work');
    });

    test('older saved places load with no description', () {
      final back = Place.fromJson({'name': 'Home', 'address': ''});
      expect(back?.description, '');
      expect(const Place('Home').toJson().containsKey('description'), isFalse);
    });

    test('is one line of at most 20 characters', () {
      expect(Place.clipDescription('  Night\nshift  '), 'Night shift');
      final long = Place.clipDescription('A very long description indeed');
      expect(long.length, lessThanOrEqualTo(Place.descriptionMaxLength));
      expect(
          Place.fromJson({'name': 'X', 'description': 'x' * 40})!
              .description
              .length,
          Place.descriptionMaxLength);
    });

    test('a description does not make two places different spots', () {
      expect(const Place('Work', 'a', 'one'), const Place('Work', 'a', 'two'));
    });
  });

  group('Backup folder', () {
    useTemporaryConfig();

    test('is remembered but not carried in backups', () async {
      await ConfigProvider.instance
          .set(Settings.backupLocationUri, 'content://tree/Backups');
      expect(ConfigProvider.instance.get(Settings.backupLocationUri),
          'content://tree/Backups');
      expect(
          ConfigProvider.instance
              .settingsForBackup()
              .containsKey(Settings.backupLocationUri.key),
          isFalse);
    });
  });
}
