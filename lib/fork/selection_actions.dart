// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/bulk_entry_actions.dart';
import 'package:daily_you/fork/entry_share.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Buttons on the bar shown while entries are selected (Gallery and
/// Timeline). Select all is always there; Settings › Appearance ›
/// Selection actions turns the rest on or off.
enum SelectionAction { mood, tags, share, delete }

class SelectionActions {
  static Set<SelectionAction> get _hidden {
    try {
      final names = (jsonDecode(
              ConfigProvider.instance.get(Settings.selectionActionsHidden))
          as List);
      return {
        for (final action in SelectionAction.values)
          if (names.contains(action.name)) action,
      };
    } catch (_) {
      return {};
    }
  }

  static bool isShown(SelectionAction action) {
    // Sharing out goes through Android's share sheet
    if (action == SelectionAction.share && !Platform.isAndroid) return false;
    return !_hidden.contains(action);
  }

  static Future<void> setShown(SelectionAction action, bool shown) async {
    final hidden = _hidden;
    shown ? hidden.remove(action) : hidden.add(action);
    await ConfigProvider.instance.set(Settings.selectionActionsHidden,
        jsonEncode([for (final action in hidden) action.name]));
  }

  static IconData iconOf(SelectionAction action) => switch (action) {
        SelectionAction.mood => Icons.mood_rounded,
        SelectionAction.tags => Icons.sell_rounded,
        SelectionAction.share => Icons.share_rounded,
        SelectionAction.delete => Icons.delete_rounded,
      };

  static String labelOf(BuildContext context, SelectionAction action) {
    final l10n = AppLocalizations.of(context)!;
    return switch (action) {
      SelectionAction.mood => l10n.bulkChangeMood,
      SelectionAction.tags => l10n.bulkChangeTags,
      SelectionAction.share => l10n.shareEntry,
      SelectionAction.delete =>
        MaterialLocalizations.of(context).deleteButtonTooltip,
    };
  }
}

/// The app bar shown in place of the usual one while entries are selected:
/// ✕, "3 selected", Select all, then the chosen actions.
class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SelectionAppBar({
    super.key,
    required this.selected,
    required this.all,
    required this.onClear,
    required this.onSelectAll,
    required this.onDone,
  });

  /// Selected entries, and every entry Select all would pick.
  final List<Entry> selected;
  final List<Entry> all;
  final VoidCallback onClear;
  final VoidCallback onSelectAll;

  /// Called after an action changed or deleted the selection, with the
  /// message to show.
  final void Function(String message) onDone;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _run(BuildContext context, SelectionAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final entries = List<Entry>.from(selected);
    if (entries.isEmpty) return;
    switch (action) {
      case SelectionAction.mood:
        final chosen = await BulkEntryActions.pickMood(context, entries.length);
        if (chosen == null || !context.mounted) return;
        await BulkEntryActions.setMood(entries, chosen.mood);
        onDone(l10n.bulkMoodChanged);
      case SelectionAction.tags:
        final (add, remove) = await BulkEntryActions.pickTags(context, entries);
        if (add.isEmpty && remove.isEmpty) return;
        await BulkEntryActions.changeTags(entries, add, remove);
        onDone(l10n.bulkTagsUpdated);
      case SelectionAction.share:
        await EntryShare.share(context, entries);
      case SelectionAction.delete:
        final deletedText = l10n.bulkDeleted(entries.length);
        if (!await BulkEntryActions.confirmDelete(context, entries.length)) {
          return;
        }
        await BulkEntryActions.delete(entries);
        onDone(deletedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the Selection actions setting changes
    Provider.of<ConfigProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
        icon: const Icon(Icons.close_rounded),
        onPressed: onClear,
      ),
      title: Text(l10n.bulkSelected(selected.length)),
      actions: [
        IconButton(
          tooltip: MaterialLocalizations.of(context).selectAllButtonLabel,
          icon: const Icon(Icons.select_all_rounded),
          onPressed: selected.length == all.length ? null : onSelectAll,
        ),
        for (final action in SelectionAction.values)
          if (SelectionActions.isShown(action))
            IconButton(
              tooltip: SelectionActions.labelOf(context, action),
              icon: Icon(SelectionActions.iconOf(action)),
              onPressed: () => _run(context, action),
            ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Settings › Appearance › Selection actions.
class SelectionActionsSettingsPage extends StatelessWidget {
  const SelectionActionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ConfigProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSelectionActions)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.settingsSelectionActionsHint,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          for (final action in SelectionAction.values)
            if (action != SelectionAction.share || Platform.isAndroid)
              SwitchListTile(
                secondary: Icon(SelectionActions.iconOf(action)),
                title: Text(SelectionActions.labelOf(context, action)),
                value: SelectionActions.isShown(action),
                onChanged: (value) => SelectionActions.setShown(action, value),
              ),
        ],
      ),
    );
  }
}

/// A tick and outline on a selected card (Gallery and Timeline).
class SelectionOutline extends StatelessWidget {
  const SelectionOutline({
    super.key,
    required this.selected,
    required this.child,
    this.showTick = false,
    this.radius = 12,
  });

  final bool selected;
  final bool showTick;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!selected) return child;
    final colorScheme = Theme.of(context).colorScheme;
    final outlined = Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.primary, width: 3),
      ),
      child: child,
    );
    if (!showTick) return outlined;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        outlined,
        PositionedDirectional(
          top: 8,
          end: 8,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.check_rounded,
                size: 18, color: colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}
