// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  test('restored theme shows straight away, including System', () async {
    final provider = ThemeModeProvider()..themeMode = ThemeMode.light;
    await ConfigProvider.instance.set(Settings.followSystemColor, false);

    await ConfigProvider.instance.restoreSettingsFromBackup(
        {Settings.theme.key: 'system'});
    provider.reloadFromConfig();
    expect(provider.themeMode, ThemeMode.system);

    await ConfigProvider.instance.restoreSettingsFromBackup(
        {Settings.theme.key: 'dark', Settings.accentColor.key: 0xff00ff00});
    provider.reloadFromConfig();
    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.accentColor, const Color(0xff00ff00));
  });
}
