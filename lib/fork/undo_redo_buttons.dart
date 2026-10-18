// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Undo and redo for an editor's top bar; greyed out when there's nothing
/// to undo or redo. Text changes only, as before.
class UndoRedoButtons extends StatelessWidget {
  const UndoRedoButtons({super.key, required this.controller});

  final UndoHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<UndoHistoryValue>(
      valueListenable: controller,
      builder: (context, value, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.editorUndo,
            icon: const Icon(Icons.undo_rounded),
            onPressed: value.canUndo ? controller.undo : null,
          ),
          IconButton(
            tooltip: l10n.editorRedo,
            icon: const Icon(Icons.redo_rounded),
            onPressed: value.canRedo ? controller.redo : null,
          ),
        ],
      ),
    );
  }
}
