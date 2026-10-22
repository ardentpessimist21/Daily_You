// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:convert';

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

/// A button the user made in Settings > Editor buttons: tapping it inserts
/// [text] (plain words or Markdown) at the cursor.
@immutable
class CustomEditorButton {
  const CustomEditorButton({
    required this.id,
    required this.name,
    required this.symbol,
    required this.text,
  });

  /// Stable, never reused, so the saved order and hidden list can find it.
  final String id;

  /// Shown in settings and when the button is long-pressed.
  final String name;

  /// What the button shows on the toolbar: an emoji or a couple of letters.
  final String symbol;

  /// What a tap inserts.
  final String text;

  /// The button's token in the saved toolbar order.
  String get token => '${EditorButtons.customPrefix}$id';

  Map<String, String> toJson() =>
      {'id': id, 'name': name, 'symbol': symbol, 'text': text};

  static CustomEditorButton? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final text = json['text'];
    if (id is! String || id.isEmpty || text is! String) return null;
    final name = json['name'];
    final symbol = json['symbol'];
    return CustomEditorButton(
      id: id,
      name: name is String ? name : '',
      symbol: symbol is String ? symbol : '',
      text: text,
    );
  }

  CustomEditorButton copyWith({String? name, String? symbol, String? text}) =>
      CustomEditorButton(
        id: id,
        name: name ?? this.name,
        symbol: symbol ?? this.symbol,
        text: text ?? this.text,
      );

  @override
  bool operator ==(Object other) =>
      other is CustomEditorButton &&
      other.id == id &&
      other.name == name &&
      other.symbol == symbol &&
      other.text == text;

  @override
  int get hashCode => Object.hash(id, name, symbol, text);
}

/// One slot on the toolbar: a built-in button or one of the user's own.
@immutable
class ToolbarItem {
  const ToolbarItem.builtIn(EditorButton this.builtIn) : custom = null;
  const ToolbarItem.custom(CustomEditorButton this.custom) : builtIn = null;

  final EditorButton? builtIn;
  final CustomEditorButton? custom;

  /// How this slot is saved in the toolbar order and hidden list.
  String get token => builtIn?.name ?? custom!.token;

  @override
  bool operator ==(Object other) =>
      other is ToolbarItem && other.token == token;

  @override
  int get hashCode => token.hashCode;
}

class EditorButtons {
  /// The entry open in the editor, so the link picker can leave it out.
  static int? editingEntryId;

  /// Saved tokens starting with this mark one of the user's own buttons.
  static const String customPrefix = 'custom:';

  /// 📍 lives with Tags, Attach and Camera (the + menu with the keyboard
  /// up, the bottom bar with it down), so it's never a formatting button.
  static bool _isFormatting(EditorButton button) =>
      button != EditorButton.place;

  static final List<EditorButton> defaultToolbar =
      EditorButton.values.where(_isFormatting).toList(growable: false);
  static const List<EditorButton> defaultPopup = [
    EditorButton.bold,
    EditorButton.italic,
    EditorButton.highlight,
    EditorButton.link,
  ];

  static List<String> _tokens(String stored) =>
      stored.split(',').where((token) => token.isNotEmpty).toList();

  static List<EditorButton> _parse(String stored) => _tokens(stored)
      .map((name) => EditorButton.values
          .where((button) => button.name == name && _isFormatting(button))
          .firstOrNull)
      .nonNulls
      .toList();

  static String _store(Iterable<EditorButton> buttons) =>
      buttons.map((button) => button.name).join(',');

