// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/quick_entry/quick_entry_service.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/pages/audio_recorder_page.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/entry_attachment_actions.dart';
import 'package:daily_you/widgets/entry_mood_picker.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:daily_you/pages/attachment_view_page.dart';
import 'package:daily_you/widgets/attachment_tile_background.dart';
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

  /// Photos, videos and recordings for this note (Update 68), already in
  /// storage: saved onto the entry, or deleted if the note is dropped.
  List<NewAttachment> _attachments = [];
  bool _capturing = false;
  bool _locked = false;
  bool _moodOpen = false;
  bool _saving = false;
  bool _loaded = false;

  bool get _keepOpen =>
      ConfigProvider.instance.get<bool>(Settings.quickEntryKeepOpen);

  bool get _toLast =>
      _target == QuickEntryTarget.lastEntry && _lastEntry != null;

  bool get _hasContent =>
      _text.text.trim().isNotEmpty || _attachments.isNotEmpty;

  bool get _canSave => widget.ready && !_saving && _hasContent;

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
    // Dropped without saving: the files go too
    if (_attachments.isNotEmpty) {
      unawaited(EntryAttachmentActions.deleteStoredAttachments(_attachments));
    }
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
    final capture = QuickCaptureRequest.parse(launch['capture'] as String?);
    if (capture != null) {
      // From the floating button's pie: take it straight away
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture(
          capture.kind,
          front: capture.front,
          autoStart: capture.autoStart)));
    }
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

  // Attachments (Update 68)

  /// [front] picks the lens for photo and video; [autoStart] starts the
  /// audio recorder straight away (the pie's second ring, 3.7.0.68).
  Future<void> _capture(QuickCapture kind,
      {bool? front, bool autoStart = false}) async {
    if (_capturing || !await _unlock() || !mounted) return;
    setState(() => _capturing = true);
    try {
      List<NewAttachment> added;
      switch (kind) {
        case QuickCapture.photo:
          added = await EntryAttachmentActions.storeAll(
              await EntryAttachmentActions.takePhoto(front: front));
        case QuickCapture.video:
          added = await EntryAttachmentActions.storeAll(
              await EntryAttachmentActions.takeVideo(front: front));
        case QuickCapture.audio:
          final recorded = await Navigator.of(context).push<NewAttachment>(
            MaterialPageRoute(
              allowSnapshotting: false,
              fullscreenDialog: true,
              builder: (context) => AudioRecorderPage(autoStart: autoStart),
            ),
          );
          added = recorded == null ? const [] : [recorded];
        case QuickCapture.gallery:
          added = await EntryAttachmentActions.storeAll(
              await EntryAttachmentActions.pickMediaFromGallery());
      }
      if (!mounted) {
        await EntryAttachmentActions.deleteStoredAttachments(added);
        return;
      }
      if (added.isNotEmpty) {
        setState(() => _attachments = [..._attachments, ...added]);
      }
    } catch (error) {
      if (mounted) _snack('Couldn\'t attach: $error');
    } finally {
      if (mounted) setState(() => _capturing = false);
      _focus.requestFocus();
    }
  }

  Future<void> _removeAttachments(List<NewAttachment> gone) async {
    setState(() => _attachments = [
          for (final attachment in _attachments)
            if (!gone.contains(attachment)) attachment
        ]);
    await EntryAttachmentActions.deleteStoredAttachments(gone);
  }

  /// The chip's icon: the one kind attached, or 📎 for a mix (3.7.0.68).
  IconData _attachmentsIcon() {
    final kinds = {for (final attachment in _attachments) attachment.type};
    if (kinds.length != 1) return Icons.attach_file_rounded;
    return switch (kinds.single) {
      AttachmentType.image => Icons.photo_outlined,
      AttachmentType.video => Icons.videocam_outlined,
      AttachmentType.audio => Icons.mic_none_rounded,
    };
  }

  /// "2 photos · 1 audio".
  String _attachmentsLabel() {
    int count(AttachmentType type) =>
        _attachments.where((attachment) => attachment.type == type).length;
    final photos = count(AttachmentType.image);
    final videos = count(AttachmentType.video);
    final audio = count(AttachmentType.audio);
    return [
      if (photos > 0) photos == 1 ? '1 photo' : '$photos photos',
      if (videos > 0) videos == 1 ? '1 video' : '$videos videos',
      if (audio > 0) '$audio audio',
    ].join(' · ');
  }

  Future<void> _openAttachMenu(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final picked = await showMenu<QuickCapture>(
      context: buttonContext,
      // Leave the text box focused: taking focus closed the keyboard and
      // flipped the sheet's layout under the menu (3.7.0.68)
      requestFocus: false,
      position: RelativeRect.fromLTRB(topLeft.dx, topLeft.dy - 8,
          overlay.size.width - topLeft.dx, overlay.size.height - topLeft.dy),
      items: [
        for (final kind in QuickCapture.values)
          PopupMenuItem(
            value: kind,
            child: Row(
              children: [
                Icon(kind.icon),
                const SizedBox(width: 12),
                Text(kind.label),
              ],
            ),
          ),
      ],
    );
    if (picked != null) await _capture(picked);
  }

  /// The attachments as the editor's tiles (3.7.0.68): a preview each,
  /// ✕ to remove one, sideways to see more, tap to view full screen.
  Future<void> _showAttachmentList() async {
    final now = DateTime.now();
    List<EntryAttachment> asTiles() => [
          for (final (index, attachment) in _attachments.indexed)
            EntryAttachment(
                entryId: null,
                type: attachment.type,
                filePath: attachment.filePath,
                rank: _attachments.length - index,
                timeCreate: now),
        ];
    await showAppDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) {
          final tiles = asTiles();
          return AlertDialog(
            title: const Text('Attached'),
            contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _attachments.isEmpty
                          ? 'Nothing attached'
                          : _attachmentsLabel(),
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (tiles.isNotEmpty)
                    SizedBox(
                      key: const ValueKey('quick-entry-attachment-carousel'),
                      height: 124,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: tiles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (_, index) => SizedBox(
                          width: 124,
                          child: Card.filled(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(dialogContext).push(
                                      AttachmentViewPage.route(
                                          attachments: tiles, index: index)),
                                  child: AttachmentTileBackground(
                                      attachment: tiles[index]),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    tooltip: 'Remove',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    icon: Icon(Icons.close_rounded,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 6),
                                        ]),
                                    onPressed: () async {
                                      await _removeAttachments(
                                          [_attachments[index]]);
                                      setLocal(() {});
                                      if (_attachments.isEmpty &&
                                          dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 📎 and the attachment chip, in the text box's bottom corner.
  Widget _attachBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (buttonContext) => SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              key: const ValueKey('quick-entry-attach'),
              padding: EdgeInsets.zero,
              tooltip: 'Attach',
              // Tonal so it stands out from the text box (3.7.0.68)
              style: IconButton.styleFrom(
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  side: BorderSide(
                      color: cs.onSecondaryContainer.withValues(alpha: 0.25))),
              iconSize: 19,
              onPressed:
                  _capturing ? null : () => _openAttachMenu(buttonContext),
              icon: _capturing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.attach_file_rounded),
            ),
          ),
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(width: 6),
          InputChip(
            key: const ValueKey('quick-entry-attachments'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: cs.primaryContainer,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            avatar: Icon(_attachmentsIcon(),
                size: 16, color: cs.onPrimaryContainer),
            label: Text(_attachmentsLabel(),
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer)),
            onPressed: _showAttachmentList,
            deleteIcon: Icon(Icons.close_rounded,
                size: 16, color: cs.onPrimaryContainer),
            deleteButtonTooltipMessage: 'Remove all',
            onDeleted: () => _removeAttachments([..._attachments]),
          ),
        ],
      ],
    );
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
        attachments: _attachments,
        at: now,
        timeText: _timeText(now),
      );
      // They're on the entry now
      _attachments = [];
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
    // Text or attachments: saved first, so nothing is lost (Update 68)
    if (_hasContent) {
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
    if (!_hasContent) {
      await _close();
      return;
    }
    final discard = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this note?'),
        content: Text(_attachments.isEmpty
            ? 'What you typed won\'t be saved.'
            : 'What you typed and attached won\'t be saved.'),
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
    // Title over the date, so large text never wraps "Quick entry" or
    // squeezes the date beside it
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quick entry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                '${DateFormat.MMMd(locale).format(now)} · ${_timeText(now)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
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
    return Stack(
      children: [
        Positioned.fill(child: _textInput(context)),
        Positioned(left: 8, bottom: 8, child: _attachBar(context)),
      ],
    );
  }

  Widget _textInput(BuildContext context) {
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
        // Room for 📎 at the bottom
        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 52),
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
        // Fills the space up to Save, so "New entry" fits even with large
        // text (3.7.0.52 cut it to "N…" next to an empty gap)
        Expanded(
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
            // "New entry", or just "New" when large text leaves no room
            child: LayoutBuilder(builder: (context, box) {
              final full = _toLast ? 'Last entry' : 'New entry';
              final short = _toLast ? 'Last' : 'New';
              final style = DefaultTextStyle.of(context).style;
              final painter = TextPainter(
                text: TextSpan(text: full, style: style),
                textScaler: MediaQuery.textScalerOf(context),
                textDirection: Directionality.of(context),
                maxLines: 1,
              )..layout();
              final fits = painter.width + 24 <= box.maxWidth;
              painter.dispose();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      fits ? full : short,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        // A round ✓ above the keyboard; the full sheet keeps "Save" / "Add
        // to entry" in words
        IconButton.filled(
          tooltip: _toLast ? 'Add' : 'Save',
          onPressed: _canSave ? _onSavePressed : null,
          // Colours set here: the app's icon theme otherwise tints the ✓
          // almost the same as the button (3.7.0.53)
          style: IconButton.styleFrom(
            fixedSize: const Size(44, 44),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
            disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
          ),
          icon: Icon(Icons.check_rounded,
              color: _canSave
                  ? cs.onPrimary
                  : cs.onSurface.withValues(alpha: 0.38)),
        ),
      ],
    );
  }
}

