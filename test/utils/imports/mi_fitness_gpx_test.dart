// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/imports/mi_fitness_gpx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../support/gpx_fixture.dart';

void main() {
  group('activityFromName', () {
    test('drops the date prefix Mi Fitness puts on names', () {
      expect(activityFromName('20261015Walking'), 'Walking');
    });

    test('spaces out joined words', () {
      expect(activityFromName('20261015OutdoorRunning'), 'Outdoor Running');
    });

    test('falls back to a generic name', () {
      expect(activityFromName(null), 'Workout');
      expect(activityFromName('20261015'), 'Workout');
    });
  });

  group('parseGpxWorkout', () {
    test('reads Mi Fitness times as the local time they were recorded', () {
      // Mi Fitness labels local wall-clock time as UTC; the app showed this
      // walk as starting at 4:54 PM on 15 October.
      final workout = parseGpxWorkout(gpxFixture());

      expect(workout.activity, 'Walking');
      expect(workout.source, 'Mi Fitness');
      expect(workout.start, DateTime(2026, 10, 15, 16, 54, 7));
      expect(workout.start.isUtc, isFalse);
      expect(workout.end, DateTime(2026, 10, 15, 17, 12, 13));
    });

    test('converts real UTC times from other apps to local time', () {
      final workout =
          parseGpxWorkout(gpxFixture(description: 'Export from Strava'));

      expect(workout.source, isNull);
      expect(workout.start, DateTime.utc(2026, 10, 15, 16, 54, 7).toLocal());
    });

    test('prefers the distance Mi Fitness recorded', () {
      final workout = parseGpxWorkout(gpxFixture(totalDistance: '10374'));

      expect(workout.distanceMeters, 10374);
    });

    test('measures the track when no distance is recorded, ignoring jitter',
        () {
      final workout = parseGpxWorkout(gpxFixture());

      expect(workout.distanceMeters, closeTo(2050, 15));
    });

    test('rejects a file without a track', () {
      expect(
          () => parseGpxWorkout(
              '<gpx xmlns="http://www.topografix.com/GPX/1/1"></gpx>'),
          throwsFormatException);
    });
  });

  group('formatLongDuration', () {
    test('rounds to the nearest minute like Mi Fitness', () {
      expect(
          formatLongDuration(
              const Duration(hours: 1, minutes: 44, seconds: 58)),
          '1 h 45 min');
      expect(formatLongDuration(const Duration(minutes: 42, seconds: 10)),
          '42 min');
    });
  });

  group('workoutEntryText', () {
    test('lists the date, distance, duration, start and end', () {
      final workout = parseGpxWorkout(gpxFixture(totalDistance: '2000'));
      final text = workoutEntryText(workout,
          dateFormat: DateFormat('d MMM y'), timeFormat: DateFormat('HH:mm'));

      expect(
          text,
          '## 🚶 Walking\n'
          '\n'
          '- **Date:** 15 Oct 2026\n'
          '- **Distance:** 2.00 km\n'
          '- **Duration:** 18 min\n'
          '- **Start:** 16:54\n'
          '- **End:** 17:12\n'
          '\n'
          '_Imported from Mi Fitness_');
    });
  });
}
