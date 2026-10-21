// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/utils/imports/workout_share.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:share_receiver/share_receiver.dart';

import '../../support/gpx_fixture.dart';

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('gpx_share'));
  tearDown(() => directory.deleteSync(recursive: true));

  String writeFile(String name, String contents) {
    final file = File('${directory.path}/$name')..writeAsStringSync(contents);
    return file.path;
  }

  Future<ResolvedShare> resolve(SharePayload payload) =>
      resolveWorkoutShare(payload,
          dateFormat: DateFormat('d MMM y'), timeFormat: DateFormat('HH:mm'));

  test('leaves a share without GPX files untouched', () async {
    const payload = SharePayload(text: 'https://maps.app.goo.gl/abc');

    final resolved = await resolve(payload);

    expect(resolved.payload, same(payload));
    expect(resolved.workoutStart, isNull);
  });

  test('turns a shared workout into entry text timed at its start', () async {
    final path =
        writeFile('20261015Walking_03.gpx', gpxFixture(totalDistance: '10374'));

    final resolved = await resolve(SharePayload(gpxPaths: [path]));

    expect(resolved.isEmpty, isFalse);
    expect(resolved.workoutStart, DateTime(2026, 10, 15, 16, 54, 7));
    expect(resolved.payload.text, contains('- **Distance:** 10.37 km'));
    expect(resolved.payload.text, contains('- **Start:** 16:54'));
    // The file is kept so the share page can clean it up.
    expect(resolved.payload.gpxPaths, [path]);
  });

  test('keeps text shared alongside the workout', () async {
    final path = writeFile('walk.gpx', gpxFixture());

    final resolved =
        await resolve(SharePayload(text: 'Evening walk', gpxPaths: [path]));

    expect(resolved.payload.text, startsWith('Evening walk\n\n## 🚶 Walking'));
  });

  test('reports a GPX file it cannot read', () async {
    final path = writeFile('broken.gpx', 'not a gpx file');

    final resolved = await resolve(SharePayload(gpxPaths: [path]));

    expect(resolved.failedGpx, 1);
    expect(resolved.isEmpty, isTrue);
  });
}
