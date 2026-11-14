// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// A place: one of an entry's places, or a saved place you go often, e.g.
/// Home or Work. [address] is an optional map link; without one the place
/// is just its name.
class Place {
  const Place(this.name, [this.address = '', this.description = '']);

  final String name;
  final String address;

  /// A short note shown under the name: on saved places (3.7.0.39) and,
  /// since 3.7.0.43, on an entry's own places too. It's a label, so it isn't
  /// part of what makes two places the same spot.
  final String description;

  /// The longest description a place can have (3.7.0.43: 40, was 20).
  static const int descriptionMaxLength = 40;

  /// Same spot and the same description: what decides whether an entry's
  /// places changed.
  bool sameAs(Place other) => this == other && description == other.description;

  Place copyWith({String? name, String? address, String? description}) => Place(
      name ?? this.name,
      address ?? this.address,
      description ?? this.description);

  Map<String, String> toJson() => {
        'name': name,
        'address': address,
        if (description.isNotEmpty) 'description': description,
      };

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
    final description = json['description'];
    return Place(
      name.trim(),
      address is String ? address.trim() : '',
      description is String ? clipDescription(description) : '',
    );
  }

  /// A description as stored: one line, at most [descriptionMaxLength]
  /// characters.
  static String clipDescription(String text) {
    final line = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final chars = line.characters;
    return chars.length <= descriptionMaxLength
        ? line
        : chars.take(descriptionMaxLength).toString().trim();
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
  /// With [search], Maps opens searching that text (3.7.0.39).
  static Future<bool> findInMaps(
      BuildContext context, void Function(Place place) add,
      {String? search}) async {
    waitForMapsPlace(context, add);
    final query = search?.trim() ?? '';
    final url = query.isEmpty
        ? Uri.parse('https://www.google.com/maps')
        : Uri.https(
            'www.google.com', '/maps/search/', {'api': '1', 'query': query});
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
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
  // Places used in entries (3.7.0.43)

  static String _key(String name) => name.trim().toLowerCase();

  /// Every place used in [entries], most recently used first. One row per
  /// name (ignoring case), keeping the newest entry's map link. The entry's
  /// own description stays behind, since it was about that entry.
  static List<RecentPlace> usedPlaces(Iterable<Entry> entries) {
    final byKey = <String, RecentPlace>{};
    for (final entry in entries) {
      final seen = <String>{};
      for (final place in EntryLocations.placesOf(entry.text)) {
        final key = _key(place.name);
        if (key.isEmpty || !seen.add(key)) continue;
        final known = byKey[key];
        if (known == null) {
          byKey[key] = RecentPlace(
              Place(place.name.trim(), place.address), entry.timeCreate, 1);
        } else {
          final newer = entry.timeCreate.isAfter(known.used);
          byKey[key] = RecentPlace(
              newer ? Place(place.name.trim(), place.address) : known.place,
              newer ? entry.timeCreate : known.used,
              known.count + 1);
        }
      }
    }
    return byKey.values.toList()..sort((a, b) => b.used.compareTo(a.used));
  }

  /// Used places that aren't saved places yet: Settings › Locations' Recent.
  static List<RecentPlace> recentNotSaved(
      Iterable<Entry> entries, List<Place> saved) {
    final savedKeys = saved.map((place) => _key(place.name)).toSet();
    return usedPlaces(entries)
        .where((recent) => !savedKeys.contains(_key(recent.place.name)))
        .toList();
  }

  /// "Oct 28" this year, "Mar 2025" before.
  static String usedLabel(BuildContext context, DateTime date) {
    final locale = TimeManager.currentLocale(context);
    return date.year == DateTime.now().year
        ? DateFormat.MMMd(locale).format(date)
        : DateFormat.yMMM(locale).format(date);
  }

  // The 📍 toolbar sheet

  /// [onPicked] (3.7.0.50) takes the picked place instead of the editor or
  /// [controller], e.g. a template's place.
  static Future<void> showPlaceSheet(
      BuildContext context, TextEditingController? controller,
      {void Function(Place place)? onPicked}) async {
    final copied =
        (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!context.mounted) return;
    void add(Place place) {
      if (onPicked != null) {
        onPicked(place);
        return;
      }
      final sink = addToEditor;
      if (sink != null) {
        sink(place);
      } else if (controller != null) {
        insertAtCursor(controller, markdownFor(place));
      }
    }

    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _PlaceSheet(
        copiedPlace: placeFromShared(copied),
        onFindInMaps: (search) async {
          Navigator.pop(sheetContext);
          final opened = await findInMaps(context, add, search: search);
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

/// A place used in entries: when it was last used and in how many entries.
class RecentPlace {
  const RecentPlace(this.place, this.used, this.count);

  final Place place;
  final DateTime used;
  final int count;
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
  final void Function(String? search) onFindInMaps;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  final TextEditingController _search = TextEditingController();
  late List<Place> _saved = Places.savedPlaces();
  late final List<RecentPlace> _used =
      Places.usedPlaces(EntriesProvider.instance.entries);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  /// The saved or used place named exactly [_query], ignoring case.
  Place? get _exact {
    final key = _query.toLowerCase();
    if (key.isEmpty) return null;
    for (final place in _saved) {
      if (place.name.toLowerCase() == key) return place;
    }
    for (final recent in _used) {
      if (recent.place.name.toLowerCase() == key) return recent.place;
    }
    return null;
  }

  void _submit() {
    if (_query.isEmpty) return;
    Navigator.pop(context, _exact ?? Places.typedPlace(_query));
  }

  /// [name] with the part matching the search in the accent colour.
  Widget _highlighted(String name, ColorScheme colorScheme) {
    final start = name.toLowerCase().indexOf(_query.toLowerCase());
    if (_query.isEmpty || start < 0) return Text(name);
    final end = start + _query.length;
    return Text.rich(TextSpan(children: [
      TextSpan(text: name.substring(0, start)),
      TextSpan(
          text: name.substring(start, end),
          style: TextStyle(
              color: colorScheme.primary, fontWeight: FontWeight.w600)),
      TextSpan(text: name.substring(end)),
    ]));
  }

  Widget _section(String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }

  List<Widget> _browsing(AppLocalizations l10n, ColorScheme colorScheme) {
    final copied = widget.copiedPlace;
    return [
      if (copied != null)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading:
              Icon(Icons.content_paste_rounded, color: colorScheme.primary),
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
        onTap: () => widget.onFindInMaps(null),
      ),
      _section(l10n.placeSaved),
      for (final place in _saved)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(Icons.place_rounded, color: colorScheme.primary),
          title: Text(place.name),
          subtitle: place.description.isEmpty
              ? null
              : Text(place.description,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.pop(context, place),
        ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading:
            Icon(Icons.settings_rounded, color: colorScheme.onSurfaceVariant),
        title: Text(l10n.placeManageSaved),
        onTap: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SavedPlacesPage()));
          if (mounted) setState(() => _saved = Places.savedPlaces());
        },
      ),
    ];
  }

  List<Widget> _searching(AppLocalizations l10n, ColorScheme colorScheme) {
    final key = _query.toLowerCase();
    final savedKeys = _saved.map((p) => p.name.toLowerCase()).toSet();
    final recent = _used
        .where((r) =>
            r.place.name.toLowerCase().contains(key) &&
            !savedKeys.contains(r.place.name.toLowerCase()))
        .take(12)
        .toList();
    final saved =
        _saved.where((p) => p.name.toLowerCase().contains(key)).toList();
    return [
      if (_exact == null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Material(
            color: colorScheme.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Icon(Icons.add_location_alt_rounded,
                  color: colorScheme.primary),
              title: Text(l10n.placeAddTyped(_query),
                  style: TextStyle(color: colorScheme.primary)),
              subtitle: Text(l10n.placeAddTypedHint),
              onTap: () => Navigator.pop(context, Places.typedPlace(_query)),
            ),
          ),
        ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(Icons.map_rounded, color: colorScheme.primary),
        title: Text(l10n.placeSearchInMaps(_query),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(l10n.placeSearchInMapsHint),
        onTap: () => widget.onFindInMaps(_query),
      ),
      _section(l10n.placeMatches),
      if (recent.isEmpty && saved.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(l10n.placeNoMatches,
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ),
      for (final r in recent)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(Icons.history_rounded, color: colorScheme.primary),
          title: _highlighted(r.place.name, colorScheme),
          subtitle: Text(
              l10n.placeMatchRecent(Places.usedLabel(context, r.used)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.pop(context, r.place),
        ),
      for (final place in saved)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(Icons.place_rounded, color: colorScheme.primary),
          title: _highlighted(place.name, colorScheme),
          subtitle: Text(
              place.description.isEmpty
                  ? l10n.placeMatchSaved
                  : '${l10n.placeMatchSaved} · ${place.description}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.pop(context, place),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
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
                controller: _search,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.placeSearchHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              ...(_query.isEmpty
                  ? _browsing(l10n, colorScheme)
                  : _searching(l10n, colorScheme)),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the place dialog ended with: a place to save, or Delete / Remove.
typedef PlaceDialogResult = ({Place? place, bool removed});

/// The Name · Map link · Description dialog (3.7.0.43). Settings ›
/// Locations uses it for saved places ([removeLabel] Delete, asks first);
/// the editor uses it for an entry's own place ([removeLabel] Remove).
Future<PlaceDialogResult?> showPlaceDialog(
  BuildContext context, {
  required String title,
  Place? initial,
  String? footnote,
  String? removeLabel,
  Future<bool> Function()? confirmRemove,
}) async {
  final result = await showDialog<PlaceDialogResult>(
    context: context,
    builder: (_) => _PlaceDialog(
      title: title,
      initial: initial,
      footnote: footnote,
      removeLabel: removeLabel,
      confirmRemove: confirmRemove,
    ),
  );
  return result;
}

class _PlaceDialog extends StatefulWidget {
  const _PlaceDialog({
    required this.title,
    this.initial,
    this.footnote,
    this.removeLabel,
    this.confirmRemove,
  });

  final String title;
  final Place? initial;
  final String? footnote;
  final String? removeLabel;
  final Future<bool> Function()? confirmRemove;

  @override
  State<_PlaceDialog> createState() => _PlaceDialogState();
}

class _PlaceDialogState extends State<_PlaceDialog> {
  late final TextEditingController _name = TextEditingController(
      text: widget.initial?.name == Places.unnamed
          ? ''
          : widget.initial?.name ?? '');
  late final TextEditingController _address =
      TextEditingController(text: _shownAddress(widget.initial?.address ?? ''));
  late final TextEditingController _description =
      TextEditingController(text: widget.initial?.description ?? '');

  /// A name search (`geo:0,0?q=…`) is what a place without a link does
  /// anyway, so the box shows empty rather than the search address.
  static String _shownAddress(String address) =>
      address.toLowerCase().startsWith('geo:0,0?q=') ? '' : address;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final typed = _address.text.trim();
    final original = widget.initial?.address ?? '';
    // Left as it was shown: keep the original address (e.g. a name search
    // that follows the old name gets the new name instead).
    String address;
    if (typed.isEmpty) {
      address = original.toLowerCase().startsWith('geo:0,0?q=')
          ? Places.typedPlace(name).address
          : '';
    } else {
      address = Places.fromShared(typed)?.$2 ?? typed;
    }
    Navigator.pop(context, (
      place: Place(name, address, Place.clipDescription(_description.text)),
      removed: false,
    ));
  }

  Future<void> _remove() async {
    final confirm = widget.confirmRemove;
    if (confirm != null && !await confirm()) return;
    if (mounted) Navigator.pop(context, (place: null, removed: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final removeLabel = widget.removeLabel;
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.placeName,
                    helperText: l10n.placeSearchNameHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton.filledTonal(
                  tooltip: l10n.placeFindInMaps,
                  icon: const Icon(Icons.map_rounded),
                  onPressed: () {
                    // The place shared back from Maps fills the link, and
                    // the name if it's still empty
                    Places.findInMaps(context, (place) {
                      if (!mounted) return;
                      _address.text = place.address;
                      if (_name.text.trim().isEmpty &&
                          place.name != Places.unnamed) {
                        _name.text = place.name;
                      }
                      setState(() {});
                    }, search: _name.text);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
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
                  final copied = (await Clipboard.getData(Clipboard.kTextPlain))
                          ?.text
                          ?.trim() ??
                      '';
                  final place = Places.fromShared(copied);
                  _address.text = place?.$2 ?? copied;
                  if (_name.text.trim().isEmpty &&
                      (place?.$1.isNotEmpty ?? false)) {
                    _name.text = place!.$1;
                  }
                  if (mounted) setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLength: Place.descriptionMaxLength,
            maxLines: 1,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.placeDescription,
              helperText: widget.footnote ?? l10n.placeDescriptionHint,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            if (removeLabel != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                onPressed: _remove,
                child: Text(removeLabel),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: _name.text.trim().isEmpty ? null : _save,
              child: Text(MaterialLocalizations.of(context).saveButtonLabel),
            ),
          ],
        ),
      ],
    );
  }
}

/// Settings → Locations: saved places, places used in entries that can be
/// pinned into them, and whether entries show their location buttons.
class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({super.key});

  @override
  State<SavedPlacesPage> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  late List<Place> _places = Places.savedPlaces();

  /// How many Recent places show.
  static const int _recentShown = 10;

  Future<bool> _confirmDelete(Place place) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.placeDeleteTitle(place.name)),
        content: Text(l10n.placeDeleteBody(place.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.placeDelete),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  Future<void> _edit([int? index]) async {
    final l10n = AppLocalizations.of(context)!;
    final existing = index == null ? null : _places[index];
    final result = await showPlaceDialog(
      context,
      title: existing?.name ?? l10n.placeNewSaved,
      initial: existing,
      removeLabel: existing == null ? null : l10n.placeDelete,
      confirmRemove: existing == null ? null : () => _confirmDelete(existing),
    );
    if (result == null || !mounted) return;
    setState(() {
      _places = [..._places];
      if (result.removed) {
        if (index != null) _places.removeAt(index);
      } else if (index == null) {
        _places.add(result.place!);
      } else {
        _places[index] = result.place!;
      }
    });
    await Places.saveSavedPlaces(_places);
  }

  Future<void> _pin(Place place) async {
    setState(() => _places = [..._places, place]);
    await Places.saveSavedPlaces(_places);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.placePinned(place.name)),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Widget _heading(String label, {String? note}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
          ),
          if (note != null)
            Text(note,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final recent =
        Places.recentNotSaved(EntriesProvider.instance.entries, _places)
            .take(_recentShown)
            .toList();
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
            _heading(l10n.placeSaved),
            if (_places.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(l10n.placeSavedEmpty,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
          ],
        ),
        footer: recent.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heading(l10n.placeRecent, note: l10n.placeRecentPinHint),
                  for (final r in recent)
                    ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(r.place.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          l10n.placeRecentUsed(
                              Places.usedLabel(context, r.used), r.count),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        tooltip: l10n.placePinToSaved,
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        color: colorScheme.primary,
                        icon: const Icon(Icons.push_pin_outlined),
                        onPressed: () => _pin(r.place),
                      ),
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
            subtitle: place.description.isEmpty
                ? Text(l10n.placeAddDescription,
                    style: TextStyle(color: colorScheme.outline))
                : Text(place.description,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _edit(index),
            trailing: IconButton(
              tooltip: l10n.placeEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(index),
            ),
          );
        },
      ),
    );
  }
}
