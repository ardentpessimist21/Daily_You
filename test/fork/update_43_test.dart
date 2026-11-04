// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/models/entry.dart';
import 'package:flutter_test/flutter_test.dart';

Entry _entry(int id, String text, DateTime time) =>
    Entry(id: id, text: text, timeCreate: time, timeModified: time);

void main() {
  group('3.7.0.43 entry place descriptions', () {
    test('a description rides on the link title and reads back', () {
      final text = EntryLocations.join('Lunch after shift', [
        const Place('Jollibee', 'https://maps.app.goo.gl/7xQe', 'Lunch spot'),
        const Place('Uni'),
      ]);
      expect(text,
          'Lunch after shift\n\n📍 [Jollibee](https://maps.app.goo.gl/7xQe "Lunch spot") · Uni');
      final (body, places) = EntryLocations.split(text);
      expect(body, 'Lunch after shift');
      expect(places.length, 2);
      expect(places.first.description, 'Lunch spot');
      expect(places.last.description, '');
    });

    test('old lines without descriptions still read', () {
      final places =
          EntryLocations.placesOf('Hi\n\n📍 [Work](geo:-27.47,153.02) · Uni');
      expect(places, const [Place('Work', 'geo:-27.47,153.02'), Place('Uni')]);
    });

    test('a name-only place with a description gets a name search', () {
      final text =
          EntryLocations.join('', [const Place('Eco Park', '', 'Walk')]);
      final place = EntryLocations.placesOf(text).single;
      expect(place.name, 'Eco Park');
      expect(place.address, Places.typedPlace('Eco Park').address);
      expect(place.description, 'Walk');
    });

    test('quotes and separators in a description stay safe', () {
      final text = EntryLocations.join(
          'x', [const Place('Home', 'geo:1,2', 'My "spot" · near')]);
      final place = EntryLocations.placesOf(text).single;
      expect(place.description, "My 'spot' near");
    });

    test('descriptions are capped at 40 characters', () {
      expect(Place.descriptionMaxLength, 40);
      final text =
          EntryLocations.join('x', [Place('Home', 'geo:1,2', 'y' * 60)]);
      expect(EntryLocations.placesOf(text).single.description.length, 40);
    });

    test('sameAs counts the description, == does not', () {
      const a = Place('Home', 'geo:1,2', 'one');
      const b = Place('Home', 'geo:1,2', 'two');
      expect(a == b, isTrue);
      expect(a.sameAs(b), isFalse);
    });
  });

  group('3.7.0.43 used places', () {
    final entries = [
      _entry(1, 'a\n\n📍 [Eco Park](geo:1,1 "Walk")', DateTime(2026, 10, 28)),
      _entry(2, 'b\n\n📍 eco park · Home', DateTime(2025, 3, 2)),
      _entry(3, 'c\n\n📍 Beleco Café', DateTime(2025, 3, 1)),
    ];

    test('newest first, one per name, counted, no entry description', () {
      final used = Places.usedPlaces(entries);
      expect(used.map((r) => r.place.name).toList(),
          ['Eco Park', 'Home', 'Beleco Café']);
      expect(used.first.count, 2);
      expect(used.first.place.address, 'geo:1,1');
      expect(used.first.place.description, '');
      expect(used.first.used, DateTime(2026, 10, 28));
    });

    test('Recent leaves out places already saved', () {
      final recent =
          Places.recentNotSaved(entries, const [Place('home', 'geo:9,9')]);
      expect(recent.map((r) => r.place.name), ['Eco Park', 'Beleco Café']);
    });
  });
}
