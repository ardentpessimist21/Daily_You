// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_actions.dart';
import 'package:daily_you/widgets/icons/svg_icon.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Every formatting button the editor offers. The toolbar, the selection
/// popup and the "Editor buttons" settings all read from here.
enum EditorButton {
  timestamp,
  place,
  list,
  checklist,
  heading,
  bold,
  italic,
  highlight,
  strikethrough,
  quote,
  link,
}

class EditorButtons {
  /// The entry open in the editor, so the link picker can leave it out.
  static int? editingEntryId;

  static const List<EditorButton> defaultToolbar = EditorButton.values;
  static const List<EditorButton> defaultPopup = [
    EditorButton.bold,
    EditorButton.italic,
    EditorButton.highlight,
    EditorButton.link,
  ];

  static List<EditorButton> _parse(String stored) => stored
      .split(',')
      .map((name) => EditorButton.values
          .where((button) => button.name == name)
          .firstOrNull)
      .nonNulls
      .toList();

  static String _store(Iterable<EditorButton> buttons) =>
      buttons.map((button) => button.name).join(',');

  /// Toolbar order, including hidden buttons. Buttons added in later
  /// versions are appended so they're never lost.
  static List<EditorButton> toolbarOrder() {
    final stored =
        _parse(ConfigProvider.instance.get(Settings.editorToolbarOrder));
    if (stored.isEmpty) return List.of(defaultToolbar);
    final order = [...stored];
    // 📍 joins a saved order second, after 🕒, as it does by default.
    if (!order.contains(EditorButton.place)) {
      final after = order.indexOf(EditorButton.timestamp);
      order.insert(after + 1, EditorButton.place);
    }
    return [
      ...order,
      for (final button in defaultToolbar)
        if (!order.contains(button)) button,
    ];
  }

  static Set<EditorButton> toolbarHidden() =>
      _parse(ConfigProvider.instance.get(Settings.editorToolbarHidden)).toSet();

  static List<EditorButton> popupItems() {
    final stored = ConfigProvider.instance.get(Settings.editorPopupItems);
    if (stored == 'default') return List.of(defaultPopup);
    return _parse(stored);
  }

  static Future<void> saveToolbar(
      List<EditorButton> order, Set<EditorButton> hidden) async {
    await ConfigProvider.instance
        .set(Settings.editorToolbarOrder, _store(order));
    await ConfigProvider.instance
        .set(Settings.editorToolbarHidden, _store(hidden));
  }

  static Future<void> savePopup(List<EditorButton> items) =>
      ConfigProvider.instance.set(Settings.editorPopupItems, _store(items));

  static Future<void> resetAll() async {
    await ConfigProvider.instance.set(Settings.editorToolbarOrder, '');
    await ConfigProvider.instance.set(Settings.editorToolbarHidden, '');
    await ConfigProvider.instance.set(Settings.editorPopupItems, 'default');
  }

  static Widget icon(EditorButton button) => switch (button) {
        EditorButton.timestamp => const Icon(Icons.schedule_rounded),
        EditorButton.place => const Icon(Icons.place_rounded),
        EditorButton.list => const Icon(Icons.format_list_bulleted_rounded),
        EditorButton.checklist => const Icon(Icons.checklist_rounded),
        EditorButton.heading => const Icon(Icons.text_fields_rounded),
        EditorButton.bold => const Icon(Icons.format_bold_rounded),
        EditorButton.italic => const Icon(Icons.format_italic_rounded),
        EditorButton.highlight =>
          const SvgIcon('assets/icons/format_ink_highlighter.svg'),
        EditorButton.strikethrough =>
          const Icon(Icons.format_strikethrough_rounded),
        EditorButton.quote => const Icon(Icons.format_quote_rounded),
        EditorButton.link => const Icon(Icons.link_rounded),
      };

  static String label(AppLocalizations l10n, EditorButton button) =>
      switch (button) {
        EditorButton.timestamp => l10n.editorTimestamp,
        EditorButton.place => l10n.editorPlace,
        EditorButton.list => l10n.editorList,
        EditorButton.checklist => l10n.editorChecklist,
        EditorButton.heading => l10n.editorHeading,
        EditorButton.bold => l10n.editorBold,
        EditorButton.italic => l10n.editorItalic,
        EditorButton.highlight => l10n.editorHighlight,
        EditorButton.strikethrough => l10n.editorStrikethrough,
        EditorButton.quote => l10n.editorQuote,
        EditorButton.link => l10n.editorLink,
      };

  /// What a long-press does instead, or null when a button has no pair.
  static String? holdLabel(AppLocalizations l10n, EditorButton button) =>
      switch (button) {
        EditorButton.timestamp => l10n.editorDateAndTime,
        EditorButton.list => l10n.editorNumberedList,
        EditorButton.checklist => l10n.editorTickedCheckbox,
        EditorButton.heading => l10n.editorHeading1,
        EditorButton.bold => l10n.editorItalic,
        EditorButton.highlight => l10n.editorStrikethrough,
        EditorButton.quote => l10n.editorDivider,
        EditorButton.link => l10n.editorPasteLink,
        EditorButton.italic ||
        EditorButton.strikethrough ||
        EditorButton.place =>
          null,
      };

