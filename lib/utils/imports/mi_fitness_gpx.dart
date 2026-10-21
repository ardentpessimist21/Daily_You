// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

/// GPS fixes closer together than this are treated as jitter, not movement.
const double _minHopMeters = 10;

/// A hop slower than this (10 m in more than a minute) counts as standing.
const Duration _maxMovingHop = Duration(seconds: 60);

class GpxTrackPoint {
  const GpxTrackPoint(this.lat, this.lon, this.time);

  final double lat;
  final double lon;
  final DateTime time;
}

/// A single workout read from a GPX export (such as Mi Fitness).
class GpxWorkout {
  const GpxWorkout({
    required this.activity,
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.movingTime,
    required this.kmSplits,
    required this.pointCount,
  });

  /// Human readable activity, e.g. "Walking" or "Outdoor Running".
  final String activity;

  /// Start and end of the recording, in UTC.
  final DateTime start;
  final DateTime end;

  /// The distance the app recorded, or one computed from the track.
  final double distanceMeters;
  final Duration movingTime;

  /// Time taken for each completed kilometre, in order.
  final List<Duration> kmSplits;
  final int pointCount;

  Duration get elapsed => end.difference(start);

  /// Average time per kilometre over the whole recording.
  Duration? get averagePace => distanceMeters < 1
      ? null
      : Duration(
          milliseconds:
              (elapsed.inMilliseconds / (distanceMeters / 1000)).round());
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

GpxWorkout parseGpxWorkout(String gpxText) {
  final document = XmlDocument.parse(gpxText);

  final points = <GpxTrackPoint>[];
  for (final element in document.findAllElements('trkpt')) {
    final lat = double.tryParse(element.getAttribute('lat') ?? '');
    final lon = double.tryParse(element.getAttribute('lon') ?? '');
    final timeText = element.getElement('time')?.innerText;
    final time = timeText == null ? null : DateTime.tryParse(timeText.trim());
    if (lat == null || lon == null || time == null) continue;
    points.add(GpxTrackPoint(lat, lon, time.toUtc()));
  }
  if (points.length < 2) {
    throw const FormatException('The GPX file has no recorded track.');
  }
  points.sort((a, b) => a.time.compareTo(b.time));

  // Walk the track hop by hop, ignoring jitter smaller than _minHopMeters.
  var anchor = points.first;
  var computedMeters = 0.0;
  var moving = Duration.zero;
  final splits = <Duration>[];
  var lastSplitTime = points.first.time;
  for (final point in points.skip(1)) {
    final hop = haversineMeters(anchor, point);
    if (hop < _minHopMeters) continue;
    final hopTime = point.time.difference(anchor.time);
    if (hopTime <= _maxMovingHop) moving += hopTime;
    computedMeters += hop;
    anchor = point;
    while (computedMeters >= (splits.length + 1) * 1000) {
      splits.add(point.time.difference(lastSplitTime));
      lastSplitTime = point.time;
    }
  }

  final metadataName = document.findAllElements('name').firstOrNull?.innerText;
  final reported = double.tryParse(
      document.findAllElements('totalDistance').firstOrNull?.innerText.trim() ??
          '');

  return GpxWorkout(
    activity: activityFromName(metadataName),
    start: points.first.time,
    end: points.last.time,
    distanceMeters:
        reported != null && reported > 0 ? reported : computedMeters,
    movingTime: moving,
    kmSplits: splits,
    pointCount: points.length,
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

/// "1 h 45 min" or "42 min".
String formatLongDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return hours > 0 ? '$hours h $minutes min' : '$minutes min';
}

/// "10:07".
String formatPace(Duration pace) {
  final minutes = pace.inMinutes;
  final seconds = (pace.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// The Markdown text of the journal entry for [workout].
///
/// Times are shown in the device's zone unless [toDisplayTime] says otherwise.
String workoutEntryText(GpxWorkout workout,
    {DateFormat? timeFormat,
    DateTime Function(DateTime utc)? toDisplayTime,
    String source = 'Mi Fitness'}) {
  final format = timeFormat ?? DateFormat.jm();
  final local = toDisplayTime ?? (DateTime utc) => utc.toLocal();
  final km = (workout.distanceMeters / 1000).toStringAsFixed(2);

  final buffer = StringBuffer()
    ..writeln('## ${_emojiFor(workout.activity)} ${workout.activity}')
    ..writeln();

  final headline =
      StringBuffer('**$km km** in ${formatLongDuration(workout.elapsed)}');
  final pace = workout.averagePace;
  if (pace != null) headline.write(' · ${formatPace(pace)} /km');
  buffer
    ..writeln(headline)
    ..writeln()
    ..writeln('- Started ${format.format(local(workout.start))}, '
        'finished ${format.format(local(workout.end))}')
    ..writeln('- Moving time ${formatLongDuration(workout.movingTime)}');

  if (workout.kmSplits.isNotEmpty) {
    var fastest = 0;
    for (var i = 1; i < workout.kmSplits.length; i++) {
      if (workout.kmSplits[i] < workout.kmSplits[fastest]) fastest = i;
    }
    buffer
      ..writeln('- Fastest km: ${formatPace(workout.kmSplits[fastest])} '
          '(km ${fastest + 1})')
      ..writeln('- Splits: ${workout.kmSplits.map(formatPace).join(' · ')}');
  }

  buffer
    ..writeln()
    ..write('_Imported from ${source}_');
  return buffer.toString();
}
