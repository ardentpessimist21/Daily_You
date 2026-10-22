// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Keeps the text selection popup (Cut · Copy · Paste … ⋮) where it can be
/// reached.
///
/// The popup normally sits above the start of the selection, or below its
/// end when there's no room above. After Select all on a long entry, the
/// start is far above the screen and the end is down by the keyboard and
/// the toolbar, so the popup ended up off screen with its ⋮ out of reach.
class SelectionMenu {
  /// Room the popup needs: its height plus the gap to the selection.
  static const double popupRoom = 56;

  /// The editor's toolbar dock at the bottom covers about this much.
  static const double dockAllowance = 72;

  /// [anchors] moved so the popup lands inside the visible area of [media]:
  /// below the app bar and above the keyboard and toolbar dock.
  static TextSelectionToolbarAnchors keepOnScreen(
      MediaQueryData media, TextSelectionToolbarAnchors anchors) {
    final top = media.padding.top + kToolbarHeight;
    final bottom = media.size.height - media.viewInsets.bottom - dockAllowance;
    if (bottom - top < popupRoom * 2) return anchors;

    final primary = anchors.primaryAnchor;
    final secondary = anchors.secondaryAnchor;
    return TextSelectionToolbarAnchors(
      // Start hidden above the screen: put the popup at the top instead
      primaryAnchor:
          primary.dy < top ? Offset(primary.dx, top + popupRoom) : primary,
      // End down by the keyboard: leave room for the popup below it
      secondaryAnchor: secondary == null
          ? null
          : Offset(secondary.dx,
              math.max(top, math.min(secondary.dy, bottom - popupRoom))),
    );
  }

  /// [keepOnScreen] for the screen around [context].
  static TextSelectionToolbarAnchors of(
          BuildContext context, TextSelectionToolbarAnchors anchors) =>
      keepOnScreen(MediaQuery.of(context), anchors);
}
