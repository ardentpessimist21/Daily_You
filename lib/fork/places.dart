// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// A place: one of an entry's places, or a saved place you go often, e.g.
/// Home or Work. [address] is an optional map link; without one the place
/// is just its name.
class Place {
  const Place(this.name, [this.address = '']);

  final String name;
  final String address;

  Map<String, String> toJson() => {'name': name, 'address': address};

  @override
  bool operator ==(Object other) =>
      other is Place && other.name == name && other.address == address;

  @override
  int get hashCode => Object.hash(name, address);

  @override
  String toString() => 'Place($name, $address)';

  static Place? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final address = json['address'];
    return Place(name.trim(), address is String ? address.trim() : '');
  }
}

/// Saved places are ordinary places.
typedef SavedPlace = Place;

/// 📍 places, without location permission or internet: typed, pasted or
/// shared from Google Maps, or saved places. An entry keeps them on a
/// hidden last line (see EntryLocations).
class Places {
  static const String pin = '📍';

  /// Set by the open entry editor: where a picked place goes. Without one
  /// (e.g. in a template) the place is written into the text as a link.
  static void Function(Place place)? addToEditor;

  static final RegExp _mapsLink = RegExp(
    r'https?://(?:maps\.app\.goo\.gl|goo\.gl/maps|g\.co/kgs|(?:www\.)?google\.[a-z.]+/maps|maps\.google\.[a-z.]+)\S*',
    caseSensitive: false,
  );
  static final RegExp _geo = RegExp(r'^geo:\S+$', caseSensitive: false);

  /// `[📍 name](address)`.
  static String named(String name, String address) {
    final clean = name.trim().startsWith(pin)
        ? name.trim().substring(pin.length).trim()
        : name.trim();
    return EntryLinks.markdown('$pin $clean', address);
  }

  /// A typed place: tapping it searches the name in your map app.
  static String typed(String name) => markdownFor(typedPlace(name));

  static Place typedPlace(String name) =>
      Place(name.trim(), 'geo:0,0?q=${Uri.encodeQueryComponent(name.trim())}');

  /// A place written into text: `[📍 name](address)`, or `📍 name`.
  static String markdownFor(Place place) => place.address.isEmpty
      ? '$pin ${place.name}'
      : named(place.name, place.address);

  /// A spot on the map, shown as its coordinates.
  static String coordinates(double latitude, double longitude) {
    final lat = latitude.toStringAsFixed(5);
    final lng = longitude.toStringAsFixed(5);
    return named('$lat, $lng', 'geo:$lat,$lng');
  }

  static String saved(Place place) => markdownFor(place);

  /// The name given to a Maps place that arrives without one.
  static const String unnamed = 'Google Maps';

  /// Puts a share's [subject] in front of a bare map link, since some
  /// versions of Google Maps send the place's name there instead of in the
  /// text. Anything else comes back unchanged.
  static String? nameShared(String? text, String? subject) {
    if (text == null) return null;
    final name = subject?.trim() ?? '';
    if (name.isEmpty || name.contains('\n') || name.length > 120) return text;
    if (RegExp(r'https?://|geo:', caseSensitive: false).hasMatch(name)) {
      return text;
    }
    final shared = fromShared(text);
    if (shared == null || shared.$1.isNotEmpty) return text;
    return '$name\n${text.trim()}';
  }

  /// A place read from shared or copied map text.
  static Place? placeFromShared(String text) {
    final shared = fromShared(text);
    if (shared == null) return null;
    final (name, address, _) = shared;
    if (name.isNotEmpty) return Place(name, address);
    if (address.toLowerCase().startsWith('geo:')) {
      return Place(_geoLabel(address), address);
    }
    return Place(unnamed, address);
  }

