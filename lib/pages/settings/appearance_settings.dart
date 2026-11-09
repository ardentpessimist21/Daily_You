// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/selection_actions.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/editor_buttons_settings_page.dart';
import 'package:daily_you/fork/home_greeting.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/color_picker_dialog.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_group.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:daily_you/theme_mode_provider.dart';

/// Which part of the old Appearance page to show (Settings regroup): the
/// visual look, plus three pages split out of it.
enum AppearanceSection { appearance, homeAndCalendar, writing, reading }

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings(
      {super.key, this.section = AppearanceSection.appearance});

  final AppearanceSection section;

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
          maxLength: HomeGreeting.maxNameLength,
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
    final l10n = AppLocalizations.of(context)!;

    final String title = switch (widget.section) {
      AppearanceSection.appearance => l10n.settingsAppearanceTitle,
      AppearanceSection.homeAndCalendar => l10n.settingsHomeAndCalendarTitle,
      AppearanceSection.writing => l10n.settingsWritingTitle,
      AppearanceSection.reading => l10n.settingsReadingTitle,
    };

    final List<Widget> rows = switch (widget.section) {
      AppearanceSection.appearance => [
          SettingsDropdown<String>(
              title: l10n.settingsTheme,
              leading: Icons.dark_mode_outlined,
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
              title: l10n.settingsUseSystemAccentColor,
              leading: Icons.water_drop_outlined,
              setting: Settings.followSystemColor,
              onChanged: (value) {
                configProvider.set(Settings.followSystemColor, value);
                themeProvider.updateAccentColor();
              }),
          if (!configProvider.get(Settings.followSystemColor))
            SettingsIconAction(
              title: l10n.settingsCustomAccentColor,
              leading: Icons.brush_outlined,
              icon: Icon(Icons.colorize_rounded),
              onPressed: () async {
                _showAccentColorPopup(themeProvider);
              },
            ),
          _moodIconsRow(context),
        ],
      AppearanceSection.homeAndCalendar => [
          SettingsToggle(
            title: l10n.settingsHomeGreeting,
            hint: l10n.settingsHomeGreetingHint,
            leading: Icons.waving_hand_outlined,
            setting: Settings.homeGreetingEnabled,
            onChanged: (value) =>
                configProvider.set(Settings.homeGreetingEnabled, value),
          ),
          if (configProvider.get(Settings.homeGreetingEnabled)) ...[
            SettingsIconAction(
              title: l10n.settingsYourName,
              hint: configProvider.get(Settings.homeGreetingName).isEmpty
                  ? l10n.settingsYourNameHint
                  : configProvider.get(Settings.homeGreetingName),
              leading: Icons.person_outline_rounded,
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showNameDialog(configProvider),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SettingsDropdown<String>(
                  title: l10n.settingsGreetingStyle,
                  leading: Icons.auto_awesome_outlined,
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
                title: l10n.settingsFirstDayOfWeek,
                leading: Icons.view_week_outlined,
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
                title: l10n.settingsCalendarSystem,
                leading: Icons.public_outlined,
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
        ],
      AppearanceSection.writing => [
          SettingsIconAction(
            title: l10n.settingsEditorButtons,
            hint: l10n.settingsEditorButtonsHint,
            leading: Icons.smart_button_outlined,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EditorButtonsSettingsPage())),
          ),
          SettingsToggle(
            title: l10n.settingsWritingPrompts,
            hint: l10n.settingsWritingPromptsHint,
            leading: Icons.lightbulb_outline_rounded,
            setting: Settings.writingPrompts,
            onChanged: (value) =>
                configProvider.set(Settings.writingPrompts, value),
          ),
          SettingsToggle(
            title: l10n.settingsFutureEntries,
            hint: l10n.settingsFutureEntriesHint,
            leading: Icons.edit_calendar_outlined,
            setting: Settings.allowFutureEntries,
            onChanged: (value) =>
                configProvider.set(Settings.allowFutureEntries, value),
          ),
        ],
      AppearanceSection.reading => [
          SettingsToggle(
            title: l10n.settingsJustifyText,
            hint: l10n.settingsJustifyTextHint,
            leading: Icons.format_align_justify_rounded,
            setting: Settings.justifyText,
            onChanged: (value) =>
                configProvider.set(Settings.justifyText, value),
          ),
          SettingsToggle(
            title: l10n.settingsTimelineShowFullEntries,
            hint: l10n.settingsTimelineShowFullEntriesHint,
            leading: Icons.view_agenda_outlined,
            setting: Settings.timelineShowFullEntries,
            onChanged: (value) =>
                configProvider.set(Settings.timelineShowFullEntries, value),
          ),
          SettingsIconAction(
            title: l10n.settingsHideImages,
            leading: Icons.hide_image_outlined,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _showHideImagesDialog(context, configProvider),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SettingsDropdown<String>(
                title: l10n.settingsGalleryViewLayout,
                leading: Icons.grid_view_outlined,
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
            title: l10n.settingsSelectionActions,
            hint: l10n.settingsSelectionActionsHint,
            leading: Icons.check_box_outlined,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SelectionActionsSettingsPage())),
          ),
        ],
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [SettingsGroup(children: rows)],
      ),
    );
  }

  /// Change Mood Icons: the five mood buttons and reset.
  Widget _moodIconsRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: Row(
            children: [
              Icon(Icons.mood_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.settingsChangeMoodIcons,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(48.0, 0, 8.0, 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // On the narrower card the five buttons shrink to fit
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      moodIconButton(-2),
                      moodIconButton(-1),
                      moodIconButton(0),
                      moodIconButton(1),
                      moodIconButton(2),
                    ],
                  ),
                ),
              ),
              IconButton(
                  onPressed: _resetMoodIcons,
                  icon: const Icon(Icons.refresh_rounded))
            ],
          ),
        ),
      ],
    );
  }
}
