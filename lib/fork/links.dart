// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/places.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/entries_list_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Links between entries, and to websites, written as ordinary Markdown:
/// `[Night shift](entry:42)` or `[Rota](https://…)`. Plain text keeps them
/// in backups and exports, with no change to the database.
class EntryLinks {
  static const String scheme = 'entry';
  static final RegExp _entryUri = RegExp(r'^entry:(\d+)$');
  static final RegExp _markdownLink = RegExp(
      r'^\[([^\]\n]*)\]\(([a-z][a-z0-9+.-]*:[^)\s]+)\)$',
      caseSensitive: false);
  static final RegExp _anyLink =
      RegExp(r'^[a-z][a-z0-9+.-]*:\S+$', caseSensitive: false);

  static String uriFor(int id) => '$scheme:$id';

  /// The entry id in an `entry:42` address, or null.
  static int? idOf(String url) {
    final match = _entryUri.firstMatch(url.trim());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// A short name for [entry]: its first heading or first few words.
  static String titleOf(Entry entry, {int maxWords = 6}) {
    for (final rawLine in entry.text.split('\n')) {
      final line = plainText(rawLine);
      if (line.isEmpty) continue;
      final words = line.split(RegExp(r'\s+'));
      if (words.length <= maxWords) return line;
      return '${words.take(maxWords).join(' ')}…';
    }
    return '';
  }

  /// [markdown] without its formatting marks, on one line.
  static String plainText(String markdown) => markdown
      .replaceAll(RegExp(r'^\s{0,3}(#{1,6}|>+|[-*+]|\d+[.)])\s+'), '')
      .replaceAll(RegExp(r'^\[[ xX]\]\s+'), '')
      .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
      .replaceAll(RegExp(r'(\*\*|__|==|~~|`|\*|_)'), '')
      .replaceAll(RegExp(r'[\[\]]'), '')
      .trim();

  /// `[text](address)`, with brackets in [text] removed so it stays a link.
  static String markdown(String text, String address) =>
      '[${text.replaceAll(RegExp(r'[\[\]]'), '').trim()}]($address)';

  static String markdownForEntry(Entry entry, {String? text}) {
    final shown =
        (text?.trim().isNotEmpty ?? false) ? text! : _fallbackTitle(entry);
    return markdown(shown, uriFor(entry.id!));
  }

  static String _fallbackTitle(Entry entry) {
    final title = titleOf(entry);
    return title.isNotEmpty ? title : entry.timeCreate.toIso8601String();
  }

  /// Splits a copied `[text](address)` link into its parts, or null.
  static (String, String)? parseMarkdownLink(String text) {
    final match = _markdownLink.firstMatch(text.trim());
    return match == null ? null : (match.group(1)!, match.group(2)!);
  }

  static bool looksLikeAddress(String text) => _anyLink.hasMatch(text.trim());

  /// Copies a link to [entry] that turns into a named link when pasted.
  static Future<void> copyLink(BuildContext context, Entry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: markdownForEntry(entry)));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.linkCopied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ));
  }

  /// Opens a tapped link: entries in the app, anything else outside it.
  static Future<void> open(BuildContext context, String url) async {
    final id = idOf(url);
    if (id != null) {
      final provider = EntriesProvider.instance;
      final index = provider.getIndexOfEntry(id);
      if (index < 0) {
        _say(context, AppLocalizations.of(context)!.linkEntryMissing);
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        builder: (context) => EntriesListPage(
          index: index,
          getEntries: () => EntriesProvider.instance.entries,
        ),
      ));
      return;
    }
    final uri = Uri.tryParse(url.trim());
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      _say(context, AppLocalizations.of(context)!.linkCannotOpen);
    }
  }

  static void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2000),
      ));
  }

  /// Opens the "Add link" box and puts the link where the cursor or
  /// selection was. Highlighted words become the link's text.
  static Future<void> showAddLinkDialog(
      BuildContext context, TextEditingController controller,
      {int? currentEntryId}) async {
    final value = controller.value;
    final selection = value.selection;
    final selected = selection.isValid && !selection.isCollapsed
        ? selection.textInside(value.text)
        : '';
    final copied =
        (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!context.mounted) return;

    final link = await showAppDialog<String>(
      context: context,
      builder: (context) => _AddLinkDialog(
        selectedText: selected,
        copied: copied,
        currentEntryId: currentEntryId,
      ),
    );
    if (link == null) return;

    final text = controller.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, link),
      selection: TextSelection.collapsed(offset: start + link.length),
    );
  }
}

