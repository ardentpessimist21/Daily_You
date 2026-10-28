// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/favourites.dart';
import 'package:daily_you/fork/tag_picker_layout.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/pages/settings/tags_settings.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/edit_tag.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/utils/tag_category_visuals.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/widgets/tag_grouped_chip_list.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

enum TagPickerMode { attach, selectSingle, filter }

enum TagFilterMode { all, any }

class TagPickerDialog extends StatefulWidget {
  final TagPickerMode mode;

  // attach
  final TagAttachmentSource? source;

  // filter
  final List<int> initialSelectedTagIds;
  final TagFilterMode initialFilterMode;
  final bool initialNoTagsOnly;
  final void Function(List<int>, TagFilterMode, bool)? onFilterChanged;

  final TagType? tagTypeFilter;

  /// Optional line under the title, e.g. multi-select's "On some: …"
  final String? note;

  const TagPickerDialog({
    super.key,
    required this.mode,
    this.source,
    this.initialSelectedTagIds = const [],
    this.initialFilterMode = TagFilterMode.any,
    this.initialNoTagsOnly = false,
    this.onFilterChanged,
    this.tagTypeFilter,
    this.note,
  });

  @override
  State<TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<TagPickerDialog> {
  final TagNameEditingController _searchController = TagNameEditingController();
  String _searchText = '';

  // Usage is measured once when the popup opens, so tags don't jump around
  // while you're picking
  late final Map<int, TagUsage> _usage;

  /// Groups opened by hand; every group starts closed. -1 = Uncategorized.
  final Set<int> _openGroups = {};

  // filter mode state
  late List<int> _selectedTagIds;
  late TagFilterMode _filterMode;
  late bool _noTagsOnly;

  /// Gallery filter's Trackers button: shows every tracker, each in its
  /// own category, with every category open.
  bool _trackersOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List.from(widget.initialSelectedTagIds);
    _filterMode = widget.initialFilterMode;
    _noTagsOnly = widget.initialNoTagsOnly;
    final entryDates = <int, DateTime>{
      for (final entry in EntriesProvider.instance.entries)
        if (entry.id != null) entry.id!: entry.timeCreate,
    };
    _usage = TagPickerLayout.usage(
        TagsProvider.instance.entryTags, entryDates, DateTime.now());
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static int _groupKey(TagCategory? category) => category?.id ?? -1;

  void _toggleGroup(TagCategory? category) {
    final key = _groupKey(category);
    setState(() {
      if (!_openGroups.remove(key)) _openGroups.add(key);
    });
  }

  // attach mode helpers

  Future<void> _createAndAddTagWithName(
      TagsProvider provider, String name) async {
    final tagsBefore = List<Tag>.from(provider.tags);
    await showAppDialog(
      context: context,
      builder: (_) => EditTag(tag: null, initialName: name),
    );
    final newTag = provider.tags
        .where((tag) =>
            tagsBefore.every((existingTag) => existingTag.id != tag.id))
        .firstOrNull;
    if (newTag == null) return;

    _searchController.clear();

    if (widget.mode == TagPickerMode.attach) {
      final source = widget.source!;
      if (source.contains(newTag.id!)) return;
      if (mounted) await source.attach(context, newTag);
    }
  }

  // filter mode helpers

  void _notifyFilter() {
    widget.onFilterChanged?.call(_selectedTagIds, _filterMode, _noTagsOnly);
  }

  void _addFilterTag(int tagId) {
    setState(() => _selectedTagIds.add(tagId));
    _notifyFilter();
  }

  void _removeFilterTag(int tagId) {
    setState(() => _selectedTagIds.remove(tagId));
    _notifyFilter();
  }

  void _setNoTagsOnly(bool value) {
    setState(() {
      _noTagsOnly = value;
      if (value) {
        _selectedTagIds = [];
        _filterMode = TagFilterMode.any;
      }
    });
    _notifyFilter();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTagIds = [];
      _filterMode = TagFilterMode.any;
      _noTagsOnly = false;
      _trackersOnly = false;
    });
    _notifyFilter();
    Navigator.of(context).pop();
  }

  // builders

  Widget _buildAttachedChips(TagsProvider provider) {
    final source = widget.source!;
    final attachedIds = source.attachedTagIds;
    if (attachedIds.isEmpty) return const SizedBox.shrink();
    final attachedSet = attachedIds.toSet();
    final tagPool =
        provider.tags.where((tag) => attachedSet.contains(tag.id)).toList();
    final sections = provider.buildSections('', tagPool: tagPool);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TagGroupedChipList(
        sections: sections,
        chipBuilder: (tag) => TagChip(
          tag: tag,
          value: source.valueFor(tag.id!),
          onTap: (source.supportsValues && tag.tagType == TagType.tracker)
              ? () => source.editValue(context, tag)
              : null,
          onRemove: () => source.detach(tag.id!),
        ),
      ),
    );
  }

  Widget _buildFilterSelectedChips(TagsProvider provider) {
    if (_selectedTagIds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _selectedTagIds.map((tagId) {
          final tag = provider.tags
              .where((candidate) => candidate.id == tagId)
              .firstOrNull;
          if (tag == null) return const SizedBox.shrink();
          return TagChip(tag: tag, onRemove: () => _removeFilterTag(tagId));
        }).toList(),
      ),
    );
  }

  /// Any/All (once two tags are picked) and No tags, on one row.
  Widget _buildFilterRow(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _selectedTagIds.length < 2 || _noTagsOnly
                  ? const SizedBox.shrink()
                  : _buildFilterModeToggle(context, l10n),
            ),
          ),
          _buildNoTagsToggle(l10n),
        ],
      ),
    );
  }

  Widget _buildFilterModeToggle(BuildContext context, AppLocalizations l10n) {
    return SegmentedButton<TagFilterMode>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(
          value: TagFilterMode.any,
          label: Text(l10n.tagFilterModeAny),
        ),
        ButtonSegment(
          value: TagFilterMode.all,
          label: Text(l10n.tagFilterModeAll),
        ),
      ],
      selected: {_filterMode},
      onSelectionChanged: (selected) {
        setState(() => _filterMode = selected.first);
        _notifyFilter();
      },
    );
  }

  Widget _buildNoTagsToggle(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.noTagsFilterLabel,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 4),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _noTagsOnly,
            onChanged: _setNoTagsOnly,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n, TagsProvider provider) {
    final showAdd = _searchText.isNotEmpty &&
        widget.mode == TagPickerMode.attach &&
        !provider.tags
            .any((tag) => tag.name.toLowerCase() == _searchText.toLowerCase());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SearchBar(
        controller: _searchController,
        hintText: l10n.addTagsSearchHint,
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.only(left: 4, right: 4),
        ),
        backgroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.secondaryContainer,
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        trailing: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              final scale = TweenSequence([
                TweenSequenceItem(
                  tween: Tween<double>(begin: 0.0, end: 1.1)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 60,
                ),
                TweenSequenceItem(
                  tween: Tween<double>(begin: 1.1, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeIn)),
                  weight: 40,
                ),
              ]).animate(animation);
              return ScaleTransition(scale: scale, child: child);
            },
            child: showAdd
                ? IconButton(
                    key: const ValueKey('addButton'),
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _createAndAddTagWithName(
                        provider, sanitizeTagName(_searchController.text)),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    if (source != null) {
      // Rebuild when source mutates
      return ListenableBuilder(
        listenable: source,
        builder: (context, _) => _buildDialog(context),
      );
    }
    return _buildDialog(context);
  }

  Widget _buildDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TagsProvider>(
      builder: (context, provider, _) {
        // Available pool excludes tags already selected/attached
        final List<int> excludedIds;
        if (widget.mode == TagPickerMode.attach) {
          excludedIds = widget.source!.attachedTagIds;
        } else if (widget.mode == TagPickerMode.filter) {
          excludedIds = _selectedTagIds;
        } else {
          excludedIds = [];
        }

        final trackersOnly =
            widget.mode == TagPickerMode.filter && _trackersOnly;
        bool typeMatch(Tag tag) => trackersOnly
            ? tag.tagType == TagType.tracker || Favourites.isFavouriteTag(tag)
            : widget.tagTypeFilter == null ||
                tag.tagType == widget.tagTypeFilter;
        final pool = provider.tags
            .where((tag) => !excludedIds.contains(tag.id) && typeMatch(tag))
            .toList();

        // ⭐ Favourite is set with the star button; only the Gallery filter
        // offers it, pinned at the top
        final content = TagPickerLayout.build(
          pool: pool,
          categories: provider.categories,
          usage: _usage,
          query: _searchText,
          pinFavourite: widget.mode == TagPickerMode.filter,
        );
        final hasTrackers =
            provider.tags.any((tag) => tag.tagType == TagType.tracker);

        final String title;
        switch (widget.mode) {
          case TagPickerMode.attach:
            title = l10n.addTagsTitle;
          case TagPickerMode.selectSingle:
            title = l10n.selectTagTitle;
          case TagPickerMode.filter:
            title = l10n.filterTagsTitle;
        }

        return AlertDialog(
          title: Text(title),
          contentPadding: widget.mode == TagPickerMode.selectSingle
              ? const EdgeInsets.fromLTRB(24, 16, 24, 0)
              : null,
          content: SizedBox(
            width: double.maxFinite,
            child: _buildContent(context, l10n, provider, content,
                hasTrackers: hasTrackers),
          ),
          actions: _buildActions(context, l10n, provider),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    TagsProvider provider,
    TagPickerContent content, {
    bool hasTrackers = false,
  }) {
    Future<void> pick(Tag tag) async {
      switch (widget.mode) {
        case TagPickerMode.attach:
          await widget.source!.attach(context, tag);
        case TagPickerMode.selectSingle:
          Navigator.of(context).pop(tag);
        case TagPickerMode.filter:
          _addFilterTag(tag.id!);
      }
    }

    final trackersButton = widget.mode == TagPickerMode.filter && hasTrackers
        ? FilterChip(
            avatar: Icon(Icons.numbers_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            showCheckmark: false,
            label: Text(l10n.tagFilterTrackers),
            selected: _trackersOnly,
            onSelected: (value) => setState(() => _trackersOnly = value),
          )
        : null;

    final list = _TagPickerList(
      content: content,
      searching: _searchText.isNotEmpty || _trackersOnly,
      trailingPinned: trackersButton,
      isOpen: (category) => _openGroups.contains(_groupKey(category)),
      onToggle: _toggleGroup,
      onPick: pick,
    );

    if (widget.mode == TagPickerMode.selectSingle) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(l10n, provider),
          const SizedBox(height: 8),
          if (content.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.noResults),
            )
          else
            Flexible(child: SingleChildScrollView(child: list)),
        ],
      );
    }

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.mode == TagPickerMode.attach) _buildAttachedChips(provider),
        if (widget.mode == TagPickerMode.filter)
          _buildFilterSelectedChips(provider),
        _buildSearchField(l10n, provider),
        const SizedBox(height: 8),
        if (content.isEmpty && (_searchText.isNotEmpty || _trackersOnly))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noResults),
          )
        else
          list,
      ],
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(widget.note!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          if (widget.mode == TagPickerMode.filter)
            _buildFilterRow(context, l10n),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _noTagsOnly ? 0.3 : 1.0,
            child: IgnorePointer(ignoring: _noTagsOnly, child: body),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(
      BuildContext context, AppLocalizations l10n, TagsProvider provider) {
    final close = TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(MaterialLocalizations.of(context).closeButtonLabel),
    );

    final manageTags = TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TagsSettings()),
      ),
      child: Text(l10n.manageTags),
    );

    switch (widget.mode) {
      case TagPickerMode.attach:
        return [manageTags, close];
      case TagPickerMode.selectSingle:
        return [close];
      case TagPickerMode.filter:
        return [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(l10n.clearAllFilters),
          ),
          close,
        ];
    }
  }
}

