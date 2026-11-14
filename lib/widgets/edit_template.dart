// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/undo_redo_buttons.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/delete_confirm_dialog.dart';
import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/editor_action_bar/editor_keyboard_session.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/widgets/tag_grouped_chip_list.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class EditTemplate extends StatefulWidget {
  final Template? template;

  const EditTemplate({super.key, this.template});

  @override
  State<EditTemplate> createState() => _EditTemplateState();
}

class _EditTemplateState extends State<EditTemplate> {
  late TextEditingController _nameController;
  late String templateText;

  /// The template's place (3.7.0.50), kept on the template text's hidden
  /// last line like an entry's places. Entries made from the template get
  /// it unless they already have a place.
  List<Place> _places = [];
  late final TagAttachmentSource _tagSource;
  final FocusNode _focusNode = FocusNode();
  final MarkdownPreviewController _textEditingController =
      MarkdownPreviewController();
  final UndoHistoryController _undoController = UndoHistoryController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    final (body, places) =
        EntryLocations.split(widget.template?.text ?? "");
    templateText = body;
    _places = [...places];
    final initialTagIds = widget.template?.id == null
        ? <int>[]
        : TagsProvider.instance
            .getTemplateTagsForTemplate(widget.template!.id!)
            .map((templateTag) => templateTag.tagId)
            .toList();
    _tagSource = TagAttachmentSource(initialTagIds: initialTagIds);
    _textEditingController
        .addListener(() => templateText = _textEditingController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagSource.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  /// The text with the template's place on its hidden last line.
  String get _fullText => EntryLocations.join(templateText, _places);

  /// 📍: pick the template's place. A template has one place, so a new
  /// pick replaces the old one.
  Future<void> _pickPlace() => Places.showPlaceSheet(context, null,
      onPicked: (place) {
        if (!mounted) return;
        setState(() => _places = [place]);
      });

  /// Tapping the place: Name, Map link and Description for this template,
  /// with Remove.
  Future<void> _editPlace(int index) async {
    if (index < 0 || index >= _places.length) return;
    final place = _places[index];
    final l10n = AppLocalizations.of(context)!;
    final result = await showPlaceDialog(
      context,
      title: l10n.placeInTemplate,
      initial: place,
      footnote: l10n.placeInTemplateHint,
      removeLabel: l10n.placeRemove,
    );
    if (result == null || !mounted || index >= _places.length) return;
    if (!identical(_places[index], place)) return;
    setState(() {
      _places = result.removed
          ? ([..._places]..removeAt(index))
          : ([..._places]..[index] = result.place!);
    });
  }

  Future<void> _saveTemplate() async {
    final int templateId;
    if (widget.template == null) {
      final created = await TemplatesProvider.instance.add(Template(
          name: _nameController.text,
          text: _fullText,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now()));
      templateId = created.id!;
    } else {
      final updated = widget.template!.copy(
          name: _nameController.text,
          text: _fullText,
          timeModified: DateTime.now());
      await TemplatesProvider.instance.update(updated);
      templateId = updated.id!;
    }
    await TagsProvider.instance
        .setTemplateTags(templateId, _tagSource.attachedTagIds);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final template = widget.template;
    if (template == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmDialog(
      context,
      message: l10n.deleteTemplateMessage(template.name),
    );
    if (confirmed && mounted) {
      final defaultTemplateId =
          ConfigProvider.instance.get(Settings.defaultTemplate);
      if (defaultTemplateId == template.id) {
        await ConfigProvider.instance.set(Settings.defaultTemplate, -1);
      }
      await TemplatesProvider.instance.remove(template);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openTagPicker() async {
    await showAppDialog(
      context: context,
      builder: (_) =>
          TagPickerDialog(mode: TagPickerMode.attach, source: _tagSource),
    );
  }

  List<ToolbarAction> _buildMainActions() {
    return [
      ToolbarAction(
        icon: const Icon(Icons.today_rounded),
        onPressed: () => insertAtCursor(_textEditingController, '{{date}}'),
      ),
      ToolbarAction(
        icon: const Icon(Icons.access_time_rounded),
        onPressed: () => insertAtCursor(_textEditingController, '{{time}}'),
      ),
      ToolbarAction(
        icon: const Icon(Icons.local_offer_rounded),
        onPressed: _openTagPicker,
      ),
      ToolbarAction(
        icon: const Icon(Icons.place_rounded),
        onPressed: _pickPlace,
        mayLeaveApp: true,
      ),
    ];
  }

  Widget _buildTagChips() {
    return ListenableBuilder(
      listenable: _tagSource,
      builder: (context, _) {
        final attachedIds = _tagSource.attachedTagIds;
        if (attachedIds.isEmpty) return const SizedBox.shrink();
        final tagsProvider = Provider.of<TagsProvider>(context);
        final attachedSet = attachedIds.toSet();
        final tagPool = tagsProvider.tags
            .where((tag) => attachedSet.contains(tag.id))
            .toList();
        final sections = tagsProvider.buildSections('', tagPool: tagPool);
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TagGroupedChipList(
            sections: sections,
            chipBuilder: (tag) => TagChip(
              tag: tag,
              onRemove: () => _tagSource.detach(tag.id!),
            ),
          ),
        );
      },
    );
  }

  Widget saveButton() {
    return IconButton(
      icon: const Icon(Icons.check),
      onPressed: () async {
        await _saveTemplate();
      },
    );
  }

  Widget deleteButton() {
    return IconButton(
      icon: const Icon(Icons.delete_rounded),
      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
      onPressed: _confirmDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The action bar overlay handles the keyboard (Update L2)
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          UndoRedoButtons(controller: _undoController),
          if (widget.template != null) deleteButton(),
          saveButton(),
        ],
      ),
      body: EditorActionBarOverlay(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Card.filled(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          right: 8.0,
                        ),
                        child: TextField(
                          controller: _nameController,
                          maxLines: 1,
                          textCapitalization: TextCapitalization.words,
                          spellCheckConfiguration: SpellCheckConfiguration(
                              spellCheckService: DefaultSpellCheckService()),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: AppLocalizations.of(context)!.titleHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_places.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                              child: LocationRows(
                                  places: _places, onTap: _editPlace),
                            ),
                          _buildTagChips(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Builder(
                builder: (context) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    EditorKeyboardSessionScope.maybeOf(context)?.resume();
                    _focusNode.requestFocus();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                Expanded(
                                  child: EntryTextEditor(
                                    text: templateText,
                                    focusNode: _focusNode,
                                    textEditingController:
                                        _textEditingController,
                                    undoHistoryController: _undoController,
                                  ),
                                ),
                                SizedBox(
                                    height: 16 +
                                        EditorActionBar.reservedHeight(
                                            context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actionBar: EditorActionBar(
          controller: _textEditingController,
          undoController: _undoController,
          focusNode: _focusNode,
          showTemplateButton: false,
          mainActions: _buildMainActions(),
        ),
      ),
    );
  }
}
