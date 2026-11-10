// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

class StatItem {
  final IconData icon;
  final String title;

  /// Statistics counts open their own page (3.7.0.48).
  final VoidCallback? onTap;

  const StatItem({required this.icon, required this.title, this.onTap});
}

({String number, String label}) _splitStat(String title) {
  final match = RegExp(r'\d+').firstMatch(title);
  if (match == null) return (number: '', label: title);

  final formatter = NumberFormat('#,###');
  final number =
      formatter.format(int.parse(title.substring(match.start, match.end)));
  final before = title.substring(0, match.start).trim();
  final after = title.substring(match.end).trim();
  return (
    number: number,
    label: [before, after].where((s) => s.isNotEmpty).join(' ')
  );
}

class StatsOverviewCard extends StatelessWidget {
  final StatItem? primary;
  final List<StatItem> sideItems;
  final List<StatItem> writingItems;

  const StatsOverviewCard({
    super.key,
    this.primary,
    this.sideItems = const [],
    this.writingItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (primary == null && sideItems.isEmpty && writingItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final dividerColor =
        Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Card.filled(
      margin: const EdgeInsets.all(4.0),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (primary != null) _HeroStat(item: primary!),
                  if (primary != null && sideItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: VerticalDivider(
                          width: 1, thickness: 1, color: dividerColor),
                    ),
                  if (sideItems.isNotEmpty)
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < sideItems.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _LineItem(item: sideItems[i], constrainWidth: true),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (writingItems.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(height: 1, thickness: 1, color: dividerColor),
              ),
              // Two centred lines of three (3.7.0.48): logs · days · words,
              // then tags · places · photos
              for (var row = 0; row * 3 < writingItems.length; row++)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    for (final item in writingItems.skip(row * 3).take(3))
                      _TappableItem(item: item),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final StatItem item;

  const _HeroStat({required this.item});

  @override
  Widget build(BuildContext context) {
    final stat = _splitStat(item.title);
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 26, color: color),
          const SizedBox(height: 6),
          Text(
            stat.number,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final StatItem item;

  // Allow item to wrap when there is not enough width. This cannot be used when the line item is placed withing a wrap
  final bool constrainWidth;

  const _LineItem({required this.item, this.constrainWidth = false});

  @override
  Widget build(BuildContext context) {
    final stat = _splitStat(item.title);
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface.withValues(alpha: 0.7);
    final numberColor = colorScheme.primary;

    final label = Text(
      stat.label,
      style: TextStyle(fontSize: 14, color: textColor),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          constrainWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(item.icon, size: 17, color: textColor),
        const SizedBox(width: 6),
        constrainWidth ? Flexible(child: label) : label,
        const SizedBox(width: 8),
        Text(
          stat.number,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: numberColor,
          ),
        ),
      ],
    );
  }
}

/// A count that opens its page: no arrows or outlines, just a soft rounded
/// highlight while pressed.
class _TappableItem extends StatelessWidget {
  const _TappableItem({required this.item});

  final StatItem item;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: _LineItem(item: item),
    );
    if (item.onTap == null) return child;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: item.onTap,
        child: child,
      ),
    );
  }
}
