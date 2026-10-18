// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/editor_buttons_settings_page.dart';
import 'package:daily_you/fork/home_greeting.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/theme_mode_provider.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettings> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _showNameDialog(ConfigProvider configProvider) async {
    final controller = TextEditingController(
        text: configProvider.get(Settings.homeGreetingName));
    final name = await showAppDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.settingsYourName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.settingsYourNameHint),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await configProvider.set(Settings.homeGreetingName, name.trim());
    }
  }

  Future<void> _showAccentColorPopup(ThemeModeProvider themeProvider) async {
    final initialColor =
        Color(ConfigProvider.instance.get(Settings.accentColor));
    final result = await showAppDialog<ColorPickerResult>(
      context: context,
      builder: (context) => ColorPickerDialog(initialColor: initialColor),
    );
    if (result?.color != null) {
      themeProvider.accentColor = result!.color!;
      themeProvider.updateAccentColor();
    }
  }

  void _showMoodEmojiPopup(int? value) {
    String newEmoji = '';
    showAppDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: MoodIcon(
              moodValue: value,
              size: 32,
            ),
          ),
          actions: [
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () async {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
              onPressed: () async {
                if (newEmoji.isNotEmpty) {
                  if (value != null) {
                    await ConfigProvider.instance
                        .set(Settings.moodIcons[value]!, newEmoji);
                  }
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.moodIconPrompt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card.filled(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Center(
                    child: TextField(
                      autofocus: true,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                            1), // Limit to one character
                      ],
                      onChanged: (value) {
                        newEmoji = value;
                      },
                      decoration: const InputDecoration(
                        hintText: '?',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHideImagesDialog(
      BuildContext context, ConfigProvider configProvider) {
    showAppDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.settingsHideImages),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hideImagesToggleRow(
                    context,
                    AppLocalizations.of(context)!.flashbacksTitle,
                    configProvider.get(Settings.hideImagesInFlashbacks),
                    (value) {
                      configProvider.set(
                          Settings.hideImagesInFlashbacks, value);
                      setDialogState(() {});
                    },
                  ),
                  _hideImagesToggleRow(
                    context,
                    AppLocalizations.of(context)!.pageCalendarTitle,
                    configProvider.get(Settings.hideImagesInCalendar),
                    (value) {
                      configProvider.set(Settings.hideImagesInCalendar, value);
                      setDialogState(() {});
                    },
                  ),
                  _hideImagesToggleRow(
                    context,
                    AppLocalizations.of(context)!.pageGalleryTitle,
                    configProvider.get(Settings.hideImagesInGallery),
                    (value) {
                      configProvider.set(Settings.hideImagesInGallery, value);
                      setDialogState(() {});
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _hideImagesToggleRow(BuildContext context, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Future _resetMoodIcons() async {
    for (final setting in Settings.moodIcons.values) {
      await ConfigProvider.instance.set(setting, setting.defaultValue);
    }
  }

  Widget moodIconButton(int? index) {
    return GestureDetector(
      child: Card.filled(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
                constraints: const BoxConstraints(minWidth: 32),
                child: Center(child: MoodIcon(moodValue: index, size: 24))),
          )),
      onTap: () => _showMoodEmojiPopup(index),
    );
  }

  List<DropdownMenuItem<String>> _buildFirstDayOfWeekDropdownItems(
      BuildContext context) {
    final dayLabels = TimeManager.daysOfWeekLabels(context);
    List<DropdownMenuItem<String>> dropdownItems = List.empty(growable: true);
    dropdownItems.add(DropdownMenuItem<String>(
      value: "system",
      child: Text(AppLocalizations.of(context)!.themeSystem),
    ));

    var dropdownDays = List.generate(7, (index) {
      return DropdownMenuItem<String>(
        value: TimeManager.dayOfWeekIndexMapping[index],
        child: Text(
          dayLabels[index],
        ),
      );
    });
    dropdownItems.addAll(dropdownDays);
    return dropdownItems;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsAppearanceTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsDropdown<String>(
              title: AppLocalizations.of(context)!.settingsTheme,
              value: configProvider.get(Settings.theme),
              options: [
                DropdownMenuItem<String>(
                    value: "system",
                    child: Text(AppLocalizations.of(context)!.themeSystem)),
                DropdownMenuItem<String>(
                    value: "dark",
                    child: Text(AppLocalizations.of(context)!.themeDark)),
                DropdownMenuItem<String>(
                    value: "light",
                    child: Text(AppLocalizations.of(context)!.themeLight)),
                DropdownMenuItem<String>(
                    value: "amoled",
                    child: Text(AppLocalizations.of(context)!.themeAmoled)),
              ],
              onChanged: (String? newValue) {
                if (newValue == null) return;
                ThemeMode themeMode = ThemeMode.system;
                switch (newValue) {
                  case "system":
                    themeMode = ThemeMode.system;
                    break;
                  case "light":
                    themeMode = ThemeMode.light;
                    break;
                  case "dark":
                  case "amoled":
                    themeMode = ThemeMode.dark;
                    break;
                  default:
                    themeMode = ThemeMode.system;
                    break;
                }
                themeProvider.themeMode = themeMode;
                configProvider.set(Settings.theme, newValue);
              }),
          SettingsToggle(
              title: AppLocalizations.of(context)!.settingsUseSystemAccentColor,
              setting: Settings.followSystemColor,
              onChanged: (value) {
                configProvider.set(Settings.followSystemColor, value);
                themeProvider.updateAccentColor();
              }),
          if (!configProvider.get(Settings.followSystemColor))
            SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsCustomAccentColor,
              icon: Icon(Icons.colorize_rounded),
              onPressed: () async {
                _showAccentColorPopup(themeProvider);
              },
            ),
          SettingsIconAction(
            title: AppLocalizations.of(context)!.settingsEditorButtons,
            hint: AppLocalizations.of(context)!.settingsEditorButtonsHint,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EditorButtonsSettingsPage())),
          ),
          SettingsToggle(
            title: AppLocalizations.of(context)!.settingsWritingPrompts,
            hint: AppLocalizations.of(context)!.settingsWritingPromptsHint,
            setting: Settings.writingPrompts,
            onChanged: (value) =>
                configProvider.set(Settings.writingPrompts, value),
          ),
          SettingsToggle(
            title: AppLocalizations.of(context)!.settingsHomeGreeting,
            hint: AppLocalizations.of(context)!.settingsHomeGreetingHint,
            setting: Settings.homeGreetingEnabled,
            onChanged: (value) =>
                configProvider.set(Settings.homeGreetingEnabled, value),
          ),
          if (configProvider.get(Settings.homeGreetingEnabled)) ...[
            SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsYourName,
              hint: configProvider.get(Settings.homeGreetingName).isEmpty
                  ? AppLocalizations.of(context)!.settingsYourNameHint
                  : configProvider.get(Settings.homeGreetingName),
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showNameDialog(configProvider),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SettingsDropdown<String>(
                  title: AppLocalizations.of(context)!.settingsGreetingStyle,
                  value: configProvider.get(Settings.homeGreetingStyle),
                  options: [
                    DropdownMenuItem<String>(
                        value: HomeGreeting.styleClassic,
                        child: Text(AppLocalizations.of(context)!
                            .greetingStyleClassic)),
                    DropdownMenuItem<String>(
                        value: HomeGreeting.stylePlayful,
                        child: Text(AppLocalizations.of(context)!
                            .greetingStylePlayful)),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    configProvider.set(Settings.homeGreetingStyle, newValue);
                  }),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SettingsDropdown<String>(
                title: AppLocalizations.of(context)!.settingsFirstDayOfWeek,
                value: configProvider.get(Settings.startingDayOfWeek),
                options: _buildFirstDayOfWeekDropdownItems(context),
                onChanged: (String? newValue) async {
                  if (newValue == null) return;
                  await configProvider.set(
                      Settings.startingDayOfWeek, newValue);
                }),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SettingsDropdown<String>(
                title: AppLocalizations.of(context)!.settingsCalendarSystem,
                value: configProvider.get(Settings.calendarSystem),
                options: [
                  DropdownMenuItem<String>(
                      value: "system",
                      child: Text(AppLocalizations.of(context)!.themeSystem)),
                  DropdownMenuItem<String>(
                      value: "gregorian",
                      child: Text(AppLocalizations.of(context)!
                          .calendarSystemGregorian)),
                  DropdownMenuItem<String>(
                      value: "jalali",
                      child: Text(
                          AppLocalizations.of(context)!.calendarSystemJalali)),
                ],
                onChanged: (String? newValue) async {
                  if (newValue == null) return;
                  await configProvider.set(Settings.calendarSystem, newValue);
                }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SettingsDropdown<String>(
                title: AppLocalizations.of(context)!.settingsGalleryViewLayout,
                value: configProvider.get(Settings.galleryPageViewMode),
                options: [
                  DropdownMenuItem<String>(
                      value: "list",
                      child:
                          Text(AppLocalizations.of(context)!.viewLayoutList)),
                  DropdownMenuItem<String>(
                      value: "grid",
                      child:
                          Text(AppLocalizations.of(context)!.viewLayoutGrid)),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    configProvider.set(Settings.galleryPageViewMode, newValue);
                  }
                }),
          ),
          SettingsIconAction(
            title: AppLocalizations.of(context)!.settingsHideImages,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _showHideImagesDialog(context, configProvider),
          ),
          SettingsToggle(
            title: AppLocalizations.of(context)!
                .settingsTimelineShowFullEntries,
            hint: AppLocalizations.of(context)!
                .settingsTimelineShowFullEntriesHint,
            setting: Settings.timelineShowFullEntries,
            onChanged: (value) =>
                configProvider.set(Settings.timelineShowFullEntries, value),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Text(
              AppLocalizations.of(context)!.settingsChangeMoodIcons,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    moodIconButton(-2),
                    moodIconButton(-1),
                    moodIconButton(0),
                    moodIconButton(1),
                    moodIconButton(2),
                  ],
                ),
                IconButton(
                    onPressed: _resetMoodIcons,
                    icon: const Icon(Icons.refresh_rounded))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
