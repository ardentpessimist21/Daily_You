// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/time_manager.dart';
import 'package:material_ui/material_ui.dart';

/// The floating "September 2026" pill shown while scrolling the Gallery.
/// Tapping it opens Jump to month (see jump_picker.dart).
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
}
