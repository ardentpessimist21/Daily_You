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
import 'package:daily_you/widgets/settings_group.dart';
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
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        children: [
          SettingsGroup(title: l10n.settingsGroupLookAndFeel, children: [
            SettingsCategory(
                title: l10n.settingsAppearanceTitle,
                icon: Icons.palette_outlined,
                page: const AppearanceSettings()),
            SettingsCategory(
                title: l10n.settingsHomeAndCalendarTitle,
                icon: Icons.calendar_today_outlined,
                page: const AppearanceSettings(
                    section: AppearanceSection.homeAndCalendar)),
            SettingsCategory(
                title: l10n.settingsLanguageTitle,
                icon: Icons.language_outlined,
                page: LanguageSettings()),
          ]),
          SettingsGroup(title: l10n.settingsGroupJournal, children: [
            SettingsCategory(
                title: l10n.settingsWritingTitle,
                icon: Icons.edit_outlined,
                page: const AppearanceSettings(
                    section: AppearanceSection.writing)),
            SettingsCategory(
                title: l10n.settingsReadingTitle,
                icon: Icons.menu_book_outlined,
                page: const AppearanceSettings(
                    section: AppearanceSection.reading)),
            SettingsCategory(
                title: l10n.settingsTagsTitle,
                icon: Icons.local_offer_outlined,
                page: TagsSettings()),
            SettingsCategory(
                title: l10n.settingsTemplatesTitle,
                icon: Icons.description_outlined,
                page: TemplateSettings()),
            SettingsCategory(
                title: l10n.settingsLocations,
                icon: Icons.place_outlined,
                page: const SavedPlacesPage()),
          ]),
          SettingsGroup(title: l10n.settingsGroupReminders, children: [
            if (Platform.isAndroid)
              SettingsCategory(
                  title: l10n.settingsNotificationsTitle,
                  icon: Icons.notifications_outlined,
                  page: NotificationSettings()),
            SettingsCategory(
                title: l10n.flashbacksTitle,
                icon: Icons.history_rounded,
                page: FlashbackSettings()),
          ]),
          SettingsGroup(title: l10n.settingsGroupYourData, children: [
            SettingsCategory(
                title: l10n.settingsBackupRestoreTitle,
                icon: Icons.sync_rounded,
                page: BackupRestoreSettings()),
            SettingsCategory(
                title: l10n.settingsStorageTitle,
                icon: Icons.storage_outlined,
                page: StorageSettings()),
            SettingsCategory(
                title: l10n.settingsSecurityTitle,
                icon: Icons.lock_outline_rounded,
                page: SecuritySettings()),
          ]),
          SettingsGroup(children: [
            SettingsCategory(
                title: l10n.settingsAboutTitle,
                icon: Icons.info_outline_rounded,
                page: AboutSettings()),
          ]),
        ],
      ),
    );
  }
}
