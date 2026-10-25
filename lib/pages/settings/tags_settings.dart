// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/tag_bulk_move.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/tag_category_visuals.dart';
import 'package:daily_you/utils/templates_tags_transfer.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/edit_category.dart';
import 'package:daily_you/widgets/edit_tag.dart';
import 'package:daily_you/widgets/expressive_fab_menu.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/share_tags_dialog.dart';
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

class TagsSettings extends StatefulWidget {
  const TagsSettings({super.key});

  @override
  State<TagsSettings> createState() => _TagsSettingsState();
}

class _TagsSettingsState extends State<TagsSettings> {
  final Set<int?> _manuallyCollapsedIds = {};
  bool _isDraggingCategory = false;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Tags picked with a long press, for Move to category.
  final Set<int> _selectedIds = {};

  bool get _searching => _query.trim().isNotEmpty;
  bool get _selecting => _selectedIds.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelected(Tag tag) {
    setState(() {
      if (!_selectedIds.remove(tag.id)) _selectedIds.add(tag.id!);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

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
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tagsMovedToCategory(count, name))),
    );
  }

  Future<void> _editFavouriteColour(Tag favourite) async {
    final result = await showAppDialog<ColorPickerResult>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: favourite.color != null ? Color(favourite.color!) : null,
        showNoneOption: true,
      ),
    );
    if (result == null) return;
    // Built directly so "None" (null) clears the colour
    await TagsProvider.instance.update(Tag(
      id: favourite.id,
      name: favourite.name,
      color: result.color?.toARGB32(),
      tagType: favourite.tagType,
      icon: favourite.icon,
      iconType: favourite.iconType,
      categoryId: favourite.categoryId,
      sortOrder: favourite.sortOrder,
      timeCreate: favourite.timeCreate,
      timeModified: DateTime.now(),
    ));
  }

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

  void _showShareDialog(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => const ShareTagsDialog()));
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

  void _toggleCollapse(int? categoryId) {
    setState(() {
      if (_manuallyCollapsedIds.contains(categoryId)) {
        _manuallyCollapsedIds.remove(categoryId);
      } else {
        _manuallyCollapsedIds.add(categoryId);
      }
    });
  }

  List<_ListItem> _buildFlatItems(TagsProvider provider) {
    final items = <_ListItem>[];
    final hasCategories = provider.categories.isNotEmpty;
    // While searching, only matches show and every group is open
    bool shown(Tag tag) =>
        !Favourites.isFavouriteTag(tag) &&
        TagBulkMove.matches(tag, _query, provider.categories);
    bool open(int? id) => _searching || !_manuallyCollapsedIds.contains(id);

    // Header only shown when named categories exist, to give uncategorized
    // tags something to collapse under.
    final uncategorizedTags = provider.tags
        .where((tag) => tag.categoryId == null && shown(tag))
        .toList();
    if (hasCategories && (!_searching || uncategorizedTags.isNotEmpty)) {
      items.add(const _HeaderItem(null));
    }
    if (!hasCategories || open(null)) {
      for (final tag in uncategorizedTags) {
        items.add(_TagItem(tag));
      }
    }

    for (final category in provider.categories) {
      final categoryTags = provider.tags
          .where((tag) => tag.categoryId == category.id && shown(tag))
          .toList();
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
    if (from == to || _searching || _selecting) return;

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
    final isCollapsed =
        !_searching && _manuallyCollapsedIds.contains(category?.id);
    final canDrag = !isUncategorized && !_searching && !_selecting;
    final name =
        isUncategorized ? l10n.tagCategoryUncategorized : category.name;

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
              if (!isUncategorized)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _showCategoryDialog(context, category),
                ),
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
    if (_selecting) {
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
        onTap: _selecting
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
                  child: TagChip(tag: tag),
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
              if (!_selecting)
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

  /// ⭐ Favourite: set with the star button, so it can't be renamed, moved or
  /// deleted here. Only its colour changes.
  Widget _buildFavouriteRow(
      BuildContext context, Tag favourite, TagsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selecting ? null : () => _editFavouriteColour(favourite),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(Icons.lock_rounded,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TagChip(tag: favourite),
                    const SizedBox(height: 2),
                    Text(
                      l10n.favouriteTagLockedNote,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.logCount(provider.entryCountForTag(favourite.id!)),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: l10n.tagColorLabel,
                onPressed:
                    _selecting ? null : () => _editFavouriteColour(favourite),
              ),
            ],
          ),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<TagsProvider>(context);
    final isEmpty = provider.tags.isEmpty && provider.categories.isEmpty;

    final favourite =
        provider.tags.where(Favourites.isFavouriteTag).firstOrNull;
    final showFavourite = favourite != null &&
        TagBulkMove.matches(favourite, _query, provider.categories);

    final selectionBar = AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: _clearSelection,
      ),
      title: Text(l10n.tagsSelectedCount(_selectedIds.length)),
      actions: [
        IconButton(
          icon: const Icon(Icons.drive_file_move_outlined),
          tooltip: l10n.tagsMoveToCategory,
          onPressed: () => _moveSelected(provider),
        ),
      ],
    );

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _selecting
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
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () => _showShareDialog(context),
                  ),
                ],
              ),
        floatingActionButton: _selecting
            ? null
            : ExpressiveFabMenu(items: [
                ExpressiveFabMenuItem(
                    icon: Icons.folder_rounded,
                    label: l10n.tagCategoryLabel,
                    onTap: () => _showCategoryDialog(context, null)),
                ExpressiveFabMenuItem(
                    icon: Icons.local_offer_rounded,
                    label: l10n.tagLabel,
                    onTap: () => _showEditTagDialog(context, null)),
              ]),
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
                    if (showFavourite)
                      SliverToBoxAdapter(
                        child: _buildFavouriteRow(context, favourite, provider),
                      ),
                    if (_searching && items.isEmpty && !showFavourite)
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
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 90),
                    ),
                  ],
                );
              }),
      ),
    );
  }
}
