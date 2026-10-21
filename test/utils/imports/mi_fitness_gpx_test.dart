// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/imports/mi_fitness_gpx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Metres per degree of latitude used to lay out the synthetic track.
const double _metresPerDegree = 6371000 * 3.141592653589793 / 180;

/// A Mi Fitness style export walking due north at 2 m/s, with a minute's
/// stop after the first kilometre and sub-metre GPS jitter while stopped.
String _gpx({String name = '20261015Walking', String? totalDistance}) {
  final start = DateTime.utc(2026, 10, 15, 16, 54, 7);
  final points = StringBuffer();
  var seconds = 0;
  var metres = 0.0;
  void add() {
    final lat = 16.2 + metres / _metresPerDegree;
    final time = start.add(Duration(seconds: seconds)).toIso8601String();
    points.write('<trkpt lat="$lat" lon="120.45"><time>$time</time></trkpt>');
  }

  for (; metres <= 1000; metres += 2, seconds += 1) {
    add();
  }
  metres -= 2;
  for (var i = 0; i < 60; i++, seconds += 1) {
    final saved = metres;
    metres += (i.isEven ? 0.5 : -0.5);
    add();
    metres = saved;
  }
  for (; metres <= 2050; metres += 2, seconds += 1) {
    add();
  }

  final extensions = totalDistance == null
      ? ''
      : '<extensions><totalDistance>$totalDistance</totalDistance>'
          '<cumulativeClimb>0.0</cumulativeClimb></extensions>';
  return "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>"
      '<gpx version="1.0" xmlns="http://www.topografix.com/GPX/1/1">'
      '<name>$name</name><desc>Export from Mi Fitness</desc>'
      '<trk>$extensions<trkseg>$points</trkseg></trk></gpx>';
}

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
    test('reads the start, end and activity', () {
      final workout = parseGpxWorkout(_gpx());

      expect(workout.activity, 'Walking');
      expect(workout.start, DateTime.utc(2026, 10, 15, 16, 54, 7));
      expect(workout.start.isUtc, isTrue);
      expect(workout.elapsed, greaterThan(const Duration(minutes: 17)));
    });

    test('prefers the distance Mi Fitness recorded', () {
      final workout = parseGpxWorkout(_gpx(totalDistance: '10374'));

      expect(workout.distanceMeters, 10374);
    });

    test('measures the track when no distance is recorded', () {
      final workout = parseGpxWorkout(_gpx());

      expect(workout.distanceMeters, closeTo(2050, 15));
    });

    test('ignores jitter and stops when timing', () {
      final workout = parseGpxWorkout(_gpx());

      expect(workout.movingTime.inSeconds, closeTo(1025, 10));
      expect(workout.kmSplits, hasLength(2));
      expect(workout.kmSplits.first.inSeconds, closeTo(500, 5));
      // The second kilometre includes the one-minute stop.
      expect(workout.kmSplits.last.inSeconds, closeTo(560, 10));
    });

    test('rejects a file without a track', () {
      expect(
          () => parseGpxWorkout(
              '<gpx xmlns="http://www.topografix.com/GPX/1/1"></gpx>'),
          throwsFormatException);
    });
  });

  group('workoutEntryText', () {
    test('summarises the workout in Markdown', () {
      final workout = parseGpxWorkout(_gpx(totalDistance: '2000'));
      final text = workoutEntryText(workout,
          timeFormat: DateFormat('HH:mm'),
          toDisplayTime: (utc) => utc.add(const Duration(hours: 8)));

      expect(text, startsWith('## 🚶 Walking\n'));
      expect(text, contains('**2.00 km** in 18 min'));
      expect(text, contains('- Started 00:54, finished 01:12'));
      expect(text, matches(RegExp(r'- Fastest km: 8:2\d \(km 1\)')));
      expect(text, endsWith('_Imported from Mi Fitness_'));
    });
  });
}
