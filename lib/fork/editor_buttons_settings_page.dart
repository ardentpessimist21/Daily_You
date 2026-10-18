// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/editor_buttons.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/settings_header.dart';
import 'package:material_ui/material_ui.dart';

/// Settings > Appearance > Editor buttons: the toolbar's order and hidden
/// buttons, and which formatting options the selection popup offers.
class EditorButtonsSettingsPage extends StatefulWidget {
  const EditorButtonsSettingsPage({super.key});

  @override
  State<EditorButtonsSettingsPage> createState() =>
      _EditorButtonsSettingsPageState();
}

class _EditorButtonsSettingsPageState extends State<EditorButtonsSettingsPage> {
  late List<EditorButton> _toolbar;
  late Set<EditorButton> _hidden;
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
      for (final button in EditorButton.values)
        if (!ticked.contains(button)) button,
    ];
  }

  Future<void> _saveToolbar() => EditorButtons.saveToolbar(_toolbar, _hidden);

  Future<void> _savePopup() =>
      EditorButtons.savePopup(_popupOrder.where(_popupOn.contains).toList());

  Widget _rowIcon(EditorButton button) => SizedBox(
      width: 24, height: 24, child: Center(child: EditorButtons.icon(button)));

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
            child: Text(l10n.editorButtonsToolbarHint,
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
              for (final (index, button) in _toolbar.indexed)
                ListTile(
                  key: ValueKey('toolbar-${button.name}'),
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.drag_indicator_rounded, color: muted),
                      const SizedBox(width: 8),
                      Opacity(
                          opacity: _hidden.contains(button) ? 0.4 : 1,
                          child: _rowIcon(button)),
                    ]),
                  ),
                  title: Text(EditorButtons.label(l10n, button),
                      style: TextStyle(
                          color: _hidden.contains(button) ? muted : null)),
                  subtitle: switch (EditorButtons.holdLabel(l10n, button)) {
                    null => null,
                    final hold => Text(l10n.editorButtonsHold(hold)),
                  },
                  trailing: IconButton(
                    tooltip: EditorButtons.label(l10n, button),
                    icon: Icon(_hidden.contains(button)
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () {
                      setState(() => _hidden.contains(button)
                          ? _hidden.remove(button)
                          : _hidden.add(button));
                      _saveToolbar();
                    },
                  ),
                ),
            ],
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
                      _rowIcon(button),
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
}
