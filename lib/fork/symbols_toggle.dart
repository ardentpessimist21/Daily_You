// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// The `#` in the editor's top bar: shows or hides formatting symbols, and
/// remembers the choice (the same switch as in Settings → Appearance).
/// A plain `#` means symbols are hidden; a crossed-out `#` means showing.
class SymbolsToggleButton extends StatelessWidget {
  const SymbolsToggleButton({super.key, this.onChanged});

  /// Called after the setting changes, so the editor can redraw.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context);
    final hidden = config.get(Settings.hideFormattingSymbols);
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: hidden ? l10n.editorShowSymbols : l10n.editorHideSymbols,
      icon: _HashIcon(crossedOut: !hidden),
      onPressed: () async {
        await config.set(Settings.hideFormattingSymbols, !hidden);
        onChanged?.call();
      },
    );
  }
}

class _HashIcon extends StatelessWidget {
  const _HashIcon({required this.crossedOut});

  final bool crossedOut;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        foregroundPainter: _SlashPainter(crossedOut ? color : null),
        child: const Icon(Icons.tag_rounded),
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  _SlashPainter(this.color);

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final color = this.color;
    if (color == null) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.12, size.height * 0.12),
        Offset(size.width * 0.88, size.height * 0.88), paint);
  }

  @override
  bool shouldRepaint(_SlashPainter oldDelegate) => oldDelegate.color != color;
}
