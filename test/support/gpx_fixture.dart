// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

/// Metres per degree of latitude used to lay out the synthetic track.
const double _metresPerDegree = 6371000 * 3.141592653589793 / 180;

/// A Mi Fitness style export walking due north at 2 m/s, with a minute's
/// stop after the first kilometre and sub-metre GPS jitter while stopped.
String gpxFixture(
    {String name = '20261015Walking',
    String description = 'Export from Mi Fitness',
    String? totalDistance}) {
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
      '<name>$name</name><desc>$description</desc>'
      '<trk>$extensions<trkseg>$points</trkseg></trk></gpx>';
}
