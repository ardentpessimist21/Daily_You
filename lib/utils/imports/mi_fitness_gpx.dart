// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

/// GPS fixes closer together than this are treated as jitter, not movement.
const double _minHopMeters = 10;

class GpxTrackPoint {
  const GpxTrackPoint(this.lat, this.lon);

  final double lat;
  final double lon;
}

/// A single workout read from a GPX export (such as Mi Fitness).
class GpxWorkout {
  const GpxWorkout({
    required this.activity,
    required this.start,
    required this.end,
    required this.distanceMeters,
    this.source,
  });

  /// Human readable activity, e.g. "Walking" or "Outdoor Running".
  final String activity;

  /// Start and end of the recording as local wall-clock times.
  final DateTime start;
  final DateTime end;

  /// The distance the app recorded, or one measured from the track.
  final double distanceMeters;

  /// The app that exported the file, when the file says so.
  final String? source;

  Duration get duration => end.difference(start);
}

double haversineMeters(GpxTrackPoint a, GpxTrackPoint b) {
  const earthRadius = 6371000.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLon = rad(b.lon - a.lon);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(h));
}

/// Turns names like "20261015Walking" or "OutdoorRunning" into
/// "Walking" or "Outdoor Running".
String activityFromName(String? name) {
  final stripped = (name ?? '').replaceFirst(RegExp(r'^[\d_\-\s]+'), '').trim();
  if (stripped.isEmpty) return 'Workout';
  return stripped
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
}

/// Mi Fitness writes the watch's local time but labels it as UTC ("Z"), so
/// its times are read as they are written. Other GPX files use real UTC.
DateTime _wallClock(DateTime parsed, {required bool labelledLocalAsUtc}) {
  if (!labelledLocalAsUtc) return parsed.toLocal();
  return DateTime(parsed.year, parsed.month, parsed.day, parsed.hour,
      parsed.minute, parsed.second, parsed.millisecond);
}

GpxWorkout parseGpxWorkout(String gpxText) {
  final document = XmlDocument.parse(gpxText);

  final description =
      document.findAllElements('desc').firstOrNull?.innerText ?? '';
  final isMiFitness = description.contains('Mi Fitness');

  final points = <GpxTrackPoint>[];
  DateTime? first;
  DateTime? last;
  for (final element in document.findAllElements('trkpt')) {
    final lat = double.tryParse(element.getAttribute('lat') ?? '');
    final lon = double.tryParse(element.getAttribute('lon') ?? '');
    final timeText = element.getElement('time')?.innerText;
    final time = timeText == null ? null : DateTime.tryParse(timeText.trim());
    if (lat == null || lon == null || time == null) continue;
    points.add(GpxTrackPoint(lat, lon));
    if (first == null || time.isBefore(first)) first = time;
    if (last == null || time.isAfter(last)) last = time;
  }
  if (points.length < 2 || first == null || last == null) {
    throw const FormatException('The GPX file has no recorded track.');
  }

  // Measure hop by hop, ignoring jitter smaller than _minHopMeters.
  var anchor = points.first;
  var measuredMeters = 0.0;
  for (final point in points.skip(1)) {
    final hop = haversineMeters(anchor, point);
    if (hop < _minHopMeters) continue;
    measuredMeters += hop;
    anchor = point;
  }

  final reported = double.tryParse(
      document.findAllElements('totalDistance').firstOrNull?.innerText.trim() ??
          '');

  return GpxWorkout(
    activity: activityFromName(
        document.findAllElements('name').firstOrNull?.innerText),
    start: _wallClock(first, labelledLocalAsUtc: isMiFitness),
    end: _wallClock(last, labelledLocalAsUtc: isMiFitness),
    distanceMeters:
        reported != null && reported > 0 ? reported : measuredMeters,
    source: isMiFitness ? 'Mi Fitness' : null,
  );
}

String _emojiFor(String activity) {
  final lower = activity.toLowerCase();
  if (lower.contains('walk')) return '🚶';
  if (lower.contains('run')) return '🏃';
  if (lower.contains('cycl') || lower.contains('bik')) return '🚴';
  if (lower.contains('hik')) return '🥾';
  if (lower.contains('swim')) return '🏊';
  return '🏅';
}

/// "1 h 45 min" or "42 min", rounded to the nearest minute.
String formatLongDuration(Duration duration) {
  final totalMinutes = (duration.inSeconds / 60).round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return hours > 0 ? '$hours h $minutes min' : '$minutes min';
}

/// The Markdown text of the journal entry for [workout].
String workoutEntryText(GpxWorkout workout,
    {DateFormat? dateFormat, DateFormat? timeFormat}) {
  final date = dateFormat ?? DateFormat.yMMMMEEEEd();
  final time = timeFormat ?? DateFormat.jm();
  final km = (workout.distanceMeters / 1000).toStringAsFixed(2);

  final buffer = StringBuffer()
    ..writeln('## ${_emojiFor(workout.activity)} ${workout.activity}')
    ..writeln()
    ..writeln('- **Date:** ${date.format(workout.start)}')
    ..writeln('- **Distance:** $km km')
    ..writeln('- **Duration:** ${formatLongDuration(workout.duration)}')
    ..writeln('- **Start:** ${time.format(workout.start)}')
    ..write('- **End:** ${time.format(workout.end)}');

  final source = workout.source;
  if (source != null) {
    buffer
      ..writeln()
      ..writeln()
      ..write('_Imported from ${source}_');
  }
  return buffer.toString();
}
