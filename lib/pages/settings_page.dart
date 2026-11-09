// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/pages/settings/about_settings.dart';
import 'package:daily_you/pages/settings/appearance_settings.dart';
import 'package:daily_you/pages/settings/backup_restore_settings.dart';
import 'package:daily_you/pages/settings/flashback_settings.dart';
import 'package:daily_you/pages/settings/language_settings.dart';
import 'package:daily_you/pages/settings/notification_settings.dart';
import 'package:daily_you/pages/settings/security_settings.dart';
import 'package:daily_you/pages/settings/storage_settings.dart';
import 'package:daily_you/pages/settings/tags_settings.dart';
import 'package:daily_you/pages/settings/templates_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/widgets/settings_category.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final entriesProvider = Provider.of<EntriesProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pageSettingsTitle),
        centerTitle: true,
      ),
      persistentFooterButtons: [
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                    text: AppLocalizations.of(context)!.settingsMadeWithLove,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary)),
                if (entriesProvider.entries.length > 30)
                  TextSpan(
                      text: " ",
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary)),
                if (entriesProvider.entries.length > 30)
                  TextSpan(
                    text: AppLocalizations.of(context)!
                        .settingsConsiderSupporting,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await launchUrl(
                            Uri(
                                scheme: "https",
                                host: "github.com",
                                path: "/Demizo/Daily_You",
                                queryParameters: {"tab": "readme-ov-file"},
                                fragment: "support-the-app"),
                            mode: LaunchMode.externalApplication);
                      },
                  ),
              ],
            ),
          ),
        )
      ],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          _GroupLabel(l10n.settingsGroupLookAndFeel),
          SettingsCategory(
              title: l10n.settingsAppearanceTitle,
              icon: Icons.palette_rounded,
              page: const AppearanceSettings()),
          SettingsCategory(
              title: l10n.settingsHomeAndCalendarTitle,
              icon: Icons.calendar_month_rounded,
              page: const AppearanceSettings(
                  section: AppearanceSection.homeAndCalendar)),
          SettingsCategory(
              title: l10n.settingsLanguageTitle,
              icon: Icons.language_rounded,
              page: LanguageSettings()),
          _GroupLabel(l10n.settingsGroupJournal),
          SettingsCategory(
              title: l10n.settingsWritingTitle,
              icon: Icons.edit_rounded,
              page:
                  const AppearanceSettings(section: AppearanceSection.writing)),
          SettingsCategory(
              title: l10n.settingsReadingTitle,
              icon: Icons.menu_book_rounded,
              page:
                  const AppearanceSettings(section: AppearanceSection.reading)),
          SettingsCategory(
              title: l10n.settingsTagsTitle,
              icon: Icons.local_offer_rounded,
              page: TagsSettings()),
          SettingsCategory(
              title: l10n.settingsTemplatesTitle,
              icon: Icons.description_rounded,
              page: TemplateSettings()),
          SettingsCategory(
              title: l10n.settingsLocations,
              icon: Icons.place_rounded,
              page: const SavedPlacesPage()),
          _GroupLabel(l10n.settingsGroupReminders),
          if (Platform.isAndroid)
            SettingsCategory(
                title: l10n.settingsNotificationsTitle,
                icon: Icons.notifications_rounded,
                page: NotificationSettings()),
          SettingsCategory(
              title: l10n.flashbacksTitle,
              icon: Icons.history_rounded,
              page: FlashbackSettings()),
          _GroupLabel(l10n.settingsGroupYourData),
          SettingsCategory(
              title: l10n.settingsBackupRestoreTitle,
              icon: Icons.settings_backup_restore_rounded,
              page: BackupRestoreSettings()),
          SettingsCategory(
              title: l10n.settingsStorageTitle,
              icon: Icons.storage_rounded,
              page: StorageSettings()),
          SettingsCategory(
              title: l10n.settingsSecurityTitle,
              icon: Icons.security_rounded,
              page: SecuritySettings()),
          const Divider(indent: 16, endIndent: 16, height: 24),
          SettingsCategory(
              title: l10n.settingsAboutTitle,
              icon: Icons.info_rounded,
              page: AboutSettings()),
        ],
      ),
    );
  }
}

/// A group heading on the main Settings page (Settings regroup).
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