enum _LinkKind { entry, website }

class _AddLinkDialog extends StatefulWidget {
  const _AddLinkDialog({
    required this.selectedText,
    required this.copied,
    this.currentEntryId,
  });

  final String selectedText;
  final String copied;
  final int? currentEntryId;

  @override
  State<_AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<_AddLinkDialog> {
  late final TextEditingController _text =
      TextEditingController(text: widget.selectedText);
  final TextEditingController _address = TextEditingController();
  _LinkKind _kind = _LinkKind.entry;
  Entry? _entry;

  @override
  void initState() {
    super.initState();
    // A copied entry link fills in "Link to"; a copied web address fills in
    // the website box.
    final copied = widget.copied;
    final parsed = EntryLinks.parseMarkdownLink(copied);
    final address = parsed?.$2 ?? copied;
    final id = EntryLinks.idOf(address);
    if (id != null) {
      _entry = EntriesProvider.instance.entries
          .where((entry) => entry.id == id)
          .firstOrNull;
    } else if (RegExp(r'^https?://\S+$').hasMatch(address)) {
      _address.text = address;
      _kind = _LinkKind.website;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _result() {
    final shown = _text.text.trim();
    if (_kind == _LinkKind.entry) {
      final entry = _entry;
      if (entry == null) return null;
      return EntryLinks.markdownForEntry(entry, text: shown);
    }
    var address = _address.text.trim();
    if (address.isEmpty) return null;
    if (!EntryLinks.looksLikeAddress(address)) address = 'https://$address';
    return EntryLinks.markdown(shown.isEmpty ? address : shown, address);
  }

  Future<void> _chooseEntry() async {
    final picked = await Navigator.of(context).push<Entry>(MaterialPageRoute(
      builder: (context) =>
          EntryPickerPage(excludeEntryId: widget.currentEntryId),
    ));
    if (picked != null && mounted) setState(() => _entry = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final entry = _entry;
    return AlertDialog(
      title: Text(l10n.linkAddTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_LinkKind>(
              segments: [
                ButtonSegment(
                    value: _LinkKind.entry,
                    icon: const Icon(Icons.article_rounded),
                    label: Text(l10n.linkKindEntry)),
                ButtonSegment(
                    value: _LinkKind.website,
                    icon: const Icon(Icons.public_rounded),
                    label: Text(l10n.linkKindWebsite)),
              ],
              selected: {_kind},
              onSelectionChanged: (kinds) =>
                  setState(() => _kind = kinds.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.linkTextToShow,
                hintText: _kind == _LinkKind.entry && entry != null
                    ? EntryLinks.titleOf(entry)
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_kind == _LinkKind.entry)
              Material(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.article_rounded),
                  title: Text(entry == null
                      ? l10n.linkChooseEntry
                      : (EntryLinks.titleOf(entry).isEmpty
                          ? TimeManager.formatDate(entry.timeCreate, context)
                          : EntryLinks.titleOf(entry))),
                  subtitle: entry == null
                      ? null
                      : Text(TimeManager.formatDateWithWeekday(
                          entry.timeCreate, context)),
                  trailing: entry == null
                      ? const Icon(Icons.chevron_right_rounded)
                      : IconButton(
                          tooltip: l10n.linkClear,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _entry = null),
                        ),
                  onTap: _chooseEntry,
                ),
              )
            else
              TextField(
                controller: _address,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.linkWebAddress,
                  hintText: 'https://',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _result() == null
              ? null
              : () => Navigator.pop(context, _result()),
          child: Text(l10n.linkAdd),
        ),
      ],
    );
  }
}

/// Picks an entry to link to: search across the whole diary, or narrow it
/// to one day with the date bar.
class EntryPickerPage extends StatefulWidget {
  const EntryPickerPage({super.key, this.excludeEntryId});

  final int? excludeEntryId;

  @override
  State<EntryPickerPage> createState() => _EntryPickerPageState();
}

class _EntryPickerPageState extends State<EntryPickerPage> {
  final TextEditingController _search = TextEditingController();
  DateTime? _day;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final entries = EntriesProvider.instance.entries;
    final picked = await TimeManager.pickDate(
      context,
      initialDate: _day ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: entries.isEmpty
          ? DateTime.now()
          : entries
              .map((entry) => entry.timeCreate)
              .reduce((a, b) => a.isAfter(b) ? a : b),
      selectableDayPredicate: (date) =>
          EntriesProvider.instance.getEntriesForDate(date).isNotEmpty,
    );
    if (picked != null && mounted) setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _search.text.trim().toLowerCase();
    final day = _day;
    final entries = EntriesProvider.instance.entries.where((entry) {
      if (entry.id == null || entry.id == widget.excludeEntryId) return false;
      if (day != null && !TimeManager.isSameDay(entry.timeCreate, day)) {
        return false;
      }
      return query.isEmpty || entry.text.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.linkChooseEntry)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: SearchBar(
              controller: _search,
              elevation: const WidgetStatePropertyAll(0),
              leading: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.search_rounded),
              ),
              hintText: l10n.searchLogsHint,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                InputChip(
                  avatar: const Icon(Icons.calendar_month_rounded),
                  label: Text(day == null
                      ? l10n.linkAnyDate
                      : TimeManager.formatDateWithWeekday(day, context)),
                  onPressed: _pickDay,
                  onDeleted:
                      day == null ? null : () => setState(() => _day = null),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(l10n.noResults))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final title = EntryLinks.titleOf(entry);
                      return ListTile(
                        title: Text(
                          title.isEmpty ? l10n.writeSomethingHint : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                            '${TimeManager.formatDateWithWeekday(entry.timeCreate, context)} · '
                            '${TimeManager.localizedTimeFormat(context, TimeManager.currentLocale(context)).format(entry.timeCreate)}'),
                        onTap: () => Navigator.pop(context, entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tidies pasted links: a copied link pasted over highlighted words wraps
/// them, and a place shared from Google Maps becomes `📍 Name`.
class LinkPasteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final oldSelection = oldValue.selection;
    if (!oldSelection.isValid) return newValue;
    final start = oldSelection.start;
    final oldEnd = oldSelection.end;
    final removedAfter = oldValue.text.length - oldEnd;
    final newEnd = newValue.text.length - removedAfter;
    if (newEnd < start || newEnd > newValue.text.length) return newValue;
    // Only replacements of the selection, and only multi-character ones, so
    // ordinary typing is never touched.
    if (!newValue.text.startsWith(oldValue.text.substring(0, start)) ||
        !newValue.text.endsWith(oldValue.text.substring(oldEnd))) {
      return newValue;
    }
    final inserted = newValue.text.substring(start, newEnd);
    if (inserted.length < 4) return newValue;

    final replacement = tidy(inserted,
        selectedText: oldSelection.isCollapsed
            ? ''
            : oldSelection.textInside(oldValue.text));
    if (replacement == null) return newValue;
    final text = newValue.text.replaceRange(start, newEnd, replacement);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  /// What pasting [inserted] over [selectedText] should give, or null to
  /// paste as it is.
  static String? tidy(String inserted, {String selectedText = ''}) {
    final trimmed = inserted.trim();
    final selected = selectedText.trim();
    final hasWords = selected.isNotEmpty && !selected.contains('\n');

    final copiedLink = EntryLinks.parseMarkdownLink(trimmed);
    if (copiedLink != null) {
      return hasWords ? EntryLinks.markdown(selected, copiedLink.$2) : null;
    }
    final place = Places.fromShared(trimmed);
    if (place != null) {
      return hasWords ? Places.named(selected, place.$2) : place.$3;
    }
    if (hasWords && EntryLinks.looksLikeAddress(trimmed)) {
      return EntryLinks.markdown(selected, trimmed);
    }
    return null;
  }
}
