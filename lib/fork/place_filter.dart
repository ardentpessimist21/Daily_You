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

  /// What [pick] returns for Clear place.
  static const String cleared = '';

  /// The place list with a search box at the top. Returns the picked name,
  /// [cleared] for Clear place (shown when [current] is set), or null.
  static Future<String?> pick(BuildContext context, List<Entry> entries,
      {String? current}) {
    final places = placesIn(entries);
    return showAppDialog<String>(
      context: context,
      builder: (_) => _PlacePicker(places: places, current: current),
    );
  }
}

class _PlacePicker extends StatefulWidget {
  const _PlacePicker({required this.places, this.current});

  final List<PlaceCount> places;
  final String? current;

  /// Tighter rows, and about 6 show before the list scrolls (3.7.0.41).
  static const double rowHeight = 40;
  static const double visibleRows = 6.5;

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  String _query = '';

  bool _isCurrent(String name) =>
      widget.current != null &&
      widget.current!.trim().toLowerCase() == name.trim().toLowerCase();

  Widget _row(BuildContext context, PlaceCount place) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final picked = _isCurrent(place.name);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, place.name),
      child: Container(
        height: _PlacePicker.rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: picked
            ? BoxDecoration(
                color: PlaceFilter.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            const Icon(Icons.place_rounded, size: 18, color: PlaceFilter.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: picked ? FontWeight.w600 : null)),
            ),
            if (picked) ...[
              const Icon(Icons.check_rounded,
                  size: 18, color: PlaceFilter.color),
              const SizedBox(width: 6),
            ],
            Text(l10n.logCount(place.count),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  /// About 6 rows, the next one fading in to show there's more.
  Widget _list(BuildContext context, List<PlaceCount> shown) {
    final scrolls = shown.length > _PlacePicker.visibleRows;
    final list = SizedBox(
      height: _PlacePicker.rowHeight *
          (scrolls ? _PlacePicker.visibleRows : shown.length.toDouble()),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemExtent: _PlacePicker.rowHeight,
        itemCount: shown.length,
        itemBuilder: (context, index) => _row(context, shown[index]),
      ),
    );
    if (!scrolls) return list;
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0, 0.86, 1],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: list,
    );
  }

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
              _list(context, shown),
          ],
        ),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: PlaceFilter.color),
            onPressed: () => Navigator.pop(context, PlaceFilter.cleared),
            child: Text(l10n.placeFilterClear),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