/// What the 📎 menu and the floating button's pie can take (Update 68).
enum QuickCapture {
  photo('photo', 'Take photo', Icons.photo_camera_outlined),
  video('video', 'Record video', Icons.videocam_outlined),
  audio('audio', 'Record audio', Icons.mic_none_rounded),
  gallery('gallery', 'From gallery', Icons.photo_library_outlined);

  const QuickCapture(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static QuickCapture? fromKey(String? key) =>
      values.where((kind) => kind.key == key).firstOrNull;
}

/// What the floating button's pie asks for (3.7.0.68): "photo",
/// "photo_front", "video_back", "audio_auto" and so on.
class QuickCaptureRequest {
  const QuickCaptureRequest(this.kind, {this.front, this.autoStart = false});

  final QuickCapture kind;

  /// The lens for photo and video, or null for the camera's own choice.
  final bool? front;
  final bool autoStart;

  static QuickCaptureRequest? parse(String? key) {
    if (key == null) return null;
    final parts = key.split('_');
    final kind = QuickCapture.fromKey(parts.first);
    if (kind == null) return null;
    final extra = parts.length > 1 ? parts[1] : null;
    return QuickCaptureRequest(kind,
        front: switch (extra) {
          'front' => true,
          'back' => false,
          _ => null,
        },
        autoStart: extra == 'auto');
  }
}
