// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Mood colours and names (Mood-coloured calendar, 3.7.0.57).
///
/// Each of the five moods (2 = Very Pleasant … −2 = Very Unpleasant) has a
/// colour and a name you can change on Settings › Look and feel › Moods. The
/// colours fill the Home calendar's days when "Mood colours" is on (the
/// calendar's 👁 menu and the Moods page are the same switch).
class Moods {
  Moods._();

  /// Best mood first, as the Moods page lists them.
  static const values = [2, 1, 0, -1, -2];

  static const defaultNames = {
    2: 'Very Pleasant',
    1: 'Pleasant',
    0: 'Neutral',
    -1: 'Unpleasant',
    -2: 'Very Unpleasant',
  };

  static const colorSettings = <int, Setting<int>>{
    2: Settings.moodColorVeryPleasant,
    1: Settings.moodColorPleasant,
    0: Settings.moodColorNeutral,
    -1: Settings.moodColorUnpleasant,
    -2: Settings.moodColorVeryUnpleasant,
  };

  static const nameSettings = <int, Setting<String>>{
    2: Settings.moodNameVeryPleasant,
    1: Settings.moodNamePleasant,
    0: Settings.moodNameNeutral,
    -1: Settings.moodNameUnpleasant,
    -2: Settings.moodNameVeryUnpleasant,
  };

  static const maxNameLength = 20;

  static ConfigProvider get _config => ConfigProvider.instance;

  /// Whether calendar days are filled with their mood colour.
  static bool get calendarColours => _config.get(Settings.calendarMoodColors);

  static Color colorOf(int mood) {
    final setting = colorSettings[mood.clamp(-2, 2)]!;
    return Color(_config.get(setting));
  }

  /// The mood's name: yours if you renamed it, otherwise the default.
  static String nameOf(int mood) {
    final setting = nameSettings[mood.clamp(-2, 2)]!;
    final name = _config.get(setting).trim();
    return name.isEmpty ? defaultNames[mood.clamp(-2, 2)]! : name;
  }

  /// Saves a name; an empty one goes back to the default.
  static Future<void> setName(int mood, String name) {
    var trimmed = name.trim();
    if (trimmed.length > maxNameLength) {
      trimmed = trimmed.substring(0, maxNameLength);
    }
    if (trimmed == defaultNames[mood]) trimmed = '';
    return _config.set(nameSettings[mood]!, trimmed);
  }

  static Future<void> setColor(int mood, Color color) =>
      _config.set(colorSettings[mood]!, color.toARGB32());

  /// Puts every mood's emoji, name and colour back to the defaults.
  static Future<void> resetAll() async {
    for (final mood in values) {
      await _config.set(
          Settings.moodIcons[mood]!, Settings.moodIcons[mood]!.defaultValue);
      await _config.set(nameSettings[mood]!, '');
      await _config.set(
          colorSettings[mood]!, colorSettings[mood]!.defaultValue);
    }
  }

  /// The mood a day shows: the rounded average of its entries that have one,
  /// or null when none do.
  static int? dayMood(List<Entry> entries) {
    final moods = [
      for (final entry in entries)
        if (entry.mood != null) entry.mood!,
    ];
    if (moods.isEmpty) return null;
    final average = moods.reduce((a, b) => a + b) / moods.length;
    return average.round().clamp(-2, 2);
  }

  /// A calendar day's fill: the mood colour blended into the day square's
  /// usual colour, so it sits well in both dark and light mode.
  static Color dayFill(Color base, int mood) =>
      Color.lerp(base, colorOf(mood), 0.78)!;

  /// Black or white, whichever reads better on [background].
  static Color onColor(Color background) {
    final l = background.computeLuminance();
    // Contrast with white is 1.05/(l+.05), with black (l+.05)/.05
    return 1.05 / (l + 0.05) >= (l + 0.05) / 0.05 ? Colors.white : Colors.black;
  }
}

