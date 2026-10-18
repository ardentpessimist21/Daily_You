// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' show lerpDouble;

import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_entry.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_morph.dart';
import 'package:material_ui/material_ui.dart';

class ActionBarPill extends StatelessWidget {
  static const double _iconTintHandoff = 0.5;

  final DockMetrics metrics;
  final ToolbarEntrySplit split;
  final bool showingMainActions;
  final void Function(BuildContext buttonContext) onShowOverflow;

  const ActionBarPill({
    super.key,
    required this.metrics,
    required this.split,
    required this.showingMainActions,
    required this.onShowOverflow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTint =
        metrics.progress < _iconTintHandoff ? theme.colorScheme.primary : null;

    return Material(
      // Animated frame by frame
      animationDuration: Duration.zero,
      color: theme.colorScheme.primaryContainer
          .withValues(alpha: 1 - metrics.progress),
      shape: RoundedRectangleBorder(borderRadius: metrics.borderRadius),
      elevation: metrics.pillElevation,
      shadowColor: theme.shadowColor.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: toolbarMorphDuration,
        curve: toolbarMorphCurve,
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsets.all(metrics.pillPadding),
          child: IconTheme.merge(
            data: IconThemeData(color: iconTint),
            child: MorphContent(
              child: KeyedSubtree(
                key: ValueKey(showingMainActions),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in split.visible)
                        entry.build(context, null),
                      if (split.hasOverflow)
                        Builder(
                          builder: (buttonContext) => ToolbarIconButton(
                            size: metrics.buttonSize,
                            icon: const Icon(Icons.more_horiz_rounded),
                            onPressed: () => onShowOverflow(buttonContext),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DockSurface extends StatelessWidget {
  final DockMetrics metrics;
  final AlignmentGeometry alignment;
  final double barWidth;
  final double pillWidth;

  const DockSurface({
    super.key,
    required this.metrics,
    required this.alignment,
    required this.barWidth,
    required this.pillWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: lerpDouble(barWidth, pillWidth, 1 - metrics.progress),
        height: metrics.barHeight,
        child: Material(
          animationDuration: Duration.zero,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHigh
              .withValues(alpha: metrics.progress),
          shape: RoundedRectangleBorder(borderRadius: metrics.borderRadius),
          elevation: 0,
        ),
      ),
    );
  }
}

class ToolbarIconButton extends StatelessWidget {
  final double size;
  final Widget icon;
  final VoidCallback? onPressed;

  /// Optional alternative action; [hasAlternative] marks it with a dot
  final VoidCallback? onLongPress;
  final bool hasAlternative;

  const ToolbarIconButton({
    super.key,
    required this.size,
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    this.hasAlternative = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      icon: icon,
      onPressed: onPressed,
    );
    return SizedBox(
      width: size,
      height: size,
      child: onLongPress == null
          ? button
          : GestureDetector(
              onLongPress: onLongPress,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  button,
                  if (hasAlternative)
                    Positioned(
                      bottom: size * 0.12,
                      child: IgnorePointer(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: IconTheme.of(context)
                                .color
                                ?.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// A small label just above a toolbar button, used to name what a
/// long-press inserted.
void showToolbarHint(BuildContext buttonContext, String text) {
  final overlay = Overlay.maybeOf(buttonContext);
  final box = buttonContext.findRenderObject() as RenderBox?;
  if (overlay == null || box == null || !box.hasSize) return;
  final overlayBox = overlay.context.findRenderObject() as RenderBox;
  final topCenter =
      box.localToGlobal(box.size.topCenter(Offset.zero), ancestor: overlayBox);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Positioned(
        left: 0,
        right: 0,
        top: topCenter.dy - 40,
        child: IgnorePointer(
          child: Align(
            alignment: Alignment(
                (topCenter.dx / overlayBox.size.width) * 2 - 1, 0),
            child: Material(
              color: colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(text,
                    style: TextStyle(
                        color: colorScheme.onInverseSurface, fontSize: 13)),
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1200), () {
    if (entry.mounted) entry.remove();
  });
}
