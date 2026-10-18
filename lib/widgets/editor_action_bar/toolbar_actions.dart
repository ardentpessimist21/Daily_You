// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/fork/editor_buttons.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_menu_action.dart';
import 'package:material_ui/material_ui.dart';

@immutable
class ToolbarAction {
  final Widget icon;
  final FutureOr<void> Function()? onPressed;

  final List<ToolbarMenuAction>? menu;

  /// For actions that may launch an external activity. Focus must be manually restored
  final bool mayLeaveApp;

  /// An alternative action on long-press, named by [longPressLabel]
  final FutureOr<void> Function()? onLongPress;
  final String? longPressLabel;

  const ToolbarAction({
    required this.icon,
    this.onPressed,
    this.menu,
    this.mayLeaveApp = false,
    this.onLongPress,
    this.longPressLabel,
  }) : assert((onPressed == null) != (menu == null),
            'Provide exactly one of onPressed or menu');
}

/// The formatting buttons, in the order and visibility chosen in
/// Settings > Appearance > Editor buttons.
List<ToolbarAction> markdownActions(
    BuildContext context, TextEditingController controller,
    {DateTime Function()? entryDate}) {
  return EditorButtons.toolbarActions(context, controller,
      entryDate: entryDate);
}

Future<void> insertHeader(
    BuildContext context, TextEditingController controller) async {
  final level = await showAppDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var level = 1; level <= 6; level++)
            ListTile(
              title: Text('H$level',
                  style: TextStyle(fontSize: 28 - 2 * level.toDouble())),
              onTap: () => Navigator.pop(context, level),
            ),
        ],
      ),
    ),
  );
  if (level != null) insertLinePrefix(controller, '#' * level);
}
