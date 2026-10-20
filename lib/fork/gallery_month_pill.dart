// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The floating "September 2026" pill shown while scrolling the Gallery.
/// Tapping it opens a month picker to jump straight to a month.
class GalleryMonthPill extends StatelessWidget {
  const GalleryMonthPill({
    super.key,
    required this.month,
    required this.visible,
    required this.onTap,
  });

  final DateTime? month;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final month = this.month;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible && month != null ? 1 : 0,
        duration: Duration(milliseconds: visible ? 150 : 400),
        child: month == null
            ? const SizedBox.shrink()
            : Material(
                // Light on dark themes, dark on light ones, so it stands out
                // against cards and photos either way.
                color: colorScheme.inverseSurface,
                elevation: 3,
                shadowColor: Colors.black54,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onTap,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          TimeManager.formatMonthYear(month, context),
                          style: TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down_rounded,
                            size: 20, color: colorScheme.onInverseSurface),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Opens the month picker for [entries] and returns the chosen month.
  static Future<DateTime?> pickMonth(
      BuildContext context, List<Entry> entries, DateTime initial) {
    final counts = <(int, int), int>{};
    for (final entry in entries) {
      final key = (entry.timeCreate.year, entry.timeCreate.month);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final years = counts.keys.map((key) => key.$1).toList()..sort();
    if (years.isEmpty) return Future.value(null);
    return showAppDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(
        counts: counts,
        firstYear: years.first,
        lastYear: years.last,
        initialYear: initial.year.clamp(years.first, years.last),
        selected: initial,
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.counts,
    required this.firstYear,
    required this.lastYear,
    required this.initialYear,
    required this.selected,
  });

  final Map<(int, int), int> counts;
  final int firstYear;
  final int lastYear;
  final int initialYear;
  final DateTime selected;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initialYear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = TimeManager.currentLocale(context);
    final monthFormat = DateFormat.MMM(locale);

    return AlertDialog(
      title: Text(l10n.galleryJumpToMonth),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _year > widget.firstYear
                      ? () => setState(() => _year--)
                      : null,
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _year < widget.lastYear
                      ? () => setState(() => _year++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(12, (index) {
                final month = index + 1;
                final count = widget.counts[(_year, month)] ?? 0;
                final isSelected = widget.selected.year == _year &&
                    widget.selected.month == month;
                final enabled = count > 0;
                final background = isSelected
                    ? colorScheme.primary
                    : enabled
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5);
                final foreground = isSelected
                    ? colorScheme.onPrimary
                    : enabled
                        ? colorScheme.onSecondaryContainer
                        : Theme.of(context).disabledColor;
                return Material(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: enabled
                        ? () => Navigator.pop(context, DateTime(_year, month))
                        : null,
                    child: Semantics(
                      button: enabled,
                      label:
                          '${monthFormat.format(DateTime(_year, month))}, ${l10n.galleryMonthEntries(count)}',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            monthFormat.format(DateTime(_year, month)),
                            style: TextStyle(
                                color: foreground, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            enabled ? '$count' : '–',
                            style: TextStyle(color: foreground, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
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
