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

/// Settings › Journal › Quick entry (Update Q).
class QuickEntrySettings extends StatelessWidget {
  const QuickEntrySettings({super.key});

  Future<void> _setNotification(BuildContext context, bool on) async {
    if (on) {
      final allowed = await NotificationManager.instance.notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
      if (!allowed) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Allow notifications for Daily You to use this'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
    }
    await ConfigProvider.instance.set(Settings.quickEntryNotification, on);
    await QuickEntryHost.instance.refreshNotification();
  }

  Future<void> _addTile(BuildContext context) async {
    final asked = await QuickEntryHost.requestTile();
    if (asked || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add the Quick Settings tile'),
        content: const Text(
            'Swipe down twice from the top of the screen, tap the pencil '
            '(Edit), then drag "Quick entry" into your tiles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context);
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: const Text('Quick entry'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          SettingsGroup(children: [
            SettingsToggle(
              title: 'Lock screen notification',
              hint: 'A quiet, pinned notification to add a note from anywhere',
              leading: Icons.notifications_active_outlined,
              value: config.get(Settings.quickEntryNotification),
              onChanged: (on) => _setNotification(context, on),
            ),
            SettingsToggle(
              title: 'Keep open after saving',
              hint: 'Clears the text so you can add another note',
              leading: Icons.playlist_add_rounded,
              setting: Settings.quickEntryKeepOpen,
              onChanged: (on) => config.set(Settings.quickEntryKeepOpen, on),
            ),
          ]),
          SettingsGroup(title: 'Other ways in', children: [
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: const Text('Quick Settings tile'),
              subtitle: const Text('Works over any app and the lock screen'),
              trailing: const Icon(Icons.add_rounded),
              onTap: () => _addTile(context),
            ),
            const ListTile(
              leading: Icon(Icons.text_fields_rounded),
              title: Text('Selected text'),
              subtitle:
                  Text('Select text in any app, then ⋮ › Add to Daily You'),
            ),
            const ListTile(
              leading: Icon(Icons.touch_app_outlined),
              title: Text('App icon and widget'),
              subtitle: Text(
                  'Long-press the Daily You icon for Quick note, or add the Quick entry widget to your home screen'),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
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
