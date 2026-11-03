// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// A place found in entries, with how many entries it's in.
typedef PlaceCount = ({String name, int count});

/// Gallery › Filter's 📍 Places chip (3.7.0.40): narrow the Gallery to
/// entries with one place on them. Places are matched by name, ignoring
/// case, since the same place can be saved with different map links.
class PlaceFilter {
  static const Color color = Color(0xFFE5534B);

  static String _key(String name) => name.trim().toLowerCase();

  /// Every place in [entries], most used first, then by name.
  static List<PlaceCount> placesIn(Iterable<Entry> entries) {
    final counts = <String, int>{};
    final names = <String, String>{};
    for (final entry in entries) {
      final seen = <String>{};
      for (final place in EntryLocations.placesOf(entry.text)) {
        final key = _key(place.name);
        if (key.isEmpty || !seen.add(key)) continue;
        names.putIfAbsent(key, () => place.name.trim());
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final list = [
      for (final key in counts.keys) (name: names[key]!, count: counts[key]!),
    ]..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0
            ? byCount
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }

  /// Whether [entry] has the place called [name].
  static bool matches(Entry entry, String name) {
    final key = _key(name);
    return EntryLocations.placesOf(entry.text)
        .any((place) => _key(place.name) == key);
  }

  /// Places matching [query] (by name, anywhere in it).
  static List<PlaceCount> search(List<PlaceCount> places, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return places;
    return places.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  /// For the No Tags filter: no tags apart from ⭐ Favourite, which is set
  /// with the star button rather than as a tag.
  static bool isUntagged(Entry entry) {
    final favouriteId = Favourites.tag?.id;
    return TagsProvider.instance
        .getEntryTagsForEntry(entry.id ?? -1)
        .every((entryTag) => entryTag.tagId == favouriteId);
  }

  /// The place list with a search box at the top. Returns the picked name.
  static Future<String?> pick(BuildContext context, List<Entry> entries) {
    final places = placesIn(entries);
    return showAppDialog<String>(
      context: context,
      builder: (_) => _PlacePicker(places: places),
    );
  }
}

class _PlacePicker extends StatefulWidget {
  const _PlacePicker({required this.places});

  final List<PlaceCount> places;

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shown = PlaceFilter.search(widget.places, _query);
    return AlertDialog(
      title: Text(l10n.quickFilterPlaces),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchBar(
              hintText: l10n.placeFilterSearchHint,
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor:
                  WidgetStatePropertyAll(theme.colorScheme.secondaryContainer),
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.search_rounded,
                    color: theme.colorScheme.secondary),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            if (widget.places.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.placeFilterEmpty,
                    style:
                        TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              )
            else if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.noResults),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: shown.length,
                  itemBuilder: (context, index) {
                    final place = shown[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.place_rounded,
                          color: PlaceFilter.color),
                      title: Text(place.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(l10n.logCount(place.count),
                          style: theme.textTheme.bodySmall),
                      onTap: () => Navigator.pop(context, place.name),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
