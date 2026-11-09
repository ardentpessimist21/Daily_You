// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/fork/flashback_styles.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:daily_you/widgets/settings_group.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class FlashbackSettings extends StatefulWidget {
  const FlashbackSettings({super.key});

  @override
  State<FlashbackSettings> createState() => _FlashbackSettingsPageState();
}

class _FlashbackSettingsPageState extends State<FlashbackSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.flashbacksTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          SettingsGroup(children: [
            SettingsToggle(
                title: AppLocalizations.of(context)!.settingsShowFlashbacks,
                leading: Icons.history_rounded,
                setting: Settings.showFlashbacks,
                onChanged: (value) {
                  configProvider.set(Settings.showFlashbacks, value);
                }),
            if (configProvider.get(Settings.showFlashbacks))
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SettingsDropdown<String>(
                    title: AppLocalizations.of(context)!.settingsFlashbackStyle,
                    leading: Icons.style_outlined,
                    value: configProvider.get(Settings.flashbackStyle),
                    options: [
                      DropdownMenuItem<String>(
                          value: FlashbackStyle.cards,
                          child: Text(AppLocalizations.of(context)!
                              .flashbackStyleCards)),
                      DropdownMenuItem<String>(
                          value: FlashbackStyle.chips,
                          child: Text(AppLocalizations.of(context)!
                              .flashbackStyleChips)),
                      DropdownMenuItem<String>(
                          value: FlashbackStyle.icon,
                          child: Text(AppLocalizations.of(context)!
                              .flashbackStyleIcon)),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      configProvider.set(Settings.flashbackStyle, newValue);
                    }),
              ),
            if (configProvider.get(Settings.showFlashbacks))
              SettingsToggle(
                  title: AppLocalizations.of(context)!
                      .settingsFlashbacksExcludeBadDays,
                  leading: Icons.sentiment_dissatisfied_outlined,
                  setting: Settings.excludeBadDaysFromFlashbacks,
                  onChanged: (value) {
                    configProvider.set(
                        Settings.excludeBadDaysFromFlashbacks, value);
                  }),
          ]),
          if (configProvider.get(Settings.showFlashbacks))
            SettingsGroup(
                title: AppLocalizations.of(context)!.flashbacksTitle,
                children: buildFlashbackOptions(configProvider)),
        ],
      ),
    );
  }

  List<Widget> buildFlashbackOptions(ConfigProvider configProvider) {
    return [
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackOnThisDay,
          leading: Icons.event_repeat_outlined,
          setting: Settings.showflashbackYearsAgo,
          onChanged: (value) {
            configProvider.set(Settings.showflashbackYearsAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackMonth(6),
          leading: Icons.date_range_outlined,
          setting: Settings.showflashback6MonthsAgo,
          onChanged: (value) {
            configProvider.set(Settings.showflashback6MonthsAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackMonth(1),
          leading: Icons.calendar_month_outlined,
          setting: Settings.showflashback1MonthAgo,
          onChanged: (value) {
            configProvider.set(Settings.showflashback1MonthAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackWeek(1),
          leading: Icons.view_week_outlined,
          setting: Settings.showflashback1WeekAgo,
          onChanged: (value) {
            configProvider.set(Settings.showflashback1WeekAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackGoodDay,
          leading: Icons.sentiment_satisfied_outlined,
          setting: Settings.showflashbackGoodDay,
          onChanged: (value) {
            configProvider.set(Settings.showflashbackGoodDay, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackRandomDay,
          leading: Icons.shuffle_rounded,
          setting: Settings.showflashbackRandomDay,
          onChanged: (value) {
            configProvider.set(Settings.showflashbackRandomDay, value);
          }),
    ];
  }
}