  /// The user's own buttons, in the order they were made.
  static List<CustomEditorButton> customButtons() {
    final stored = ConfigProvider.instance.get(Settings.editorCustomButtons);
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return [];
      return decoded.map(CustomEditorButton.fromJson).nonNulls.toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveCustom(List<CustomEditorButton> buttons) =>
      ConfigProvider.instance.set(Settings.editorCustomButtons,
          jsonEncode([for (final button in buttons) button.toJson()]));

  /// A new button with an id no other button has had.
  static CustomEditorButton newCustomButton(
      {required String name, required String symbol, required String text}) {
    final taken = customButtons().map((button) => button.id).toSet();
    var id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    while (taken.contains(id)) {
      id = '${id}x';
    }
    return CustomEditorButton(id: id, name: name, symbol: symbol, text: text);
  }

  /// Adds [button], or replaces the button with the same id. New buttons
  /// go to the end of the toolbar.
  static Future<void> saveCustomButton(CustomEditorButton button) async {
    final buttons = customButtons();
    final index = buttons.indexWhere((existing) => existing.id == button.id);
    if (index == -1) {
      buttons.add(button);
    } else {
      buttons[index] = button;
    }
    await _saveCustom(buttons);
  }

  /// Removes the button, and its place in the toolbar order.
  static Future<void> deleteCustomButton(CustomEditorButton button) async {
    await _saveCustom(
        customButtons().where((existing) => existing.id != button.id).toList());
    final config = ConfigProvider.instance;
    String without(String stored) =>
        _tokens(stored).where((token) => token != button.token).join(',');
    await config.set(Settings.editorToolbarOrder,
        without(config.get(Settings.editorToolbarOrder)));
    await config.set(Settings.editorToolbarHidden,
        without(config.get(Settings.editorToolbarHidden)));
  }

  /// Toolbar order, including hidden buttons. Buttons added later (new
  /// built-ins, or buttons the user just made) are appended so they're
  /// never lost.
  static List<ToolbarItem> toolbarOrder() {
    final custom = {
      for (final button in customButtons()) button.token: button,
    };
    final order = <ToolbarItem>[];
    for (final token
        in _tokens(ConfigProvider.instance.get(Settings.editorToolbarOrder))) {
      final item = custom.containsKey(token)
          ? ToolbarItem.custom(custom[token]!)
          : switch (_parse(token)) {
              [final button] => ToolbarItem.builtIn(button),
              _ => null,
            };
      if (item != null && !order.contains(item)) order.add(item);
    }
    for (final button in defaultToolbar) {
      final item = ToolbarItem.builtIn(button);
      if (!order.contains(item)) order.add(item);
    }
    for (final button in custom.values) {
      final item = ToolbarItem.custom(button);
      if (!order.contains(item)) order.add(item);
    }
    return order;
  }

  /// Tokens of the hidden toolbar slots.
  static Set<String> toolbarHidden() =>
      _tokens(ConfigProvider.instance.get(Settings.editorToolbarHidden))
          .toSet();

  static List<EditorButton> popupItems() {
    final stored = ConfigProvider.instance.get(Settings.editorPopupItems);
    if (stored == 'default') return List.of(defaultPopup);
    return _parse(stored);
  }

  static Future<void> saveToolbar(
      List<ToolbarItem> order, Set<String> hidden) async {
    await ConfigProvider.instance.set(
        Settings.editorToolbarOrder, order.map((item) => item.token).join(','));
    await ConfigProvider.instance
        .set(Settings.editorToolbarHidden, hidden.join(','));
  }

  static Future<void> savePopup(List<EditorButton> items) =>
      ConfigProvider.instance.set(Settings.editorPopupItems, _store(items));

  /// Puts the order, hidden buttons and popup back to how they started.
  /// The user's own buttons stay, at the end of the toolbar.
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
        EditorButton.highlight => l10n.editorStrikethrough,
        EditorButton.quote => l10n.editorDivider,
        EditorButton.link => l10n.editorPasteLink,
        EditorButton.bold ||
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
      case EditorButton.highlight:
        wrapSelection(controller, '~~');
      case EditorButton.quote:
        insertOnOwnLine(controller, '---');
      case EditorButton.link:
        await pasteLink(controller);
      case EditorButton.bold:
      case EditorButton.italic:
      case EditorButton.strikethrough:
      case EditorButton.place:
        break;
    }
  }

  /// Inserts the time on its own line, e.g. "11:55 AM", and leaves the
  /// cursor on the line below. Adds the date, with its year, when the entry
  /// isn't from today (or [alwaysDate] is set), e.g. "Oct 18, 2026 · 9:10 AM".
  static void insertTimestamp(
      BuildContext context, TextEditingController controller,
      {DateTime? entryDate, bool alwaysDate = false}) {
    final now = DateTime.now();
    final locale = TimeManager.currentLocale(context);
    final time = TimeManager.localizedTimeFormat(context, locale).format(now);
    final showDate = alwaysDate ||
        (entryDate != null && !TimeManager.isSameDay(entryDate, now));
    final stamp = showDate ? '${dateWithYear(now, locale)} · $time' : time;
    insertOnOwnLine(controller, stamp);
  }

  /// The date part of a timestamp, e.g. "Oct 18, 2026".
  static String dateWithYear(DateTime date, String? locale) =>
      DateFormat.yMMMd(locale).format(date);

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
      for (final item in toolbarOrder())
        if (!hidden.contains(item.token))
          switch (item) {
            ToolbarItem(builtIn: final button?) => ToolbarAction(
                icon: icon(button),
                onPressed: () => tap(button, context, controller,
                    entryDate: entryDate?.call()),
                longPressLabel: holdLabel(l10n, button),
                onLongPress: holdLabel(l10n, button) == null
                    ? null
                    : () => hold(button, context, controller,
                        entryDate: entryDate?.call()),
              ),
            ToolbarItem(custom: final custom?) => ToolbarAction(
                icon: CustomButtonIcon(custom),
                onPressed: () => insertCustom(controller, custom),
              ),
            _ => throw StateError('Empty toolbar slot'),
          },
    ];
  }

  /// Inserts a custom button's text at the cursor, replacing any selection.
  static void insertCustom(
      TextEditingController controller, CustomEditorButton button) {
    if (button.text.isEmpty) return;
    insertAtCursor(controller, button.text);
  }

  /// A slot's icon, for settings rows.
  static Widget itemIcon(ToolbarItem item) => switch (item) {
        ToolbarItem(builtIn: final button?) => icon(button),
        ToolbarItem(custom: final custom?) => CustomButtonIcon(custom),
        _ => const SizedBox.shrink(),
      };

  /// A slot's name, for settings rows.
  static String itemLabel(AppLocalizations l10n, ToolbarItem item) =>
      switch (item) {
        ToolbarItem(builtIn: final button?) => label(l10n, button),
        ToolbarItem(custom: final custom?) => custom.name.trim().isEmpty
            ? l10n.editorCustomButtonUnnamed
            : custom.name.trim(),
        _ => '',
      };
}

/// A custom button's symbol, drawn like an icon: same colour, about the
/// same size, and never wider than the button.
class CustomButtonIcon extends StatelessWidget {
  const CustomButtonIcon(this.button, {super.key});

  final CustomEditorButton button;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24;
    final symbol = button.symbol.trim().isNotEmpty
        ? button.symbol.trim()
        : (button.name.trim().isNotEmpty
            ? button.name.trim().characters.first.toUpperCase()
            : '•');
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          symbol,
          maxLines: 1,
          style: TextStyle(
            color: iconTheme.color,
            fontSize: size * 0.8,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
