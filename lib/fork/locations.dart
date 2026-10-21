// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:material_ui/material_ui.dart';

/// An entry's places, kept without changing the database: they live on the
/// entry's last line, after a blank line, e.g.
///
///     📍 [Work](geo:-27.47,153.02) · Uni · [Jollibee](https://maps.app…)
///
/// Daily You Dev hides that line and shows the places as buttons. The
/// official Daily You shows it as an ordinary line with tappable links, so
/// backups stay restorable in both apps.
class EntryLocations {
  static const String separator = ' · ';

  static final RegExp _linked = RegExp(r'^\[([^\[\]\n]+)\]\(([^()\s]+)\)$');

  /// Whether the location buttons show in the entry view and Timeline.
  static bool get showButtons =>
      ConfigProvider.instance.get(Settings.showLocationButtons);

  /// Splits [text] into what you wrote and its places.
  static (String, List<Place>) split(String text) {
    final trimmed = text.trimRight();
    final lineStart = trimmed.lastIndexOf('\n') + 1;
    final places = _parseLine(trimmed.substring(lineStart));
    if (places == null) return (text, const []);
    if (lineStart == 0) return ('', places);
    // The line must stand apart from the writing above it.
    if (!trimmed.substring(0, lineStart).endsWith('\n\n')) {
      return (text, const []);
    }
    return (trimmed.substring(0, lineStart).trimRight(), places);
  }

  /// [text] without its location line: what to show, count and search.
  static String bodyOf(String text) => split(text).$1;

  static List<Place> placesOf(String text) => split(text).$2;

  /// [body] with [places] on the hidden last line.
  static String join(String body, List<Place> places) {
    final clean = places.where((place) => _clean(place.name).isNotEmpty);
    if (clean.isEmpty) return body;
    final line = '${Places.pin} ${clean.map(_item).join(separator)}';
    final writing = body.trimRight();
    return writing.isEmpty ? line : '$writing\n\n$line';
  }

  /// [text] with [place] added after its other places.
  static String add(String text, Place place) {
    final (body, places) = split(text);
    return join(body, [...places, place]);
  }

  /// The places as plain words for sharing outside the app, with a Maps
  /// link for each place that has a spot.
  static String shareLine(List<Place> places) => places.map((place) {
        final url = Places.mapsUrlFor(place.address) ?? place.address;
        return url.isEmpty
            ? '${Places.pin} ${place.name}'
            : '${Places.pin} ${place.name} $url';
      }).join('\n');

  static String _item(Place place) {
    final name = _clean(place.name);
    final address = place.address.trim().replaceAll(RegExp(r'[()\s]'), '');
    return address.isEmpty ? name : '[$name]($address)';
  }

  static String _clean(String name) {
    var clean = name.trim();
    if (clean.startsWith(Places.pin)) {
      clean = clean.substring(Places.pin.length).trim();
    }
    return clean
        .replaceAll(separator.trim(), ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'[\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<Place>? _parseLine(String line) {
    final prefix = '${Places.pin} ';
    if (!line.startsWith(prefix)) return null;
    final rest = line.substring(prefix.length).trim();
    if (rest.isEmpty) return null;
    final places = <Place>[];
    for (final raw in rest.split(separator)) {
      final item = raw.trim();
      if (item.isEmpty) return null;
      final match = _linked.firstMatch(item);
      if (match != null) {
        places.add(Place(match.group(1)!.trim(), match.group(2)!));
      } else if (RegExp(r'[\[\]()]').hasMatch(item)) {
        // Brackets that aren't a link: ordinary writing, not places.
        return null;
      } else {
        places.add(Place(item));
      }
    }
    return places;
  }
}

/// Opens [place] in Google Maps. A place without a map spot searches its
/// name.
Future<void> openPlace(BuildContext context, Place place) => EntryLinks.open(
    context,
    place.address.isNotEmpty
        ? place.address
        : Places.typedPlace(place.name).address);

/// A raised 📍 button that opens the place in Maps.
class LocationButton extends StatelessWidget {
  const LocationButton({
    super.key,
    required this.place,
    this.compact = false,
    this.count = 0,
    this.enabled = true,
  });

  final Place place;

  /// The smaller Timeline version.
  final bool compact;

  /// How many more places the entry has, shown as "+N".
  final int count;

  /// False while the Timeline is selecting, so taps select the card.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = colorScheme.secondaryContainer;
    final foreground = colorScheme.onSecondaryContainer;
    final edge = Color.alphaBlend(
        colorScheme.shadow.withValues(alpha: 0.28), background);
    final radius = BorderRadius.circular(compact ? 10 : 14);
    final label = count > 0 ? '${place.name}  +$count' : place.name;
    final button = Container(
      decoration: BoxDecoration(
        color: edge,
        borderRadius: radius,
      ),
      padding: EdgeInsets.only(bottom: compact ? 2 : 3),
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? () => openPlace(context, place) : null,
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(Icons.place_rounded,
                    size: compact ? 15 : 20, color: foreground),
                SizedBox(width: compact ? 5 : 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.open_in_new_rounded,
                      size: 16, color: foreground.withValues(alpha: 0.7)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.locationOpenInMaps(place.name),
      excludeSemantics: true,
      child: enabled ? button : IgnorePointer(child: button),
    );
  }
}

/// The entry view's buttons: one per place, in the order added.
class LocationButtons extends StatelessWidget {
  const LocationButtons({super.key, required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty || !EntryLocations.showButtons) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final place in places)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LocationButton(place: place),
            ),
        ],
      ),
    );
  }
}

/// The Timeline card's button: the first place, plus how many more.
class TimelineLocationButton extends StatelessWidget {
  const TimelineLocationButton(
      {super.key, required this.places, this.enabled = true});

  final List<Place> places;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty || !EntryLocations.showButtons) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: LocationButton(
        place: places.first,
        compact: true,
        count: places.length - 1,
        enabled: enabled,
      ),
    );
  }
}

/// The editor's rows under the date: one per place, each with ✕.
class LocationRows extends StatelessWidget {
  const LocationRows({super.key, required this.places, required this.onRemove});

  final List<Place> places;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (var i = 0; i < places.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Icon(Icons.place_rounded,
                        size: 20, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        places[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.locationRemove,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => onRemove(i),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// An entry's writing and places, read from its text.
extension EntryPlaces on Entry {
  /// The text without the hidden location line.
  String get body => EntryLocations.bodyOf(text);

  List<Place> get places => EntryLocations.placesOf(text);
}
