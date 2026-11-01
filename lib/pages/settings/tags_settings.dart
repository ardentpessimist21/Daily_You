// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:math' as math;

import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/quick_filters.dart';
import 'package:daily_you/fork/tag_bulk_move.dart';
import 'package:daily_you/fork/tag_pins.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/tag_category_visuals.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/utils/templates_tags_transfer.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/edit_category.dart';
import 'package:daily_you/widgets/edit_tag.dart';
import 'package:daily_you/widgets/expressive_fab_menu.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

sealed class _ListItem {
  const _ListItem();
}

class _HeaderItem extends _ListItem {
  final TagCategory? category; // null = Uncategorized section
  const _HeaderItem(this.category);
}

class _TagItem extends _ListItem {
  final Tag tag;
  const _TagItem(this.tag);
}

enum _DeleteChoice { delete, backUpFirst }

class TagsSettings extends StatefulWidget {
  const TagsSettings({super.key});

  @override
  State<TagsSettings> createState() => _TagsSettingsState();
}

class _TagsSettingsState extends State<TagsSettings> {
  /// Groups opened by hand; everything starts collapsed. null = Uncategorized.
  final Set<int?> _openIds = {};
  bool _galleryPinsOpen = false;
  bool _addTagsPinsOpen = false;
  bool _isDraggingCategory = false;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Select mode starts with a long press on a tag and stays on until it's
  /// closed, even with nothing ticked.
  bool _selectMode = false;
  final Set<int> _selectedIds = {};

  /// The pill's Share button opens Save and Share in its place.
  bool _shareOpen = false;

  bool get _searching => _query.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Selection

  void _toggleSelected(Tag tag) {
    setState(() {
      _selectMode = true;
      if (!_selectedIds.remove(tag.id)) _selectedIds.add(tag.id!);
    });
  }

  void _exitSelectMode() => setState(() {
        _selectMode = false;
        _shareOpen = false;
        _selectedIds.clear();
      });

  /// Tags the list can show: everything but ⭐ Favourite, narrowed by search.
  bool _shown(Tag tag, TagsProvider provider) =>
      !Favourites.isFavouriteTag(tag) &&
      TagBulkMove.matches(tag, _query, provider.categories);

  /// Visible tags in [categoryId] (null = Uncategorized). With a search
  /// typed, only the matches.
  List<Tag> _tagsIn(int? categoryId, TagsProvider provider) => provider.tags
      .where((tag) => tag.categoryId == categoryId && _shown(tag, provider))
      .toList();

  void _selectAllVisible(TagsProvider provider) => setState(() {
        _selectedIds.addAll(provider.tags
            .where((tag) => _shown(tag, provider))
            .map((tag) => tag.id!));
      });

  void _clearSelection() => setState(_selectedIds.clear);

  bool? _categoryCheckValue(int? categoryId, TagsProvider provider) {
    final ids = _tagsIn(categoryId, provider).map((tag) => tag.id).toSet();
    if (ids.isEmpty) return false;
    final ticked = ids.where(_selectedIds.contains).length;
    if (ticked == 0) return false;
    return ticked == ids.length ? true : null;
  }