/// Pinned ⭐, the Frequent row, then collapsible groups.
class _TagPickerList extends StatelessWidget {
  final TagPickerContent content;
  final bool searching;
  final bool Function(TagCategory?) isOpen;
  final void Function(TagCategory?) onToggle;
  final Future<void> Function(Tag) onPick;

  /// Shown on the pinned row after ⭐ (the Gallery filter's Trackers button).
  final Widget? trailingPinned;

  const _TagPickerList({
    required this.content,
    required this.searching,
    this.trailingPinned,
    required this.isOpen,
    required this.onToggle,
    required this.onPick,
  });

  Widget _chips(List<Tag> tags) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in tags) TagChip(tag: tag, onTap: () => onPick(tag)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    final favourite = content.pinnedFavourite;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (favourite != null || trailingPinned != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (favourite != null)
                  TagChip(tag: favourite, onTap: () => onPick(favourite)),
                if (trailingPinned != null) trailingPinned!,
              ],
            ),
          ),
        if (!searching && content.frequent.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(l10n.tagPickerFrequent.toUpperCase(),
                    style: labelStyle),
              ),
              Text(l10n.tagPickerFrequentWindow,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          _chips(content.frequent),
          const SizedBox(height: 10),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ],
        for (final group in content.groups)
          _TagGroupSection(
            group: group,
            open: searching || isOpen(group.category),
            onToggle: searching ? null : () => onToggle(group.category),
            chips: _chips(group.tags),
          ),
      ],
    );
  }
}

class _TagGroupSection extends StatelessWidget {
  final TagPickerGroup group;
  final bool open;
  final VoidCallback? onToggle;
  final Widget chips;

  const _TagGroupSection({
    required this.group,
    required this.open,
    required this.onToggle,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final category = group.category;
    final name = category?.name ?? l10n.tagCategoryUncategorized;

    return DecoratedBox(
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: open ? 0.25 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 20, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 6),
                    if (category != null)
                      TagIconGlyph(
                        icon: category.icon,
                        iconType: category.iconType,
                        fallbackIcon: Icons.folder_rounded,
                        color: category.resolvedColor(context),
                        size: 18,
                      )
                    else
                      Icon(Icons.folder_open_rounded,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 26),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        '${group.tags.length}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 2, 0, 12),
              child: chips,
            ),
        ],
      ),
    );
  }
}
