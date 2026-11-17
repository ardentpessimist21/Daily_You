// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/quick_entry/quick_entry_host.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/widgets/settings_group.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Settings › Journal › Quick entry (Update Q), with the floating button and
/// its badge (Update F) grouped together.
class QuickEntrySettings extends StatefulWidget {
  const QuickEntrySettings({super.key});

  @override
  State<QuickEntrySettings> createState() => _QuickEntrySettingsState();
}

/// Nudges are at least this far apart (same as the Android side).
const int _minGapMinutes = 30;
const int _maxTimes = 10;

int _maxTimesFor(int start, int end) {
  final length = end - start;
  if (length <= 0) return 1;
  return (length ~/ _minGapMinutes + 1).clamp(1, _maxTimes);
}

const Map<String, String> _bringBackLabels = {
  '30m': 'After 30 minutes',
  '1h': 'After 1 hour',
  'unlock': 'Next unlock',
  'tomorrow': 'Tomorrow',
  'never': 'Never (bring it back yourself)',
};

const Map<String, String> _modeLabels = {
  'random': 'Random times',
  'fixed': 'Fixed times',
};

class _QuickEntrySettingsState extends State<QuickEntrySettings>
    with WidgetsBindingObserver {
  /// Waiting to come back from "Display over other apps" to turn it on.
  bool _waitingForOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForOverlay) {
      _waitingForOverlay = false;
      _finishTurningOn();
    }
  }

  ConfigProvider get _config => ConfigProvider.instance;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<bool> _askNotificationPermission() async {
    return await NotificationManager.instance.notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  Future<void> _push() => QuickEntryHost.instance.refreshNotification();

  // Notification

  Future<void> _setNotification(bool on) async {
    if (on && !await _askNotificationPermission()) {
      _snack('Allow notifications for Daily You to use this');
      return;
    }
    await _config.set(Settings.quickEntryNotification, on);
    if (!on && _config.get<bool>(Settings.floatingButton)) {
      // The floating button needs the notification
      await _config.set(Settings.floatingButton, false);
      _snack('Floating button turned off too: it needs the notification');
    }
    await _push();
  }

  // Floating button

  Future<void> _setFloating(bool on) async {
    if (!on) {
      await _config.set(Settings.floatingButton, false);
      await _push();
      return;
    }
    if (await QuickEntryHost.canDrawOverlays()) {
      await _finishTurningOn();
      return;
    }
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Display over other apps'),
        content: const Text(
            'The floating button sits over other apps, so Android asks you to '
            'allow Daily You to "Display over other apps".\n\n'
            'On Xiaomi phones, also allow "Display pop-up windows while running '
            'in the background", and set Battery saver to "No restrictions", '
            'or the phone may close the button.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (go != true) return;
    _waitingForOverlay = true;
    if (!await QuickEntryHost.requestOverlay()) {
      _waitingForOverlay = false;
      _snack('Couldn\'t open the setting. Find it under Apps › Daily You');
    }
  }

  Future<void> _finishTurningOn() async {
    if (!await QuickEntryHost.canDrawOverlays()) {
      _snack('"Display over other apps" is still off');
      return;
    }
    // It rides on the pinned notification
    await _askNotificationPermission();
    await _config.set(Settings.quickEntryNotification, true);
    await _config.set(Settings.floatingButton, true);
    await _push();
  }

  Future<void> _set<T>(Setting<T> setting, T value) async {
    await _config.set(setting, value);
    await _push();
  }

  Future<void> _pickRangeTime({required bool start}) async {
    final current = _config.get<int>(
        start ? Settings.floatingBadgeStart : Settings.floatingBadgeEnd);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: start ? 'Badge range starts' : 'Badge range ends',
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    final otherStart = _config.get<int>(Settings.floatingBadgeStart);
    final otherEnd = _config.get<int>(Settings.floatingBadgeEnd);
    final newStart = start ? minutes : otherStart;
    final newEnd = start ? otherEnd : minutes;
    if (newEnd <= newStart) {
      _snack('The range has to end after it starts');
      return;
    }
    await _config.set(
        start ? Settings.floatingBadgeStart : Settings.floatingBadgeEnd,
        minutes);
    // Fewer times fit in a shorter range
    final fit = _maxTimesFor(newStart, newEnd);
    if (_config.get<int>(Settings.floatingBadgeTimes) > fit) {
      await _config.set(Settings.floatingBadgeTimes, fit);
    }
    await _push();
  }

  String _timeLabel(int minutes) => MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

  // Layout

  /// Same title and hint styles as the switches (SettingsToggle).
  static const TextStyle _titleStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle _hintStyle = TextStyle(fontSize: 14);

  Widget _dimmed(bool enabled, Widget child) => IgnorePointer(
        ignoring: !enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.38,
          child: child,
        ),
      );

  Widget _menuRow<T>({
    required IconData icon,
    required String title,
    required T value,
    required Map<T, String> labels,
    required ValueChanged<T> onSelected,
    String? hint,
  }) {
    final theme = Theme.of(context);
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final entry in labels.entries)
          PopupMenuItem<T>(value: entry.key, child: Text(entry.value)),
      ],
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: _titleStyle),
        subtitle: hint == null ? null : Text(hint, style: _hintStyle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labels[value] ?? '',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
            Icon(Icons.arrow_drop_down_rounded,
                color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _timesRow() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final times = _config.get<int>(Settings.floatingBadgeTimes);
    final fit = _maxTimesFor(_config.get<int>(Settings.floatingBadgeStart),
        _config.get<int>(Settings.floatingBadgeEnd));
    return ListTile(
      leading: const Icon(Icons.repeat_rounded),
      title: const Text('Times a day', style: _titleStyle),
      subtitle: Text(
          fit < _maxTimes ? 'Up to $fit in this range' : '30 min apart or more',
          style: _hintStyle),
      trailing: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Fewer',
              visualDensity: VisualDensity.compact,
              onPressed: times > 1
                  ? () => _set(Settings.floatingBadgeTimes, times - 1)
                  : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 24,
              child: Text('$times',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium),
            ),
            IconButton(
              tooltip: 'More',
              visualDensity: VisualDensity.compact,
              onPressed: times < fit
                  ? () => _set(Settings.floatingBadgeTimes, times + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transparencyRow() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final opacity = _config.get<int>(Settings.floatingOpacity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.opacity_rounded),
            title: const Text('Transparency', style: _titleStyle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$opacity%',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: cs.primary)),
                const SizedBox(width: 12),
                // A small sample of the button at this transparency
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: CustomPaint(
                                painter: _StripesPainter(
                                    cs.surfaceContainerHighest,
                                    cs.surfaceContainerLow))),
                        Positioned(
                          right: -11,
                          top: 9,
                          child: Opacity(
                            opacity: opacity / 100,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 12, 0),
            child: Column(
              children: [
                Slider(
                  value: opacity.toDouble(),
                  min: 30,
                  max: 100,
                  divisions: 14,
                  label: '$opacity%',
                  onChanged: (value) =>
                      _config.set(Settings.floatingOpacity, value.round()),
                  onChangeEnd: (_) => _push(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('See-through', style: theme.textTheme.bodySmall),
                      Text('Solid', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subheading(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 12, 16, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context);
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final floatingOn = config.get<bool>(Settings.floatingButton);
    final badgeOn = floatingOn && config.get<bool>(Settings.floatingBadge);
    final start = config.get<int>(Settings.floatingBadgeStart);
    final end = config.get<int>(Settings.floatingBadgeEnd);

    return Scaffold(
      appBar: AppBar(title: const Text('Quick entry'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          SettingsGroup(title: 'Quick entry sheet', children: [
            SettingsToggle(
              title: 'Keep open after saving',
              hint: 'Clears the text so you can add another note',
              leading: Icons.playlist_add_rounded,
              setting: Settings.quickEntryKeepOpen,
              onChanged: (on) => config.set(Settings.quickEntryKeepOpen, on),
            ),
          ]),
          SettingsGroup(title: 'Notification', children: [
            SettingsToggle(
              title: 'Lock screen notification',
              hint: 'Pinned and quiet. The floating button needs it',
              leading: Icons.notifications_active_outlined,
              value: config.get<bool>(Settings.quickEntryNotification),
              onChanged: (on) => _setNotification(on),
            ),
          ]),
          SettingsGroup(title: 'Floating button', children: [
            SettingsToggle(
              title: 'Floating button',
              hint: 'Tucked at the edge over other apps. Drag it to ✕ to hide',
              leading: Icons.bubble_chart_outlined,
              value: floatingOn,
              onChanged: (on) => _setFloating(on),
            ),
            _dimmed(floatingOn, _transparencyRow()),
            _dimmed(
              floatingOn,
              SettingsToggle(
                title: 'Hide during Do Not Disturb',
                hint: 'Comes back when Do Not Disturb ends',
                leading: Icons.do_not_disturb_on_outlined,
                value: config.get<bool>(Settings.floatingHideDnd),
                onChanged: (on) => _set(Settings.floatingHideDnd, on),
              ),
            ),
            _dimmed(
              floatingOn,
              _menuRow<String>(
                icon: Icons.restore_rounded,
                title: 'Bring back after',
                hint: 'After dragging to ✕',
                value: config.get<String>(Settings.floatingBringBack),
                labels: _bringBackLabels,
                onSelected: (value) => _set(Settings.floatingBringBack, value),
              ),
            ),
            _dimmed(
              floatingOn,
              Column(children: [
                _subheading('Badge'),
                SettingsToggle(
                  title: 'Badge dot',
                  hint: 'A dot at random times to nudge you to write',
                  leading: Icons.circle_notifications_outlined,
                  value: config.get<bool>(Settings.floatingBadge),
                  onChanged: (on) => _set(Settings.floatingBadge, on),
                ),
              ]),
            ),
            _dimmed(badgeOn, _timesRow()),
            _dimmed(
              badgeOn,
              _menuRow<String>(
                icon: Icons.shuffle_rounded,
                title: 'When',
                value: config.get<String>(Settings.floatingBadgeMode),
                labels: _modeLabels,
                onSelected: (value) => _set(Settings.floatingBadgeMode, value),
              ),
            ),
            _dimmed(
              badgeOn,
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Range', style: _titleStyle),
                subtitle: const Text('Not the reminder\'s', style: _hintStyle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _pickRangeTime(start: true),
                      child: Text(_timeLabel(start)),
                    ),
                    const Text('–'),
                    TextButton(
                      onPressed: () => _pickRangeTime(start: false),
                      child: Text(_timeLabel(end)),
                    ),
                  ],
                ),
              ),
            ),
            _dimmed(
              badgeOn,
              SettingsToggle(
                title: 'Nudge',
                hint: 'A small wiggle each time',
                leading: Icons.vibration_rounded,
                value: config.get<bool>(Settings.floatingNudge),
                onChanged: (on) => _set(Settings.floatingNudge, on),
              ),
            ),
          ]),
          // Plain tips, not buttons: none of these can be set up from here
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Other ways in',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 8),
                Text(
                  '• Quick Settings tile: pull down Quick Settings, tap Edit, '
                  'then drag "Quick entry" into your tiles. Works over any app.',
                  style: hintStyle,
                ),
                const SizedBox(height: 6),
                Text(
                  '• Selected text: select text in any app, then '
                  '⋮ › Add to Daily You.',
                  style: hintStyle,
                ),
                const SizedBox(height: 6),
                Text(
                  '• App icon and widget: long-press the Daily You icon for '
                  'Quick note, or add the Quick entry widget to your home '
                  'screen.',
                  style: hintStyle,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
            child: Text(
              'On the lock screen you can only add notes: your entries don\'t '
              'show, and tags, places and the full editor ask you to unlock.',
              style: hintStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  _StripesPainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = b);
    final paint = Paint()
      ..color = a
      ..strokeWidth = 5;
    for (double x = -size.height; x < size.width; x += 10) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => old.a != a || old.b != b;
}
