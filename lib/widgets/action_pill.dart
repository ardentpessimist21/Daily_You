// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

/// The select-mode action bar (3.7.0.40): a pill of icon buttons in the
/// editor toolbar's keyboard-down style, centred at the bottom of the
/// screen. Placed as a Scaffold's floating action button with
/// [FloatingActionButtonLocation.centerFloat], it sits above gesture
/// navigation. Swapping [child] for one with a different key animates
/// between them (e.g. actions ⇄ Save/Share). Built once so Settings › Tags,
/// and later Timeline and Gallery multi-select, look the same.
class ActionPill extends StatelessWidget {
  const ActionPill({super.key, required this.child});

  final Widget child;

  /// Where a Scaffold should put the pill.
  static const location = FloatingActionButtonLocation.centerFloat;

  /// Room to leave under a list so its last row can scroll above the pill.
  static const double clearance = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      shape: const StadiumBorder(),
      elevation: 3,
      shadowColor: theme.shadowColor.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: IconTheme.merge(
        data: IconThemeData(color: theme.colorScheme.primary),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              height: 48,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
