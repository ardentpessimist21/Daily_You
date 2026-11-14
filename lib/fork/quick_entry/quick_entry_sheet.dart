// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/quick_entry/quick_entry_service.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/entry_mood_picker.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The quick-entry sheet (Update Q). It runs in its own small window over
/// whatever app is open, or over the lock screen, where it is write-only:
/// tags, places and the full editor ask to unlock first.
class QuickEntryPage extends StatefulWidget {
  const QuickEntryPage({super.key, required this.ready});

  /// False when the journal couldn't be opened (e.g. Daily You was never
  /// opened yet), so there's nothing to save into.
  final bool ready;

  static const MethodChannel channel = MethodChannel('daily_you/quick_entry');

  @override
  State<QuickEntryPage> createState() => _QuickEntryPageState();
}

class _QuickEntryPageState extends State<QuickEntryPage> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// Keeps the text box the same box when the layout changes for the
  /// keyboard. Without it the box is rebuilt, loses the keyboard, and the
  /// layout flips back (3.7.0.51: the keyboard wouldn't stay up).
  final GlobalKey _textFieldKey = GlobalKey();

  QuickEntryTarget _target = QuickEntryTarget.newEntry;
  Entry? _lastEntry;
  int? _mood;

  /// Whether the mood was picked here. Adding to an entry without touching
  /// the mood keeps the entry's own.
  bool _moodTouched = false;
  TagAttachmentSource _tags = TagAttachmentSource(supportsValues: true);
  List<Place> _places = [];
  bool _locked = false;
  bool _moodOpen = false;
  bool _saving = false;
  bool _loaded = false;

  bool get _keepOpen =>
      ConfigProvider.instance.get<bool>(Settings.quickEntryKeepOpen);

  bool get _toLast =>
      _target == QuickEntryTarget.lastEntry && _lastEntry != null;

  bool get _canSave => widget.ready && !_saving && _text.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _tags.addListener(_onTagsChanged);
    QuickEntryPage.channel.setMethodCallHandler((call) async {
      // The sheet was opened again while already showing, e.g. from a
      // second selection: add that text.
      if (call.method == 'launch') _applyLaunch(call.arguments);
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _tags.removeListener(_onTagsChanged);
    super.dispose();
  }

  void _onTagsChanged() => setState(() {});

  Future<void> _load() async {
    final target = await QuickEntryService.rememberedTarget();
    Object? launch;
    try {
      launch = await QuickEntryPage.channel.invokeMethod('getLaunch');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _lastEntry = widget.ready ? QuickEntryService.lastEntryToday() : null;
      _target = target;
      _loaded = true;
    });
    _applyLaunch(launch);
    _resetMood();
  }

  void _applyLaunch(Object? launch) {
    if (launch is! Map) return;
    final locked = launch['locked'] == true;
    final text = (launch['text'] as String?)?.trim() ?? '';
    setState(() {
      _locked = locked;
      if (text.isNotEmpty) {
        final before = _text.text.trimRight();
        _text.text = before.isEmpty ? text : '$before\n$text';
        _text.selection = TextSelection.collapsed(offset: _text.text.length);
      }
    });
  }

  // Phone lock

  /// Asks to unlock the phone when it's locked. True once unlocked.
  Future<bool> _unlock() async {
    if (!_locked) return true;
    bool unlocked = false;
    try {
      unlocked =
          await QuickEntryPage.channel.invokeMethod<bool>('requestUnlock') ??
              false;
    } catch (_) {}
    if (unlocked && mounted) {
      setState(() => _locked = false);
      if (!_moodTouched) _resetMood();
    }
    return unlocked;
  }

  // Save to

  Future<void> _setTarget(QuickEntryTarget target) async {
    if (target == QuickEntryTarget.lastEntry && _lastEntry == null) return;
    setState(() => _target = target);
    _resetMood();
    await QuickEntryService.rememberTarget(target);
  }

  /// No mood for a new entry; the entry's own when adding to it (not shown
  /// while the phone is locked).
  void _resetMood() {
    if (!mounted) return;
    setState(() {
      _moodTouched = false;
      _mood = _toLast && !_locked ? _lastEntry!.mood : null;
    });
  }

  void _pickMood(int? mood) => setState(() {
        _mood = mood;
        _moodTouched = true;
      });

  // Tags and places

  Future<void> _pickTags() async {
    if (!await _unlock() || !mounted) return;
    await showAppDialog(
      context: context,
      builder: (_) =>
          TagPickerDialog(mode: TagPickerMode.attach, source: _tags),
    );
  }

  Future<void> _pickPlace() async {
    if (!await _unlock() || !mounted) return;
    await Places.showPlaceSheet(context, null, onPicked: (place) {
      final key = place.name.trim().toLowerCase();
      if (_places.any((p) => p.name.trim().toLowerCase() == key)) return;
      setState(() => _places = [..._places, place]);
    });
  }

  String _tagsLabel() {
    final ids = _tags.attachedTagIds;
    if (ids.isEmpty) return 'Tags';
    final names = [
      for (final tag in TagsProvider.instance.tags)
        if (ids.contains(tag.id)) tag.name
    ];
    if (names.isEmpty) return 'Tags';
    return names.length == 1
        ? names.first
        : '${names.first} +${names.length - 1}';
  }

  String _placeLabel() {
    if (_places.isEmpty) return 'Place';
    final first = _places.first.name.trim();
    return _places.length == 1 ? first : '$first +${_places.length - 1}';
  }

  // Saving

  String _timeText(DateTime time) => TimeManager.localizedTimeFormat(
          context, TimeManager.currentLocale(context))
      .format(time);

  Future<QuickEntryResult?> _save() async {
    if (!_canSave) return null;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final result = await QuickEntryService.save(
        text: _text.text,
        target: _target,
        mood: _mood,
        keepMood: _toLast && !_moodTouched,
        tags: _tags.toEntryTags(-1),
        places: _places,
        at: now,
        timeText: _timeText(now),
      );
      await QuickEntryService.flushExternalCopy();
      try {
        await QuickEntryPage.channel.invokeMethod('saved', {
          'lastLabel': _timeText(
              QuickEntryService.lastEntryToday()?.timeCreate ??
                  result.entry.timeCreate),
        });
      } catch (_) {}
      return result;
    } catch (error) {
      if (mounted) _snack('Couldn\'t save: $error');
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _message(QuickEntryResult result) {
    if (result.added) {
      return 'Added to the ${_timeText(result.entry.timeCreate)} entry';
    }
    return QuickEntryService.messageFor(result);
  }

  Future<void> _onSavePressed() async {
    final result = await _save();
    if (result == null || !mounted) return;

    if (!_keepOpen) {
      await _close(message: _message(result));
      return;
    }

    // Keep open: clear the text. A new entry starts fresh; adding to the
    // last entry keeps mood, tags and place for the next note.
    final wasLast = _toLast;
    setState(() {
      _text.clear();
      _lastEntry = QuickEntryService.lastEntryToday();
      if (!wasLast) {
        _mood = null;
        _moodTouched = false;
        _tags.removeListener(_onTagsChanged);
        _tags = TagAttachmentSource(supportsValues: true)
          ..addListener(_onTagsChanged);
        _places = [];
      }
    });
    _snack(_message(result));
    _focus.requestFocus();
  }

  Future<void> _openFullEditor() async {
    if (!await _unlock() || !mounted) return;
    int id;
    if (_text.text.trim().isNotEmpty) {
      final result = await _save();
      if (result == null) return;
      id = result.entry.id!;
    } else {
      id = _toLast ? _lastEntry!.id! : -1;
    }
    try {
      await QuickEntryPage.channel.invokeMethod('openInApp', {'id': id});
    } catch (_) {}
  }

  Future<void> _close({String? message}) async {
    try {
      await QuickEntryPage.channel.invokeMethod('close', {'message': message});
    } catch (_) {
      await SystemNavigator.pop();
    }
  }

  /// Back, ✕ or a tap outside: asks first when there's unsaved text.
  Future<void> _tryClose() async {
    if (_text.text.trim().isEmpty) {
      await _close();
      return;
    }
    final discard = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this note?'),
        content: const Text('What you typed won\'t be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep writing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true) await _close();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  // Layout

  @override
  Widget build(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final topGap = MediaQuery.paddingOf(context).top + 72;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_tryClose());
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _tryClose,
                child: const ColoredBox(color: Color(0x73000000)),
              ),
            ),
            if (keyboardUp)
              Positioned(
                left: 0,
                right: 0,
                top: topGap,
                bottom: 0,
                child: _sheet(context, compact: true),
              )
            else
              Align(
                alignment: Alignment.bottomCenter,
                child: _sheet(context, compact: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheet(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset =
        compact ? 8.0 : MediaQuery.paddingOf(context).bottom + 16;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset),
        child: !_loaded
            ? const SizedBox(
                height: 160, child: Center(child: CircularProgressIndicator()))
            : !widget.ready
                ? _notReady(context)
                : Column(
                    mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _handle(cs),
                      const SizedBox(height: 8),
                      compact ? _compactHeader(context) : _header(context),
                      if (!compact) ...[
                        const SizedBox(height: 12),
                        _label(context, _moodLabel()),
                        const SizedBox(height: 4),
                        EntryMoodPicker(
                          moodValue: _mood,
                          onChangedMood: _pickMood,
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (compact)
                        Expanded(child: _textField(context, expand: true))
                      else
                        SizedBox(height: 150, child: _textField(context)),
                      if (!compact) ...[
                        if (_toLast) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Added at the end of the ${_timeText(_lastEntry!.timeCreate)} entry, under a "${_timeText(DateTime.now())}" line',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _chipsRow(context),
                        const SizedBox(height: 16),
                        _label(context, 'Save to'),
                        const SizedBox(height: 8),
                        _saveToSwitch(context),
                        const SizedBox(height: 12),
                        _actionsRow(context),
                      ] else ...[
                        if (_moodOpen) ...[
                          const SizedBox(height: 8),
                          _moodPopup(context),
                        ],
                        const SizedBox(height: 8),
                        _compactBar(context),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _notReady(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _handle(Theme.of(context).colorScheme),
        const SizedBox(height: 16),
        Text('Open Daily You once first',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
            'Quick entry saves into your journal, which isn\'t set up on this phone yet.'),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(onPressed: _close, child: const Text('Close')),
        ),
      ],
    );
  }

  Widget _handle(ColorScheme cs) => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  String _dateLine(BuildContext context) {
    final locale = TimeManager.currentLocale(context);
    final now = DateTime.now();
    return '${DateFormat.yMMMEd(locale).format(now)} · ${_timeText(now)}';
  }

  String _moodLabel() {
    if (!_toLast) return 'How are you feeling?';
    if (_locked && !_moodTouched) {
      return 'Mood (keeps the entry\'s mood unless you pick one)';
    }
    return 'Mood of the ${_timeText(_lastEntry!.timeCreate)} entry';
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );

  Widget _closeButton() => IconButton(
        tooltip: 'Close',
        onPressed: _tryClose,
        icon: const Icon(Icons.close_rounded),
      );

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick entry',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(_dateLine(context),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        _closeButton(),
      ],
    );
  }

  Widget _compactHeader(BuildContext context) {
    final theme = Theme.of(context);
    final locale = TimeManager.currentLocale(context);
    final now = DateTime.now();
    return Row(
      children: [
        Text('Quick entry',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${DateFormat.MMMd(locale).format(now)} · ${_timeText(now)}',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        IconButton(
          tooltip: 'Open full editor',
          onPressed: _openFullEditor,
          icon: const Icon(Icons.open_in_new_rounded),
        ),
        _closeButton(),
      ],
    );
  }

  Widget _textField(BuildContext context, {bool expand = false}) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      key: _textFieldKey,
      controller: _text,
      focusNode: _focus,
      autofocus: true,
      expands: true,
      maxLines: null,
      minLines: null,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'What\'s on your mind?',
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary),
        ),
      ),
    );
  }

  Widget _chipsRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.local_offer_outlined, size: 18),
          label: Text(_tagsLabel()),
          onPressed: _pickTags,
        ),
        // With a place, the ✕ to remove it sits inside the pill
        if (_places.isEmpty)
          ActionChip(
            avatar: const Icon(Icons.place_outlined, size: 18),
            label: Text(_placeLabel()),
            onPressed: _pickPlace,
          )
        else
          InputChip(
            avatar: const Icon(Icons.place_outlined, size: 18),
            label: Text(_placeLabel()),
            onPressed: _pickPlace,
            onDeleted: () => setState(() => _places = []),
            deleteIcon: const Icon(Icons.close_rounded, size: 18),
            deleteButtonTooltipMessage: 'Remove place',
          ),
      ],
    );
  }

  Widget _saveToSwitch(BuildContext context) {
    final theme = Theme.of(context);
    final hasLast = _lastEntry != null;
    final lastSubtitle = hasLast
        ? 'Today, ${_timeText(_lastEntry!.timeCreate)}'
        : 'No entry today yet';
    final selected = hasLast ? _target : QuickEntryTarget.newEntry;

    return SegmentedButton<QuickEntryTarget>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: QuickEntryTarget.lastEntry,
          enabled: hasLast,
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Last entry'),
              Text(lastSubtitle,
                  style: theme.textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const ButtonSegment(
          value: QuickEntryTarget.newEntry,
          label: Text('New entry'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => _setTarget(value.first),
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.fromHeight(52)),
      ),
    );
  }

  String get _saveLabel => _toLast ? 'Add to entry' : 'Save';

  Widget _actionsRow(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _openFullEditor,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Open full editor'),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _canSave ? _onSavePressed : null,
          icon: const Icon(Icons.check_rounded),
          label: Text(_saveLabel),
        ),
      ],
    );
  }

  Widget _moodPopup(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(28),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: EntryMoodPicker(
          moodValue: _mood,
          onChangedMood: (mood) {
            _pickMood(mood);
            setState(() => _moodOpen = false);
          },
        ),
      ),
    );
  }

  Widget _compactBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasLast = _lastEntry != null;

    Widget roundButton(
            {required String tooltip,
            required Widget child,
            required VoidCallback onPressed}) =>
        IconButton.outlined(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            side: BorderSide(color: cs.outlineVariant),
            fixedSize: const Size(44, 44),
          ),
          icon: child,
        );

    return Row(
      children: [
        roundButton(
          tooltip: _mood == null ? 'Add mood' : 'Mood',
          onPressed: () => setState(() => _moodOpen = !_moodOpen),
          child: _mood == null
              ? const Icon(Icons.add_reaction_outlined)
              : MoodIcon(moodValue: _mood, size: 22, allowScaling: false),
        ),
        const SizedBox(width: 6),
        roundButton(
          tooltip: _tagsLabel(),
          onPressed: _pickTags,
          child: Badge(
            isLabelVisible: _tags.attachedTagIds.isNotEmpty,
            label: Text('${_tags.attachedTagIds.length}'),
            child: const Icon(Icons.local_offer_outlined),
          ),
        ),
        const SizedBox(width: 6),
        roundButton(
          tooltip: _placeLabel(),
          onPressed: _pickPlace,
          child: Badge(
            isLabelVisible: _places.isNotEmpty,
            smallSize: 8,
            child: const Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: OutlinedButton(
            onPressed: () {
              if (!hasLast) {
                _snack('No entry today yet');
                return;
              }
              _setTarget(_toLast
                  ? QuickEntryTarget.newEntry
                  : QuickEntryTarget.lastEntry);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.only(left: 12, right: 6),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _toLast ? 'Last entry' : 'New entry',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _canSave ? _onSavePressed : null,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(_toLast ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
