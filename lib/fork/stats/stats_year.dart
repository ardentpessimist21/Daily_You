// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:material_ui/material_ui.dart';

/// Statistics years (3.7.0.48): one calendar year picked under All Time.

/// The entries a Statistics page shows: the range, or just [year].
List<Entry> entriesForStats(List<Entry> entries, StatsRange range, int? year) {
  if (range == StatsRange.allTime && year != null) {
    return entries.where((entry) => entry.timeCreate.year == year).toList();
  }
  return entriesInRange(entries, range);
}

/// How many entries each year has.
Map<int, int> entryCountsByYear(Iterable<Entry> entries) {
  final counts = <int, int>{};
  for (final entry in entries) {
    counts.update(entry.timeCreate.year, (count) => count + 1,
        ifAbsent: () => 1);
  }
  return counts;
}

/// What the year grid returned: a year, or All years (null).
class YearPick {
  const YearPick(this.year);
  final int? year;
}

/// The year grid: "All years" on top, then every year from the first
/// entry's to this one with its entry count, newest at the bottom and in
/// view. Empty years are dimmed and can't be picked.
Future<YearPick?> showStatsYearPicker(
  BuildContext context, {
  required Map<int, int> counts,
  required int? selected,
  bool allowAll = true,
}) {
  return showDialog<YearPick>(
    context: context,
    builder: (_) => _YearPickerDialog(
        counts: counts, selected: selected, allowAll: allowAll),
  );
}

class _YearPickerDialog extends StatefulWidget {
  const _YearPickerDialog(
      {required this.counts, required this.selected, required this.allowAll});

  final Map<int, int> counts;
  final int? selected;
  final bool allowAll;

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Open with the newest years in view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now().year;
    final first = widget.counts.keys.isEmpty
        ? now
        : widget.counts.keys.reduce((a, b) => a < b ? a : b);
    final years = [for (var y = first; y <= now; y++) y];

    Widget tile({
      required String label,
      required String? count,
      required bool selected,
      required VoidCallback? onTap,
    }) {
      final enabled = onTap != null;
      final background = selected
          ? colorScheme.primary
          : enabled
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      final foreground = selected
          ? colorScheme.onPrimary
          : enabled
              ? colorScheme.onSecondaryContainer
              : Theme.of(context).disabledColor;
      return Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        color: foreground, fontWeight: FontWeight.w600)),
                if (count != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count != '–') ...[
                        Icon(Icons.description_outlined,
                            size: 12, color: foreground),
                        const SizedBox(width: 3),
                      ],
                      Text(count,
                          style: TextStyle(color: foreground, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.statsPickYear),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allowAll) ...[
              SizedBox(
                height: 44,
                width: double.infinity,
                child: tile(
                  label: '${l10n.statsAllYears}  ·  $first–$now',
                  count: null,
                  selected: widget.selected == null,
                  onTap: () => Navigator.pop(context, const YearPick(null)),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: GridView.count(
                  controller: _scroll,
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.5,
                  children: [
                    for (final year in years)
                      tile(
                        label: '$year',
                        count: (widget.counts[year] ?? 0) > 0
                            ? '${widget.counts[year]}'
                            : '–',
                        selected: widget.selected == year,
                        onTap: (widget.counts[year] ?? 0) > 0
                            ? () => Navigator.pop(context, YearPick(year))
                            : null,
                      ),
                  ],
                ),
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

/// "All years ▾", or "2024 ▾ ✕" once a year is picked.
class StatsYearButton extends StatelessWidget {
  const StatsYearButton({
    super.key,
    required this.year,
    required this.counts,
    required this.onChanged,
  });

  final int? year;
  final Map<int, int> counts;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final picked = year != null;
    final foreground =
        picked ? colorScheme.onSecondaryContainer : colorScheme.onSurface;
    return Material(
      color: picked ? colorScheme.secondaryContainer : Colors.transparent,
      shape: StadiumBorder(
        side: picked
            ? BorderSide.none
            : BorderSide(color: colorScheme.outline.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () async {
          final pick = await showStatsYearPicker(context,
              counts: counts, selected: year);
          if (pick != null) onChanged(pick.year);
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 6, picked ? 6 : 8, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(picked ? '$year' : l10n.statsAllYears,
                  style: TextStyle(
                      color: foreground,
                      fontWeight: picked ? FontWeight.w600 : FontWeight.w500)),
              Icon(Icons.arrow_drop_down_rounded, size: 20, color: foreground),
              if (picked)
                Semantics(
                  button: true,
                  label: l10n.statsAllYears,
                  child: InkResponse(
                    radius: 16,
                    onTap: () => onChanged(null),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: foreground.withValues(alpha: 0.14),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: foreground),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