  static Future<void> tap(EditorButton button, BuildContext context,
      TextEditingController controller,
      {DateTime? entryDate}) async {
    switch (button) {
      case EditorButton.timestamp:
        insertTimestamp(context, controller, entryDate: entryDate);
      case EditorButton.place:
        await Places.showPlaceSheet(context, controller);
      case EditorButton.list:
        insertLinePrefix(controller, '-');
      case EditorButton.checklist:
        insertLinePrefix(controller, '- [ ]');
      case EditorButton.heading:
        await insertHeader(context, controller);
      case EditorButton.bold:
        wrapSelection(controller, '**');
      case EditorButton.italic:
        wrapSelection(controller, '_');
      case EditorButton.highlight:
        wrapSelection(controller, '==');
      case EditorButton.strikethrough:
        wrapSelection(controller, '~~');
      case EditorButton.quote:
        insertLinePrefix(controller, '>');
      case EditorButton.link:
        await EntryLinks.showAddLinkDialog(context, controller,
            currentEntryId: editingEntryId);
    }
  }

  static Future<void> hold(EditorButton button, BuildContext context,
      TextEditingController controller,
      {DateTime? entryDate}) async {
    switch (button) {
      case EditorButton.timestamp:
        insertTimestamp(context, controller,
            entryDate: entryDate, alwaysDate: true);
      case EditorButton.list:
        insertLinePrefix(controller, '1.');
      case EditorButton.checklist:
        insertLinePrefix(controller, '- [x]');
      case EditorButton.heading:
        insertLinePrefix(controller, '#');
      case EditorButton.bold:
        wrapSelection(controller, '_');
      case EditorButton.highlight:
        wrapSelection(controller, '~~');
      case EditorButton.quote:
        insertOnOwnLine(controller, '---');
      case EditorButton.link:
        await pasteLink(controller);
      case EditorButton.italic:
      case EditorButton.strikethrough:
      case EditorButton.place:
        break;
    }
  }

  /// Inserts the time on its own line, e.g. "11:55 AM", and leaves the
  /// cursor on the line below. Adds the date when the entry isn't from today
  /// (or [alwaysDate] is set), e.g. "Oct 18 · 9:10 AM".
  static void insertTimestamp(
      BuildContext context, TextEditingController controller,
      {DateTime? entryDate, bool alwaysDate = false}) {
    final now = DateTime.now();
    final locale = TimeManager.currentLocale(context);
    final time = TimeManager.localizedTimeFormat(context, locale).format(now);
    final showDate = alwaysDate ||
        (entryDate != null && !TimeManager.isSameDay(entryDate, now));
    final stamp =
        showDate ? '${DateFormat.MMMd(locale).format(now)} · $time' : time;
    insertOnOwnLine(controller, stamp);
  }

  /// Inserts [line] as a line of its own at the cursor.
  static void insertOnOwnLine(TextEditingController controller, String line) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final before = text.substring(0, start);
    final after = text.substring(end);
    final lead = before.isEmpty || before.endsWith('\n') ? '' : '\n';
    final trail = after.startsWith('\n') ? '' : '\n';
    final inserted = '$lead$line$trail';
    final cursor = start + inserted.length;
    controller.value = TextEditingValue(
      text: '$before$inserted$after',
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  /// Turns the selection (or nothing) into a link to a copied address. A
  /// copied entry link or Maps place keeps its name.
  static Future<void> pasteLink(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final copied = data?.text?.trim() ?? '';
    if (copied.isEmpty) return;
    final selection = controller.selection;
    final selected = selection.isValid && !selection.isCollapsed
        ? selection.textInside(controller.text)
        : '';
    final tidied = LinkPasteFormatter.tidy(copied, selectedText: selected);
    if (tidied != null) {
      insertAtCursor(controller, tidied);
      return;
    }
    if (EntryLinks.parseMarkdownLink(copied) != null ||
        !EntryLinks.looksLikeAddress(copied)) {
      insertAtCursor(controller, copied);
      return;
    }
    wrapSelection(controller, '[', ']($copied)');
  }

  /// Formatting items for the text selection popup, in the user's order.
  /// Each one closes the popup, then formats the selection.
  static List<ContextMenuButtonItem> popupMenuItems(BuildContext context,
      TextEditingController controller, VoidCallback hidePopup) {
    final l10n = AppLocalizations.of(context)!;
    return [
      for (final button in popupItems())
        ContextMenuButtonItem(
          label: label(l10n, button),
          onPressed: () {
            hidePopup();
            tap(button, context, controller);
          },
        ),
    ];
  }

  /// Toolbar actions in the user's order, without hidden buttons.
  static List<ToolbarAction> toolbarActions(
      BuildContext context, TextEditingController controller,
      {DateTime Function()? entryDate}) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = toolbarHidden();
    return [
      for (final button in toolbarOrder())
        if (!hidden.contains(button))
          ToolbarAction(
            icon: icon(button),
            onPressed: () =>
                tap(button, context, controller, entryDate: entryDate?.call()),
            longPressLabel: holdLabel(l10n, button),
            onLongPress: holdLabel(l10n, button) == null
                ? null
                : () => hold(button, context, controller,
                    entryDate: entryDate?.call()),
          ),
    ];
  }
}
