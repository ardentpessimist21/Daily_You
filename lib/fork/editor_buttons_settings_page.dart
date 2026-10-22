// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/editor_buttons.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/icon_picker_dialog.dart';
import 'package:daily_you/widgets/settings_header.dart';
import 'package:material_ui/material_ui.dart';

/// Settings > Appearance > Editor buttons: the toolbar's order and hidden
/// buttons, the user's own buttons, and which formatting options the
/// selection popup offers.
class EditorButtonsSettingsPage extends StatefulWidget {
  const EditorButtonsSettingsPage({super.key});

  @override
  State<EditorButtonsSettingsPage> createState() =>
      _EditorButtonsSettingsPageState();
}

class _EditorButtonsSettingsPageState extends State<EditorButtonsSettingsPage> {
  late List<ToolbarItem> _toolbar;
  late Set<String> _hidden;
  // Popup: every button, ticked ones first in the user's order
  late List<EditorButton> _popupOrder;
  late Set<EditorButton> _popupOn;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _toolbar = EditorButtons.toolbarOrder();
    _hidden = EditorButtons.toolbarHidden();
    final ticked = EditorButtons.popupItems();
    _popupOn = ticked.toSet();
    _popupOrder = [
      ...ticked,
      for (final button in EditorButtons.defaultToolbar)
        if (!ticked.contains(button)) button,
    ];
  }

  Future<void> _saveToolbar() => EditorButtons.saveToolbar(_toolbar, _hidden);

  Future<void> _savePopup() =>
      EditorButtons.savePopup(_popupOrder.where(_popupOn.contains).toList());

  Widget _rowIcon(Widget icon) =>
      SizedBox(width: 24, height: 24, child: Center(child: icon));

  Future<void> _editCustom(CustomEditorButton? existing) async {
    final result = await showAppDialog<_CustomButtonResult>(
      context: context,
      builder: (_) => _CustomButtonDialog(existing: existing),
    );
    if (result == null || !mounted) return;
    if (result.delete) {
      if (existing != null) await EditorButtons.deleteCustomButton(existing);
    } else {
      final button = existing == null
          ? EditorButtons.newCustomButton(
              name: result.name,
              symbol: result.symbol,
              text: result.text,
              materialIcon: result.materialIcon)
          : existing.copyWith(
              name: result.name,
              symbol: result.symbol,
              text: result.text,
              materialIcon: result.materialIcon);
      await EditorButtons.saveCustomButton(button);
      // Keep the order saved so a new button stays where it lands
      await EditorButtons.saveToolbar(
          EditorButtons.toolbarOrder(), EditorButtons.toolbarHidden());
    }
    if (mounted) setState(_load);
  }

  Future<void> _editActions(EditorButton button) async {
    final result = await showAppDialog<(EditorAction, EditorAction)>(
      context: context,
      builder: (_) => _ButtonActionsDialog(button: button),
    );
    if (result == null || !mounted) return;
    await EditorButtons.saveActions(button, result.$1, result.$2);
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsEditorButtons),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.editorButtonsReset,
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () async {
              await EditorButtons.resetAll();
              setState(_load);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SettingsHeader(text: l10n.editorButtonsToolbar),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
                '${l10n.editorButtonsToolbarHint} ${l10n.editorButtonsActionsHint}',
                style: TextStyle(color: muted)),
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                _toolbar.insert(newIndex, _toolbar.removeAt(oldIndex));
              });
              _saveToolbar();
            },
            children: [
              for (final (index, item) in _toolbar.indexed)
                _toolbarRow(context, l10n, muted, index, item),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.editorButtonsCustomHint,
                style: TextStyle(color: muted)),
          ),
          ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(left: 32),
              child: _rowIcon(const Icon(Icons.add_rounded)),
            ),
            title: Text(l10n.editorCustomButtonAdd),
            onTap: () => _editCustom(null),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SettingsHeader(text: l10n.editorButtonsPopup),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.editorButtonsPopupHint,
                style: TextStyle(color: muted)),
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                _popupOrder.insert(newIndex, _popupOrder.removeAt(oldIndex));
              });
              _savePopup();
            },
            children: [
              for (final (index, button) in _popupOrder.indexed)
                CheckboxListTile(
                  key: ValueKey('popup-${button.name}'),
                  value: _popupOn.contains(button),
                  secondary: ReorderableDragStartListener(
                    index: index,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.drag_indicator_rounded, color: muted),
                      const SizedBox(width: 8),
                      _rowIcon(EditorButtons.icon(button)),
                    ]),
                  ),
                  title: Text(EditorButtons.label(l10n, button)),
                  onChanged: (on) {
                    setState(() => on == true
                        ? _popupOn.add(button)
                        : _popupOn.remove(button));
                    _savePopup();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolbarRow(BuildContext context, AppLocalizations l10n, Color muted,
      int index, ToolbarItem item) {
    final hidden = _hidden.contains(item.token);
    final custom = item.custom;
    final builtIn = item.builtIn;
    final hold =
        builtIn == null ? null : EditorButtons.holdLabel(l10n, builtIn);
    final tapChanged = builtIn != null &&
        EditorButtons.tapAction(builtIn) != EditorButtons.defaultTap(builtIn);
    final String? actions = builtIn == null
        ? null
        : tapChanged
            ? l10n.editorButtonsTapHold(
                EditorButtons.actionLabel(
                    l10n, EditorButtons.tapAction(builtIn)),
                hold ?? l10n.editorNothing)
            : (hold == null ? null : l10n.editorButtonsHold(hold));
    return ListTile(
      key: ValueKey('toolbar-${item.token}'),
      leading: ReorderableDragStartListener(
        index: index,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.drag_indicator_rounded, color: muted),
          const SizedBox(width: 8),
          Opacity(
              opacity: hidden ? 0.4 : 1,
              child: _rowIcon(EditorButtons.itemIcon(item))),
        ]),
      ),
      title: Text(EditorButtons.itemLabel(l10n, item),
          style: TextStyle(color: hidden ? muted : null)),
      subtitle: custom != null
          ? Text(custom.text.replaceAll('\n', ' ⏎ '),
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : (actions == null ? null : Text(actions)),
      onTap: custom != null
          ? () => _editCustom(custom)
          : () => _editActions(builtIn!),
      trailing: IconButton(
        tooltip: EditorButtons.itemLabel(l10n, item),
        icon: Icon(
            hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded),
        onPressed: () {
          setState(() =>
              hidden ? _hidden.remove(item.token) : _hidden.add(item.token));
          _saveToolbar();
        },
      ),
    );
  }
}