/// Settings › Look and feel › Moods: the Mood colours switch with a preview
/// of this week, then one row per mood (emoji | name | colour).
class MoodsPage extends StatelessWidget {
  const MoodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Moods'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Material(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('moodColoursSwitch'),
                  secondary: Icon(Icons.invert_colors_rounded,
                      color: colorScheme.onSurfaceVariant),
                  title: const Text('Mood colours on calendar'),
                  subtitle: const Text('Same switch as the calendar’s 👁 menu'),
                  value: config.get(Settings.calendarMoodColors),
                  onChanged: (value) =>
                      config.set(Settings.calendarMoodColors, value),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _WeekPreview(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
            child: Text('Your moods',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: colorScheme.primary)),
          ),
          for (final mood in Moods.values) ...[
            _MoodRow(key: ValueKey('moodRow$mood'), mood: mood),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Center(
            child: OutlinedButton.icon(
              key: const Key('moodsReset'),
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset to default'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Emoji, names and colours are saved in your backup.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset moods?'),
        content: const Text(
            'All five moods go back to their original emoji, names and colours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) await Moods.resetAll();
  }
}

/// This week's days, filled with their mood colour while the switch is on,
/// the way the Home calendar shows them.
class _WeekPreview extends StatelessWidget {
  const _WeekPreview();

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final entries = context.watch<EntriesProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final on = config.get(Settings.calendarMoodColors);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // FIRSTDAYOFWEEK: 0 = Monday … 6 = Sunday
    final firstDay = config.getFirstDayOfWeekIndex(context);
    final back = (today.weekday - 1 - firstDay) % 7;
    final start = today.subtract(Duration(days: back));
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    final labels = MaterialLocalizations.of(context).narrowWeekdays;
    final muted = TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Preview', style: muted),
            Text('This week', style: muted),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: Column(
                  children: [
                    Text(labels[day.weekday % 7], style: muted),
                    const SizedBox(height: 4),
                    _previewDay(context, day, today,
                        entries.getEntriesForDate(day), on),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _previewDay(BuildContext context, DateTime day, DateTime today,
      List<Entry> dayEntries, bool on) {
    final colorScheme = Theme.of(context).colorScheme;
    final mood = Moods.dayMood(dayEntries);
    final base = dayEntries.isEmpty
        ? colorScheme.surfaceContainerLow
        : colorScheme.secondaryContainer;
    final fill = on && mood != null ? Moods.dayFill(base, mood) : base;
    final isToday = day == today;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(
                  color: colorScheme.primary,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside)
              : null,
        ),
        child: Center(
          child: mood != null
              ? MoodIcon(moodValue: mood, size: 15, allowScaling: false)
              : Text('${day.day}',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                      fontSize: 11,
                      color: on && mood != null
                          ? Moods.onColor(fill)
                          : colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}

/// One mood: emoji | name box | colour button, joined like Daily You 3.9.0's
/// mood scale.
class _MoodRow extends StatefulWidget {
  const _MoodRow({super.key, required this.mood});

  final int mood;

  @override
  State<_MoodRow> createState() => _MoodRowState();
}

class _MoodRowState extends State<_MoodRow> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: Moods.nameOf(widget.mood));
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await Moods.setName(widget.mood, _controller.text);
    if (!mounted) return;
    final name = Moods.nameOf(widget.mood);
    if (_controller.text != name) _controller.text = name;
  }

  Future<void> _pickColor() async {
    final result = await showAppDialog<ColorPickerResult>(
      context: context,
      builder: (context) =>
          ColorPickerDialog(initialColor: Moods.colorOf(widget.mood)),
    );
    if (result?.color != null) {
      await Moods.setColor(widget.mood, result!.color!);
    }
  }

  Future<void> _pickEmoji() async {
    var newEmoji = '';
    await showAppDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: MoodIcon(moodValue: widget.mood, size: 32)),
        content: Card.filled(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SizedBox(
            width: 96,
            height: 96,
            child: Center(
              child: TextField(
                autofocus: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
                inputFormatters: [LengthLimitingTextInputFormatter(1)],
                onChanged: (value) => newEmoji = value,
                decoration: const InputDecoration(
                    hintText: '?', border: InputBorder.none),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () async {
              if (newEmoji.isNotEmpty) {
                await ConfigProvider.instance
                    .set(Settings.moodIcons[widget.mood]!, newEmoji);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ConfigProvider>();
    // After Reset, show the name again unless it's being typed in
    final name = Moods.nameOf(widget.mood);
    if (!_focus.hasFocus && _controller.text != name) {
      _controller.text = name;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final color = Moods.colorOf(widget.mood);
    const height = 56.0;
    const round = Radius.circular(height / 2);
    const square = Radius.circular(6);
    final segment = colorScheme.surfaceContainerHigh;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Material(
            color: segment,
            borderRadius:
                const BorderRadius.horizontal(left: round, right: square),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: Key('moodEmoji${widget.mood}'),
              onTap: _pickEmoji,
              child: SizedBox(
                width: 64,
                height: height,
                child: Center(
                  child: Text(
                    MoodIcon.getMoodIcon(widget.mood),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 26,
                      fontFamily: Platform.isLinux ? 'Noto Color Emoji' : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: segment,
                borderRadius: const BorderRadius.all(square),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                key: Key('moodName${widget.mood}'),
                controller: _controller,
                focusNode: _focus,
                maxLength: Moods.maxNameLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: Moods.defaultNames[widget.mood],
                  border: InputBorder.none,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(square),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Material(
            color: color,
            borderRadius:
                const BorderRadius.horizontal(left: square, right: round),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: Key('moodColor${widget.mood}'),
              onTap: _pickColor,
              child: SizedBox(
                width: 64,
                height: height,
                child: Icon(Icons.palette_rounded,
                    color: Moods.onColor(color),
                    semanticLabel: '${Moods.nameOf(widget.mood)} colour'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
