// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/utils/imports/mi_fitness_gpx.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:share_receiver/share_receiver.dart';

final Logger _logger = Logger('WorkoutShare');

/// A share with any GPX workouts already turned into entry text.
class ResolvedShare {
  const ResolvedShare(this.payload, {this.workoutStart, this.failedGpx = 0});

  final SharePayload payload;

  /// When the earliest shared workout started, used as the new entry's time.
  final DateTime? workoutStart;

  /// How many shared GPX files could not be read.
  final int failedGpx;

  /// Whether there is anything left to add to the journal.
  bool get isEmpty {
    final text = payload.text;
    return (text == null || text.isEmpty) && !payload.hasMedia;
  }
}

/// Reads the shared GPX files and appends a summary of each workout to the
/// shared text. Other parts of the share are left as they are.
Future<ResolvedShare> resolveWorkoutShare(SharePayload payload,
    {DateFormat? dateFormat, DateFormat? timeFormat}) async {
  if (payload.gpxPaths.isEmpty) return ResolvedShare(payload);

  final workouts = <GpxWorkout>[];
  var failed = 0;
  for (final path in payload.gpxPaths) {
    try {
      workouts.add(parseGpxWorkout(await File(path).readAsString()));
    } catch (error) {
      failed += 1;
      _logger.warning('Could not read a shared GPX file', error);
    }
  }
  workouts.sort((a, b) => a.start.compareTo(b.start));

  final sections = [
    if (payload.text?.isNotEmpty ?? false) payload.text!,
    for (final workout in workouts)
      workoutEntryText(workout, dateFormat: dateFormat, timeFormat: timeFormat),
  ];

  return ResolvedShare(
    payload.copyWith(text: sections.isEmpty ? null : sections.join('\n\n')),
    workoutStart: workouts.firstOrNull?.start,
    failedGpx: failed,
  );
}