  /// Reads a place shared or copied from a map app: "Name\nhttps://maps…",
  /// a bare map link, or a geo: address. Returns (name, address, markdown).
  static (String, String, String)? fromShared(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (_geo.hasMatch(trimmed)) {
      return ('', trimmed, named(_geoLabel(trimmed), trimmed));
    }
    final match = _mapsLink.firstMatch(trimmed);
    if (match == null) return null;
    final address = match.group(0)!;
    final rest = trimmed.replaceRange(match.start, match.end, '').trim();
    // Anything besides the link should be a short name, not a paragraph.
    final lines = rest
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length > 3) return null;
    final name = lines.isEmpty ? '' : lines.first;
    return (name, address, named(name.isEmpty ? 'Google Maps' : name, address));
  }

  static String _geoLabel(String geo) {
    final query = Uri.tryParse(geo)?.queryParameters['q'];
    if (query != null && query.isNotEmpty) return query;
    final coords = geo.substring(4).split('?').first;
    return coords.replaceAll(',', ', ');
  }

  /// A Google Maps web link for a `geo:` address, or null for anything else.
  /// `geo:0,0?q=Jollibee` searches the name; `geo:-27.47,153.02` (with an
  /// optional `?q=`) opens that spot.
  static String? mapsUrlFor(String address) {
    final trimmed = address.trim();
    if (!_geo.hasMatch(trimmed)) return null;
    final rest = trimmed.substring(4);
    final question = rest.indexOf('?');
    final coords =
        (question < 0 ? rest : rest.substring(0, question)).split(';').first;
    final query = Uri.tryParse(trimmed)?.queryParameters['q']?.trim() ?? '';
    final parts = coords.split(',');
    final lat = parts.isNotEmpty ? double.tryParse(parts[0]) : null;
    final lng = parts.length > 1 ? double.tryParse(parts[1]) : null;
    final hasSpot = lat != null && lng != null && !(lat == 0 && lng == 0);
    final search = query.isNotEmpty
        ? query
        : hasSpot
            ? '$lat,$lng'
            : '';
    if (search.isEmpty) return 'https://www.google.com/maps';
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': search,
    }).toString();
  }

  /// Turns text shared into Daily You from a map app into a tidy place
  /// link; anything else is returned as it was.
  static String tidyShared(String text) => fromShared(text)?.$3 ?? text;

  // Saved places

  static List<Place> savedPlaces() {
    try {
      final decoded =
          jsonDecode(ConfigProvider.instance.get(Settings.savedPlaces));
      if (decoded is! List) return [];
      return decoded.map(Place.fromJson).nonNulls.toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSavedPlaces(List<Place> places) =>
      ConfigProvider.instance.set(Settings.savedPlaces,
          jsonEncode(places.map((place) => place.toJson()).toList()));

  // Find in Google Maps, then Share back to Daily You

  static _PendingPlace? _pending;

  /// Opens the map app. A place shared back to Daily You within 15 minutes
  /// goes to [add] while its editor is still open.
  static Future<bool> findInMaps(
      BuildContext context, void Function(Place place) add) async {
    waitForMapsPlace(context, add);
    try {
      return await launchUrl(Uri.parse('https://www.google.com/maps'),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      _pending = null;
      return false;
    }
  }

  /// Marks an editor as waiting for a place from Maps.
  static void waitForMapsPlace(
          BuildContext context, void Function(Place place) add) =>
      _pending = _PendingPlace(context, add, DateTime.now());

  /// Called when text is shared into the app. True when it was a place for
  /// an editor waiting on Maps, and has been added there.
  static bool deliverShared(String? text) {
    final pending = _pending;
    if (pending == null || text == null) return false;
    final place = placeFromShared(text);
    if (place == null) return false;
    _pending = null;
    final fresh =
        DateTime.now().difference(pending.since) < const Duration(minutes: 15);
    if (!fresh || !pending.context.mounted) return false;
    pending.add(place);
    return true;
  }

  // The 📍 toolbar sheet

  static Future<void> showPlaceSheet(
      BuildContext context, TextEditingController controller) async {
    final copied =
        (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!context.mounted) return;
    void add(Place place) {
      final sink = addToEditor;
      if (sink != null) {
        sink(place);
      } else {
        insertAtCursor(controller, markdownFor(place));
      }
    }

    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _PlaceSheet(
        copiedPlace: placeFromShared(copied),
        onFindInMaps: () async {
          Navigator.pop(sheetContext);
          final opened = await findInMaps(context, add);
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.linkCannotOpen),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
    if (place != null) add(place);
  }
}

class _PendingPlace {
  _PendingPlace(this.context, this.add, this.since);

  final BuildContext context;
  final void Function(Place place) add;
  final DateTime since;
}

class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({required this.copiedPlace, required this.onFindInMaps});

  final Place? copiedPlace;
  final VoidCallback onFindInMaps;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  final TextEditingController _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _addTyped() {
    final name = _typed.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, Places.typedPlace(name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final copied = widget.copiedPlace;
    final saved = Places.savedPlaces();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.placeAddTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _typed,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTyped(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.edit_location_alt_rounded),
                  hintText: l10n.placeTypeHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: _typed.text.trim().isEmpty ? null : _addTyped,
                    child: Text(l10n.linkAdd),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (copied != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(Icons.content_paste_rounded,
                      color: colorScheme.primary),
                  title: Text(l10n.placePasteCopied),
                  subtitle: Text('${Places.pin} ${copied.name}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(context, copied),
                ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(Icons.map_rounded, color: colorScheme.primary),
                title: Text(l10n.placeFindInMaps),
                subtitle: Text(l10n.placeFindInMapsHint),
                onTap: widget.onFindInMaps,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                child: Text(l10n.placeSaved,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
              ),
              for (final place in saved)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading:
                      Icon(Icons.place_rounded, color: colorScheme.primary),
                  title: Text(place.name),
                  subtitle:
                      place.address.isEmpty ? null : Text(l10n.placeHasMapSpot),
                  onTap: () => Navigator.pop(context, place),
                ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(Icons.settings_rounded,
                    color: colorScheme.onSurfaceVariant),
                title: Text(l10n.placeManageSaved),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SavedPlacesPage()));
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings → Locations: saved places, and whether entries show their
/// location buttons.
class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({super.key});

  @override
  State<SavedPlacesPage> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  late List<Place> _places = Places.savedPlaces();

  Future<void> _edit([int? index]) async {
    final l10n = AppLocalizations.of(context)!;
    final existing = index == null ? null : _places[index];
    final name = TextEditingController(text: existing?.name ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final result = await showDialog<Place>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.placeNewSaved : existing.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.placeName,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.placeMapLink,
                  helperText: l10n.placeMapLinkHint,
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: l10n.placePasteCopied,
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: () async {
                      final copied =
                          (await Clipboard.getData(Clipboard.kTextPlain))
                                  ?.text
                                  ?.trim() ??
                              '';
                      final place = Places.fromShared(copied);
                      address.text = place?.$2 ?? copied;
                      if (name.text.trim().isEmpty &&
                          (place?.$1.isNotEmpty ?? false)) {
                        name.text = place!.$1;
                      }
                      setDialogState(() {});
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: name.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                      context,
                      Place(
                          name.text.trim(),
                          Places.fromShared(address.text)?.$2 ??
                              address.text.trim())),
              child: Text(MaterialLocalizations.of(context).saveButtonLabel),
            ),
          ],
        ),
      ),
    );
    // Disposed after the dialog's closing animation, which still uses them.
    Future.delayed(const Duration(seconds: 1), () {
      name.dispose();
      address.dispose();
    });
    if (result == null) return;
    setState(() {
      _places = [..._places];
      if (index == null) {
        _places.add(result);
      } else {
        _places[index] = result;
      }
    });
    await Places.saveSavedPlaces(_places);
  }

  Future<void> _delete(int index) async {
    setState(() => _places = [..._places]..removeAt(index));
    await Places.saveSavedPlaces(_places);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLocations)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.placeNewSaved,
        onPressed: () => _edit(),
        child: const Icon(Icons.add_rounded),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsToggle(
              title: l10n.settingsShowLocationButtons,
              hint: l10n.settingsShowLocationButtonsHint,
              setting: Settings.showLocationButtons,
              onChanged: (value) => ConfigProvider.instance
                  .set(Settings.showLocationButtons, value),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(l10n.placeSaved,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: colorScheme.primary)),
            ),
            if (_places.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(l10n.placeSavedEmpty,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
          ],
        ),
        itemCount: _places.length,
        onReorderItem: (from, to) async {
          setState(() {
            _places = [..._places];
            final place = _places.removeAt(from);
            _places.insert(to, place);
          });
          await Places.saveSavedPlaces(_places);
        },
        itemBuilder: (context, index) {
          final place = _places[index];
          return ListTile(
            key: ValueKey('$index-${place.name}'),
            leading: const Icon(Icons.place_rounded),
            title: Text(place.name),
            subtitle: Text(place.address.isEmpty
                ? l10n.placeNoMapSpot
                : l10n.placeHasMapSpot),
            onTap: () => _edit(index),
            trailing: IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(index),
            ),
          );
        },
      ),
    );
  }
}