  void _toggleCategorySelection(int? categoryId, TagsProvider provider) {
    final ids = _tagsIn(categoryId, provider).map((tag) => tag.id!).toList();
    setState(() {
      if (ids.every(_selectedIds.contains)) {
        _selectedIds.removeAll(ids);
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  List<Tag> _selectedTags(TagsProvider provider) =>
      provider.tags.where((tag) => _selectedIds.contains(tag.id)).toList();

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Pill actions

  Future<void> _moveSelected(TagsProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    // Wrapped so "Uncategorized" (null) can be told apart from Cancel
    final target = await showAppDialog<({int? id})>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.tagsMoveToCategory),
        children: [
          for (final category in provider.categories)
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              onPressed: () => Navigator.of(context).pop((id: category.id)),
              child: Row(children: [
                TagIconGlyph(
                  icon: category.icon,
                  iconType: category.iconType,
                  fallbackIcon: Icons.folder_rounded,
                  color: category.resolvedColor(context),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(category.name)),
              ]),
            ),
          SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onPressed: () => Navigator.of(context).pop((id: null)),
            child: Row(children: [
              Icon(Icons.folder_open_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.tagCategoryUncategorized)),
            ]),
          ),
        ],
      ),
    );
    if (target == null || !mounted) return;

    final updates = TagBulkMove.plan(provider.tags, _selectedIds, target.id);
    final count = _selectedIds.length;
    if (updates.isNotEmpty) await provider.batchUpdateTags(updates);
    if (!mounted) return;
    final name = target.id == null
        ? l10n.tagCategoryUncategorized
        : provider.categories.where((c) => c.id == target.id).first.name;
    _exitSelectMode();
    _snack(l10n.tagsMovedToCategory(count, name));
  }

  String _pinListName(AppLocalizations l10n, TagPinList list) =>
      identical(list, TagPinList.gallery)
          ? l10n.tagsPinListGallery
          : l10n.tagsPinListAddTags;

  /// Asks which list, then pins the selected tags there, or unpins them
  /// when they're all already in it.
  Future<void> _pinSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final ids = _selectedIds.toList();
    final list = await showAppDialog<TagPinList>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.tagsPinTo),
        children: [
          for (final list in TagPinList.all)
            Builder(builder: (context) {
              final allIn = ids.every(list.contains);
              final name = _pinListName(l10n, list);
              return SimpleDialogOption(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                onPressed: () => Navigator.of(context).pop(list),
                child: Row(children: [
                  Icon(
                    identical(list, TagPinList.gallery)
                        ? Icons.filter_alt_outlined
                        : Icons.new_label_outlined,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(allIn ? l10n.tagsUnpinFrom(name) : name),
                        Text(
                          l10n.tagsPinFreeOf(list.free, list.max),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ]),
              );
            }),
        ],
      ),
    );
    if (list == null || !mounted) return;
    final name = _pinListName(l10n, list);
    final String message;
    if (ids.every(list.contains)) {
      await list.unpin(ids);
      message = l10n.tagsUnpinnedFrom(name);
    } else {
      final (added, skipped) = await list.pin(ids);
      if (added == 0) {
        message = l10n.tagsPinsFull(name, list.max);
      } else if (skipped > 0) {
        message = l10n.tagsPinnedSome(added, name, skipped);
      } else {
        message = l10n.tagsPinnedTo(name, list.ids.length, list.max);
      }
    }
    if (!mounted) return;
    _exitSelectMode();
    _snack(message);
  }

  Future<void> _colourSelected(TagsProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedTags(provider);
    if (selected.isEmpty) return;
    final colours = selected.map((tag) => tag.color).toSet();
    final result = await showAppDialog<ColorPickerResult>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: colours.length == 1 && colours.first != null
            ? Color(colours.first!)
            : null,
        showNoneOption: true,
      ),
    );
    if (result == null || !mounted) return;
    final now = DateTime.now();
    // Built directly so "None" (null) clears the colour
    await provider.batchUpdateTags([
      for (final tag in selected)
        Tag(
          id: tag.id,
          name: tag.name,
          color: result.color?.toARGB32(),
          tagType: tag.tagType,
          icon: tag.icon,
          iconType: tag.iconType,
          categoryId: tag.categoryId,
          sortOrder: tag.sortOrder,
          timeCreate: tag.timeCreate,
          timeModified: now,
        ),
    ]);
    if (!mounted) return;
    _exitSelectMode();
    _snack(l10n.tagsColourChanged(selected.length));
  }

  Future<void> _deleteSelected(TagsProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedTags(provider);
    if (selected.isEmpty) return;
    final ids = selected.map((tag) => tag.id).toSet();
    final logs = {
      for (final entryTag in provider.entryTags)
        if (ids.contains(entryTag.tagId)) entryTag.entryId,
    }.length;

    final choice = await showAppDialog<_DeleteChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.tagsDeleteSelectedMessage(selected.length, logs)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_DeleteChoice.backUpFirst),
            child: Text(l10n.tagsDeleteBackupFirst),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_DeleteChoice.delete),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == _DeleteChoice.backUpFirst) {
      final status = ValueNotifier<String>("");
      BackupRestoreUtils.showLoadingStatus(context, status);
      final outcome = await BackupRestoreUtils.backupToZip(
          context, (text) => status.value = text);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (outcome.failed) {
        await showFailureDialog(context,
            description: l10n.backupErrorDescription, error: outcome.error);
        return;
      }
      // Picking no folder backs out of the delete too
      if ((outcome.status == OperationStatus.cancelled)) return;
    }

    await provider.removeTags(selected);
    if (!mounted) return;
    _exitSelectMode();
    _snack(l10n.tagsDeleted(selected.length));
  }

  String _exportFileName() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return "daily_you_tags_$timestamp.json";
  }

  Future<void> _saveSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = TemplatesTagsTransfer.exportTags({..._selectedIds});
    final status = ValueNotifier<String>("");
    BackupRestoreUtils.showLoadingStatus(context, status);
    final outcome = await TemplatesTagsTransfer.saveBytesToFile(
        bytes, _exportFileName(), (text) => status.value = text);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (outcome.failed) {
      await showFailureDialog(context,
          description: l10n.exportErrorDescription, error: outcome.error);
      return;
    }
    if (!(outcome.status == OperationStatus.cancelled)) _exitSelectMode();
  }

  Future<void> _shareSelected() async {
    final bytes = TemplatesTagsTransfer.exportTags({..._selectedIds});
    await TemplatesTagsTransfer.shareBytes(bytes, _exportFileName());
    if (mounted) _exitSelectMode();
  }

  // Top bar actions

  void _showEditTagDialog(BuildContext context, Tag? tag) {
    showAppDialog(
      context: context,
      builder: (context) => EditTag(tag: tag),
    );
  }

  void _showCategoryDialog(BuildContext context, TagCategory? category) {
    showAppDialog(
      context: context,
      builder: (_) => EditCategory(category: category),
    );
  }

  Future<void> _importFile(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    final outcome = await TemplatesTagsTransfer.importTransferFile((status) {
      statusNotifier.value = status;
    });

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.importErrorDescription,
          error: outcome.error);
    }
  }

  List<int?> _groupIds(TagsProvider provider) =>
      [null, for (final category in provider.categories) category.id];

  bool _allOpen(TagsProvider provider) =>
      _galleryPinsOpen &&
      _addTagsPinsOpen &&
      _groupIds(provider).every(_openIds.contains);

  void _toggleAll(TagsProvider provider) {
    final open = !_allOpen(provider);
    setState(() {
      _galleryPinsOpen = open;
      _addTagsPinsOpen = open;
      if (open) {
        _openIds.addAll(_groupIds(provider));
      } else {
        _openIds.clear();
      }
    });
  }

  void _toggleCollapse(int? categoryId) {
    setState(() {
      if (!_openIds.remove(categoryId)) _openIds.add(categoryId);
    });
  }

  // List

  List<_ListItem> _buildFlatItems(TagsProvider provider) {
    final items = <_ListItem>[];
    final hasCategories = provider.categories.isNotEmpty;
    // While searching, only matches show and every group is open
    bool open(int? id) => _searching || _openIds.contains(id);

    // Header only shown when named categories exist, to give uncategorized
    // tags something to collapse under.
    final uncategorizedTags = _tagsIn(null, provider);
    if (hasCategories && (!_searching || uncategorizedTags.isNotEmpty)) {
      items.add(const _HeaderItem(null));
    }
    if (!hasCategories || open(null)) {
      for (final tag in uncategorizedTags) {
        items.add(_TagItem(tag));
      }
    }

    for (final category in provider.categories) {
      final categoryTags = _tagsIn(category.id, provider);
      if (_searching && categoryTags.isEmpty) continue;
      items.add(_HeaderItem(category));
      if (open(category.id)) {
        for (final tag in categoryTags) {
          items.add(_TagItem(tag));
        }
      }
    }

    return items;
  }

  Future<void> _onReorder(
      int from, int to, TagsProvider provider, List<_ListItem> items) async {
    if (from == to || _searching || _selectMode) return;

    final movedItem = items[from];
    items.removeAt(from);
    items.insert(to, movedItem);

    if (movedItem is _HeaderItem) {
      // Uncategorized header is pinned, no-op if it was somehow moved
      if (movedItem.category == null) return;

      final orderedCategories = items
          .whereType<_HeaderItem>()
          .where((header) => header.category != null)
          .map((header) => header.category!)
          .toList();
      await provider.updateCategorySortOrders(orderedCategories);
    } else if (movedItem is _TagItem) {
      TagCategory? currentCategory;
      final Map<int?, List<Tag>> sectionTags = {};

      for (final item in items) {
        if (item is _HeaderItem) {
          currentCategory = item.category;
          sectionTags[currentCategory?.id] ??= [];
        } else if (item is _TagItem) {
          (sectionTags[currentCategory?.id] ??= []).add(item.tag);
        }
      }

      final tagsToUpdate = <Tag>[];
      for (final entry in sectionTags.entries) {
        final categoryId = entry.key;
        final tagsInSection = entry.value;
        for (int index = 0; index < tagsInSection.length; index++) {
          final tag = tagsInSection[index];
          final categoryChanged = tag.categoryId != categoryId;
          final orderChanged = tag.sortOrder != index;
          if (categoryChanged || orderChanged) {
            tagsToUpdate.add(Tag(
              id: tag.id,
              name: tag.name,
              color: tag.color,
              tagType: tag.tagType,
              icon: tag.icon,
              iconType: tag.iconType,
              categoryId: categoryId,
              sortOrder: index,
              timeCreate: tag.timeCreate,
              timeModified: categoryChanged ? DateTime.now() : tag.timeModified,
            ));
          }
        }
      }

      if (tagsToUpdate.isNotEmpty) {
        await provider.batchUpdateTags(tagsToUpdate);
      }
    }
  }

  Widget _buildHeaderRow(
    BuildContext context,
    int index,
    TagCategory? category,
    TagsProvider provider, {
    required Key key,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isUncategorized = category == null;
    final isCollapsed = !_searching && !_openIds.contains(category?.id);
    final canDrag = !isUncategorized && !_searching && !_selectMode;
    final name =
        isUncategorized ? l10n.tagCategoryUncategorized : category.name;

    final Widget trailingAction;
    if (_selectMode) {
      // Ticks everything inside (only the matches while searching),
      // without opening the group
      trailingAction = Checkbox(
        tristate: true,
        value: _categoryCheckValue(category?.id, provider),
        onChanged: (_) => _toggleCategorySelection(category?.id, provider),
      );
    } else if (!isUncategorized) {
      trailingAction = IconButton(
        icon: const Icon(Icons.edit_rounded),
        onPressed: () => _showCategoryDialog(context, category),
      );
    } else {
      trailingAction = const SizedBox.shrink();
    }

    return Material(
      key: key,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: _searching ? null : () => _toggleCollapse(category?.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const SizedBox(height: kMinInteractiveDimension),
              if (canDrag)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.drag_handle_rounded, size: 20),
                  ),
                )
              else
                const SizedBox(width: 44),
              if (!isUncategorized) ...[
                TagIconGlyph(
                  icon: category.icon,
                  iconType: category.iconType,
                  fallbackIcon: Icons.folder_rounded,
                  color: category.resolvedColor(context),
                  size: 20,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              trailingAction,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  isCollapsed
                      ? Icons.expand_more_rounded
                      : Icons.expand_less_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagRow(
    BuildContext context,
    int index,
    Tag tag,
    TagsProvider provider, {
    required Key key,
  }) {
    // Hidden while a category header is being dragged
    if (_isDraggingCategory) return SizedBox(key: key);
    final selected = _selectedIds.contains(tag.id);
    final Widget leading;
    if (_selectMode) {
      leading = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child:
            Checkbox(value: selected, onChanged: (_) => _toggleSelected(tag)),
      );
    } else if (_searching) {
      leading = const SizedBox(width: 44);
    } else {
      leading = ReorderableDragStartListener(
        index: index,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Icon(Icons.drag_handle_rounded, size: 20),
        ),
      );
    }
    return Material(
      key: key,
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.transparent,
      child: InkWell(
        onTap: _selectMode
            ? () => _toggleSelected(tag)
            : () => _showEditTagDialog(context, tag),
        onLongPress: () => _toggleSelected(tag),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              leading,
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TagPinList.pinnedAnywhere(tag.id!)
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(child: TagChip(tag: tag)),
                          const SizedBox(width: 6),
                          Icon(Icons.push_pin_rounded,
                              size: 16,
                              semanticLabel:
                                  AppLocalizations.of(context)!.pinnedTagsTitle,
                              color: Theme.of(context).colorScheme.primary),
                        ])
                      : TagChip(tag: tag),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  AppLocalizations.of(context)!
                      .logCount(provider.entryCountForTag(tag.id!)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (!_selectMode)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _showEditTagDialog(context, tag),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Pinned · Gallery / Pinned · Add Tags: a collapsible row like a
  /// category, with the pins inside as chips (grip to reorder, × to unpin)
  /// and a dashed slot showing how many are free.
  Widget _buildPinnedSection(
      BuildContext context, TagPinList list, bool open, VoidCallback onToggle) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isGallery = identical(list, TagPinList.gallery);
    final pins = list.tags;

    final header = Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const SizedBox(height: kMinInteractiveDimension, width: 12),
              Icon(Icons.push_pin_rounded,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isGallery ? l10n.tagsPinnedGallery : l10n.tagsPinnedAddTags,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  maxLines: 1,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text('${pins.length}/${list.max}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(open
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded),
              ),
            ],
          ),
        ),
      ),
    );

    if (!open) return header;

    final freeSlot = list.free > 0
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: _DashedSlot(label: l10n.tagPinsFree(list.free)),
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGallery)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _LockedChip(
                          label: l10n.quickFilterFavourite,
                          color: QuickFilters.favouriteFallback),
                      _LockedChip(
                          label: l10n.tagFilterTrackers,
                          color: QuickFilters.trackersColor),
                      _LockedChip(
                          label: l10n.quickFilterLastEdited,
                          color: QuickFilters.lastEditedColor),
                    ],
                  ),
                ),
              SizedBox(
                height: 40,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  itemCount: pins.length,
                  footer: freeSlot,
                  onReorderItem: (from, to) async {
                    await list.move(from, to);
                    if (mounted) setState(() {});
                  },
                  itemBuilder: (context, index) => Padding(
                    key: ValueKey(
                        'pin_${isGallery ? 'g' : 'a'}_${pins[index].id}'),
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: _PinChip(
                      tag: pins[index],
                      index: index,
                      onRemove: () async {
                        await list.unpin([pins[index].id!]);
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ),
              ),
              if (pins.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(l10n.tagPinsEmptyHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SearchBar(
        controller: _searchController,
        hintText: l10n.addTagsSearchHint,
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.secondaryContainer),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.search_rounded,
              color: Theme.of(context).colorScheme.secondary),
        ),
        trailing: [
          if (_searching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildSelectionPill(BuildContext context, TagsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasSelection = _selectedIds.isNotEmpty;
    VoidCallback? when(VoidCallback action) => hasSelection ? action : null;

    final Widget content;
    if (_shareOpen) {
      content = Row(
        key: const ValueKey('share'),
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => setState(() => _shareOpen = false),
          ),
          const SizedBox(width: 4),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.save_alt_rounded),
            label: Text(MaterialLocalizations.of(context).saveButtonLabel),
            onPressed: when(_saveSelected),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.share_rounded),
              label: Text(l10n.shareButtonLabel),
              onPressed: when(_shareSelected),
            ),
          ],
          const SizedBox(width: 6),
        ],
      );
    } else {
      content = Row(
        key: const ValueKey('actions'),
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: l10n.shareButtonLabel,
            onPressed: when(() => setState(() => _shareOpen = true)),
          ),
          IconButton(
            icon: const Icon(Icons.push_pin_outlined),
            tooltip: l10n.tagsPinTo,
            onPressed: when(_pinSelected),
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move_outlined),
            tooltip: l10n.tagsMoveToCategory,
            onPressed: when(() => _moveSelected(provider)),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: l10n.tagsChangeColour,
            onPressed: when(() => _colourSelected(provider)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: when(() => _deleteSelected(provider)),
          ),
        ],
      );
    }

    return Material(
      color: theme.colorScheme.primaryContainer,
      shape: const StadiumBorder(),
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: IconTheme.merge(
        data: IconThemeData(color: theme.colorScheme.primary),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              height: 48,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<TagsProvider>(context);
    final isEmpty = provider.tags.isEmpty && provider.categories.isEmpty;

    final selectionBar = AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: _exitSelectMode,
      ),
      title: Text(l10n.tagsSelectedCount(_selectedIds.length)),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all_rounded),
          tooltip: l10n.tagsSelectAll,
          onPressed: () => _selectAllVisible(provider),
        ),
        IconButton(
          icon: const Icon(Icons.deselect_rounded),
          tooltip: l10n.tagsClearSelection,
          onPressed: _clearSelection,
        ),
      ],
    );

    final allOpen = _allOpen(provider);
    final fab = ExpressiveFabMenu(
      key: const ValueKey('fab'),
      items: [
        ExpressiveFabMenuItem(
            icon: Icons.folder_rounded,
            label: l10n.tagCategoryLabel,
            onTap: () => _showCategoryDialog(context, null)),
        ExpressiveFabMenuItem(
            icon: Icons.local_offer_rounded,
            label: l10n.tagLabel,
            onTap: () => _showEditTagDialog(context, null)),
      ],
    );

    return PopScope(
      canPop: !_selectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_shareOpen) {
          setState(() => _shareOpen = false);
        } else {
          _exitSelectMode();
        }
      },
      child: Scaffold(
        appBar: _selectMode
            ? selectionBar
            : AppBar(
                title: Text(l10n.settingsTagsTitle),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.file_open_outlined),
                    onPressed: () => _importFile(context),
                  ),
                  IconButton(
                    icon: Icon(allOpen
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded),
                    tooltip:
                        allOpen ? l10n.tagsCollapseAll : l10n.tagsExpandAll,
                    onPressed: () => _toggleAll(provider),
                  ),
                ],
              ),
        // The + button stretches into the action pill in select mode
        floatingActionButton: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: [...previous, if (current != null) current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              alignment: AlignmentDirectional.centerEnd,
              child: child,
            ),
          ),
          child: _selectMode
              ? KeyedSubtree(
                  key: const ValueKey('pill'),
                  child: _buildSelectionPill(context, provider),
                )
              : fab,
        ),
        body: isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Text(l10n.noResults),
                ),
              )
            : Builder(builder: (context) {
                final allItems = _buildFlatItems(provider);
                // Keep the uncategorized header out of the reorderable range so
                // nothing can be dragged above
                final hasUncategorizedHeader = allItems.isNotEmpty &&
                    allItems[0] is _HeaderItem &&
                    (allItems[0] as _HeaderItem).category == null;
                final items =
                    hasUncategorizedHeader ? allItems.sublist(1) : allItems;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSearchField(l10n)),
                    if (!_searching) ...[
                      SliverToBoxAdapter(
                        child: _buildPinnedSection(
                          context,
                          TagPinList.gallery,
                          _galleryPinsOpen,
                          () => setState(
                              () => _galleryPinsOpen = !_galleryPinsOpen),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildPinnedSection(
                          context,
                          TagPinList.addTags,
                          _addTagsPinsOpen,
                          () => setState(
                              () => _addTagsPinsOpen = !_addTagsPinsOpen),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ],
                    if (_searching && items.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(child: Text(l10n.noResults)),
                        ),
                      ),
                    if (hasUncategorizedHeader)
                      SliverToBoxAdapter(
                        child: _buildHeaderRow(
                          context,
                          0,
                          null,
                          provider,
                          key: const ValueKey('hdr_null'),
                        ),
                      ),
                    SliverReorderableList(
                      itemCount: items.length,
                      onReorderStart: (index) {
                        if (!_isDraggingCategory &&
                            index < items.length &&
                            items[index] is _HeaderItem &&
                            (items[index] as _HeaderItem).category != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _isDraggingCategory = true);
                            }
                          });
                        }
                      },
                      onReorderEnd: (_) {
                        if (_isDraggingCategory) {
                          setState(() => _isDraggingCategory = false);
                        }
                      },
                      onReorderItem: (from, to) {
                        final snapshot = List<_ListItem>.from(items);
                        _onReorder(from, to, provider, snapshot);
                      },
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is _HeaderItem) {
                          return _buildHeaderRow(
                            context,
                            index,
                            item.category,
                            provider,
                            key: ValueKey('hdr_${item.category?.id ?? 'null'}'),
                          );
                        } else {
                          final tagItem = item as _TagItem;
                          return _buildTagRow(
                            context,
                            index,
                            tagItem.tag,
                            provider,
                            key: ValueKey('tag_${tagItem.tag.id}'),
                          );
                        }
                      },
                    ),
                    // Room for the pill or + button
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 96),
                    ),
                  ],
                );
              }),
      ),
    );
  }
}

/// A pinned tag in Settings › Tags: grip to reorder, × to unpin.
class _PinChip extends StatelessWidget {
  const _PinChip({
    required this.tag,
    required this.index,
    required this.onRemove,
  });

  final Tag tag;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        tag.resolvedColor(context, fallback: theme.colorScheme.secondary);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 2),
              child: Icon(Icons.drag_indicator_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          TagIconGlyph(
            icon: tag.icon,
            iconType: tag.iconType,
            fallbackIcon: tag.typeIcon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(tag.name,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              tooltip: AppLocalizations.of(context)!.quickFilterUnpin,
              icon: const Icon(Icons.close_rounded),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

/// Favourite, Trackers and Last Edited: always first in the Gallery filter.
class _LockedChip extends StatelessWidget {
  const _LockedChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// The "N free" slot after the pins.
class _DashedSlot extends StatelessWidget {
  const _DashedSlot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _DashedBorderPainter(theme.colorScheme.outline),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final radius = math.min(size.height / 2, 20.0);
    final path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
