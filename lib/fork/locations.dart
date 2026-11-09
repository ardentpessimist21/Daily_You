// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/search_highlight.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/utils/color_utils.dart';
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

  /// `[name](address)`, or `[name](address "description")` (3.7.0.43). A
  /// link title is plain Markdown, so the official app still reads it.
  static final RegExp _linked =
      RegExp(r'^\[([^\[\]\n]+)\]\(([^()\s"]+)(?: "([^"\n]*)")?\)$');

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
    final description = _cleanDescription(place.description);
    var address = place.address.trim().replaceAll(RegExp(r'[()\s"]'), '');
    // A description needs a link to sit on: a name-only place gets the
    // same name search it opens anyway.
    if (address.isEmpty && description.isNotEmpty) {
      address = Places.typedPlace(name).address;
    }
    if (address.isEmpty) return name;
    return description.isEmpty
        ? '[$name]($address)'
        : '[$name]($address "$description")';
  }

  static String _cleanDescription(String description) => Place.clipDescription(
      description.replaceAll('"', "'").replaceAll(separator.trim(), ' '));

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
        places.add(Place(match.group(1)!.trim(), match.group(2)!,
            Place.clipDescription(match.group(3) ?? '')));
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

/// The raised look shared by every place pill: the secondary container
/// colour with a darker bottom edge.
class _PillSurface extends StatelessWidget {
  const _PillSurface({
    required this.radius,
    required this.padding,
    required this.child,
    this.onTap,
  });

  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = colorScheme.secondaryContainer;
    final edge = Color.alphaBlend(
        colorScheme.shadow.withValues(alpha: 0.28), background);
    final shape = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(color: edge, borderRadius: shape),
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: background,
        borderRadius: shape,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                borderRadius: shape,
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

/// The two-line place pill (3.7.0.44): 📍 and the name, with the place's
/// description underneath when it has one. Used in the entry view, where
/// tapping opens Maps, and in the editor, where tapping opens the place
/// dialog (Remove lives there, so the pill has no ✕).
class PlacePill extends StatelessWidget {
  const PlacePill({
    super.key,
    required this.place,
    required this.onTap,
    required this.semanticsLabel,
  });

  final Place place;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSecondaryContainer;
    final hasDescription = place.description.isNotEmpty;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: _PillSurface(
        radius: 12,
        padding: const EdgeInsets.fromLTRB(9, 6, 12, 6),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: hasDescription
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(top: hasDescription ? 1 : 0),
              child: Icon(Icons.place_rounded, size: 15, color: foreground),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasDescription)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        place.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.72),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small one-line 📍 chip on Timeline and Gallery cards: the first
/// place's name and "+N" for more. It never takes taps (3.7.0.44), so
/// tapping it opens the entry like the rest of the card.
///
/// [highlight] marks Gallery search matches: the matched part of the name,
/// or the description after the name when that is what matched.
class LocationChip extends StatelessWidget {
  const LocationChip({
    super.key,
    required this.place,
    this.count = 0,
    this.nameMatch,
    this.descriptionMatch,
  });

  final Place place;

  /// How many more places the entry has, shown as "+N".
  final int count;

  /// Where the search matched, as (start, end) in the name or description.
  final (int, int)? nameMatch;
  final (int, int)? descriptionMatch;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSecondaryContainer;
    final base = TextStyle(
      color: foreground,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final mark = base.copyWith(
      backgroundColor: SearchHighlight.matchColor,
      color: contrastingTextColor(SearchHighlight.matchColor),
    );
    List<TextSpan> marked(String text, (int, int)? range, TextStyle style) {
      if (range == null) return [TextSpan(text: text, style: style)];
      return [
        if (range.$1 > 0)
          TextSpan(text: text.substring(0, range.$1), style: style),
        TextSpan(text: text.substring(range.$1, range.$2), style: mark),
        if (range.$2 < text.length)
          TextSpan(text: text.substring(range.$2), style: style),
      ];
    }

    final subtle = base.copyWith(
        color: foreground.withValues(alpha: 0.72), fontWeight: FontWeight.w400);
    final label = Text.rich(
      TextSpan(children: [
        ...marked(place.name, nameMatch, base),
        if (descriptionMatch != null) ...[
          TextSpan(text: ' · ', style: subtle),
          ...marked(place.description, descriptionMatch, subtle),
        ],
        if (count > 0) TextSpan(text: '  +$count', style: subtle),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return IgnorePointer(
      child: Semantics(
        label: place.name,
        excludeSemantics: true,
        child: _PillSurface(
          radius: 10,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_rounded, size: 15, color: foreground),
              const SizedBox(width: 5),
              Flexible(child: label),
            ],
          ),
        ),
      ),
    );
  }
}

/// The entry view's place pills: one per place, in the order added,
/// wrapping onto more lines. Tapping one opens it in Maps.
class LocationButtons extends StatelessWidget {
  const LocationButtons({super.key, required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty || !EntryLocations.showButtons) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        children: [
          for (final place in places)
            PlacePill(
              place: place,
              onTap: () => openPlace(context, place),
              semanticsLabel: l10n.locationOpenInMaps(place.name),
            ),
        ],
      ),
    );
  }
}

/// The Timeline and Gallery card chip: the first place, plus how many more.
class TimelineLocationButton extends StatelessWidget {
  const TimelineLocationButton({super.key, required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty || !EntryLocations.showButtons) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: LocationChip(place: places.first, count: places.length - 1),
    );
  }
}

/// The editor's place pills under the date, same look as the entry view.
/// Tapping one opens its Name · Map link · Description dialog, which has
/// Remove.
class LocationRows extends StatelessWidget {
  const LocationRows({super.key, required this.places, required this.onTap});

  final List<Place> places;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        children: [
          for (var i = 0; i < places.length; i++)
            PlacePill(
              place: places[i],
              onTap: () => onTap(i),
              semanticsLabel: places[i].name,
            ),
        ],
      ),
    );
  }
}

/// An entry's writing and places, read from its text.
extension EntryPlaces on Entry {
  /// The text without the hidden location line.
  String get body => EntryLocations.bodyOf(text);

  List<Place> get places => EntryLocations.placesOf(text);
}
