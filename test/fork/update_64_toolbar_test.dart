// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_scroller.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  // 3.7.0.64: formatting buttons that don't fit scroll sideways, with ‹ ›
  // to tap, instead of a ⋯ menu; the spot is remembered.
  testWidgets('the formatting toolbar scrolls instead of overflowing',
      (tester) async {
    // A narrow phone, so the buttons can't all fit
    tester.view.physicalSize = const Size(900, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final controller = TextEditingController(text: 'Hello');
    final undo = UndoHistoryController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(undo.dispose);
    addTearDown(focus.dispose);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: ConfigProvider.instance,
      child: MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...appLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(children: [
            TextField(controller: controller, focusNode: focus),
            const Spacer(),
            EditorActionBar(
              controller: controller,
              undoController: undo,
              focusNode: focus,
              entryDate: () => DateTime(2026, 11, 24),
            ),
          ]),
        ),
      ),
    ));
    focus.requestFocus();
    await tester.pumpAndSettle();

    final scroller = find.byType(ToolbarScroller);
    expect(scroller, findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    final view = find.descendant(
        of: scroller, matching: find.byType(SingleChildScrollView));
    final position =
        tester.widget<SingleChildScrollView>(view).controller!.position;
    expect(position.pixels, 0);
    await tester.tap(find.descendant(
        of: scroller, matching: find.byIcon(Icons.chevron_right_rounded)));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(ConfigProvider.instance.get(Settings.editorToolbarScroll),
        position.pixels.round());
    EasyDebounce.cancelAll();
  });
}
