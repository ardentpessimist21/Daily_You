// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:daily_you/config_provider.dart';
import 'package:system_theme/system_theme.dart';

class ThemeModeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Color _accentColor = const Color(0xff62A0EA);
  Color get accentColor => _accentColor;
  bool get usingSystemColor =>
      ConfigProvider.instance.get(Settings.followSystemColor);

  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  set accentColor(Color color) {
    ConfigProvider.instance.set(Settings.accentColor, color.toARGB32());
    _accentColor = color;
  }

  void updateAccentColor() {
    if (ConfigProvider.instance.get(Settings.followSystemColor)) {
      _accentColor = SystemTheme.accentColor.accent;
    } else {
      _accentColor = Color(ConfigProvider.instance.get(Settings.accentColor));
    }
    notifyListeners();
  }

  Future<void> initializeThemeFromConfig() async {
    await SystemTheme.accentColor.load();
    SystemTheme.fallbackColor = _accentColor;
    if (ConfigProvider.instance.get(Settings.followSystemColor)) {
      _accentColor = SystemTheme.accentColor.accent;
    } else {
      _accentColor = Color(ConfigProvider.instance.get(Settings.accentColor));
    }

    _themeMode = _modeFromConfig();
    notifyListeners();
  }

  /// Re-reads the theme and accent colour from settings, e.g. after
  /// settings were restored from a backup.
  void reloadFromConfig() {
    _themeMode = _modeFromConfig();
    updateAccentColor();
  }

  static ThemeMode _modeFromConfig() =>
      switch (ConfigProvider.instance.get(Settings.theme)) {
        'dark' || 'amoled' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };

  ThemeMode get currentThemeMode {
    return _themeMode;
  }
}