class _CustomButtonResult {
  const _CustomButtonResult(this.name, this.symbol, this.text,
      {this.materialIcon = false})
      : delete = false;
  const _CustomButtonResult.delete()
      : name = '',
        symbol = '',
        text = '',
        materialIcon = false,
        delete = true;

  final String name;
  final String symbol;
  final String text;
  final bool materialIcon;
  final bool delete;
}

/// Chooses what a tap and a long-press on one built-in button do.
class _ButtonActionsDialog extends StatefulWidget {
  const _ButtonActionsDialog({required this.button});

  final EditorButton button;

  @override
  State<_ButtonActionsDialog> createState() => _ButtonActionsDialogState();
}

class _ButtonActionsDialogState extends State<_ButtonActionsDialog> {
  late EditorAction _tap = EditorButtons.tapAction(widget.button);
  late EditorAction _hold = EditorButtons.holdAction(widget.button);

  Widget _picker(AppLocalizations l10n, String label, EditorAction value,
          List<EditorAction> choices, ValueChanged<EditorAction> onChanged) =>
      DropdownButtonFormField<EditorAction>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final action in choices)
            DropdownMenuItem(
              value: action,
              child: Row(children: [
                SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(child: EditorButtons.actionIcon(action))),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(EditorButtons.actionLabel(l10n, action),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
        ],
        onChanged: (action) {
          if (action != null) setState(() => onChanged(action));
        },
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final button = widget.button;
    return AlertDialog(
      title: Text(EditorButtons.label(l10n, button)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _picker(l10n, l10n.editorButtonTap, _tap, EditorButtons.tapChoices,
              (action) => _tap = action),
          const SizedBox(height: 16),
          _picker(l10n, l10n.editorButtonHold, _hold, EditorButtons.holdChoices,
              (action) => _hold = action),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, (
            EditorButtons.defaultTap(button),
            EditorButtons.defaultHold(button)
          )),
          child: Text(l10n.editorButtonDefaults),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_tap, _hold)),
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}

/// Makes or edits one custom button: its name, what it shows, and the
/// text it inserts.
class _CustomButtonDialog extends StatefulWidget {
  const _CustomButtonDialog({this.existing});

  final CustomEditorButton? existing;

  @override
  State<_CustomButtonDialog> createState() => _CustomButtonDialogState();
}

class _CustomButtonDialogState extends State<_CustomButtonDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _symbol =
      TextEditingController(text: widget.existing?.symbol ?? '');
  late final TextEditingController _text =
      TextEditingController(text: widget.existing?.text ?? '');
  // A picked Material icon's key; null when the button shows _symbol text
  late String? _iconKey =
      widget.existing?.materialIcon == true ? widget.existing!.symbol : null;

  Future<void> _pickIcon() async {
    final result = await showAppDialog<IconPickerResult>(
      context: context,
      builder: (context) => IconPickerDialog(
          previewColor: Theme.of(context).colorScheme.onSurface),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.type == TagIconType.materialIcon) {
        _iconKey = result.value;
      } else {
        _iconKey = null;
        _symbol.text = result.value;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _symbol.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final existing = widget.existing;
    return AlertDialog(
      title: Text(existing == null
          ? l10n.editorCustomButtonAdd
          : l10n.editorCustomButtonEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.editorCustomButtonName,
                hintText: l10n.editorCustomButtonNameHint,
              ),
            ),
            const SizedBox(height: 12),
            if (_iconKey != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InputDecorator(
                  decoration:
                      InputDecoration(labelText: l10n.editorCustomButtonIcon),
                  child: Row(children: [
                    Icon(lookupTagIcon(_iconKey) ?? Icons.label_rounded),
                    const Spacer(),
                    IconButton(
                      tooltip: l10n.editorCustomButtonPickIcon,
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: _pickIcon,
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).deleteButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _iconKey = null),
                    ),
                  ]),
                ),
              )
            else
              TextField(
                controller: _symbol,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: l10n.editorCustomButtonSymbol,
                  hintText: l10n.editorCustomButtonSymbolHint,
                  suffixIcon: IconButton(
                    tooltip: l10n.editorCustomButtonPickIcon,
                    icon: const Icon(Icons.interests_rounded),
                    onPressed: _pickIcon,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            TextField(
              controller: _text,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l10n.editorCustomButtonText,
                hintText: l10n.editorCustomButtonTextHint,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (existing != null)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _CustomButtonResult.delete()),
            child: Text(l10n.editorCustomButtonDelete),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _text.text.isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  _CustomButtonResult(_name.text.trim(),
                      _iconKey ?? _symbol.text.trim(), _text.text,
                      materialIcon: _iconKey != null)),
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}
