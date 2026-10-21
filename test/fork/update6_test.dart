// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/fork/double_tap_to_edit.dart';
import 'package:daily_you/fork/password_recovery.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/password_store.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

Widget _app(Widget home) => ChangeNotifierProvider.value(
      value: ConfigProvider.instance,
      child: MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...appLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      ),
    );

void main() {
  group('Justified text', () {
    testWidgets('paragraphs justify; headings and lists stay left',
        (tester) async {
      await tester.pumpWidget(_app(const ScaledMarkdown(
        data: '# Night shift\n\nBusy ward tonight, and the handover ran '
            'long but we got through it together.\n\n- Meds round\n'
            '- [ ] Charting',
        selectable: false,
        justify: true,
      )));
      await tester.pumpAndSettle();
      TextAlign? alignOf(String text) => tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((rich) => rich.text.toPlainText().contains(text))
          .textAlign;
      expect(alignOf('Busy ward'), TextAlign.justify);
      expect(alignOf('Night shift'), isNot(TextAlign.justify));
      expect(alignOf('Meds round'), isNot(TextAlign.justify));
      expect(alignOf('Charting'), isNot(TextAlign.justify));
    });

    testWidgets('off by default (Gallery, editor previews)', (tester) async {
      await tester.pumpWidget(_app(const ScaledMarkdown(
          data: 'A plain paragraph of words.', selectable: false)));
      await tester.pumpAndSettle();
      expect(
          tester
              .widgetList<RichText>(find.byType(RichText))
              .where((rich) => rich.textAlign == TextAlign.justify),
          isEmpty);
    });
  });

  group('Double-tap to edit', () {
    Future<int> doubleTapAt(WidgetTester tester, Finder target) async {
      var opened = 0;
      await tester.pumpWidget(_app(DoubleTapToEdit(
        onDoubleTap: () => opened++,
        child: ListView(children: const [
          SizedBox(height: 100, child: Text('Some words')),
          SizedBox(height: 300, key: Key('empty')),
        ]),
      )));
      final at = tester.getCenter(target);
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 400));
      return opened;
    }

    testWidgets('an empty area opens the editor', (tester) async {
      expect(await doubleTapAt(tester, find.byKey(const Key('empty'))), 1);
    });

    testWidgets('text is left for word selection', (tester) async {
      expect(await doubleTapAt(tester, find.text('Some words')), 0);
    });

    testWidgets('two slow taps are not a double tap', (tester) async {
      var opened = 0;
      await tester.pumpWidget(_app(DoubleTapToEdit(
        onDoubleTap: () => opened++,
        child: const SizedBox.expand(),
      )));
      await tester.tapAt(const Offset(200, 300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tapAt(const Offset(200, 300));
      await tester.pump(const Duration(milliseconds: 400));
      expect(opened, 0);
    });
  });

  group('Recovery code', () {
    useTemporaryConfig();

    test('a new code looks like K7M2-9XQ4-T8LP and works', () async {
      final code = await RecoveryCodeStore.generate();
      expect(code, matches(RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')));
      expect(
          code
              .replaceAll('-', '')
              .split('')
              .every(RecoveryCodeStore.alphabet.contains),
          isTrue);
      expect(RecoveryCodeStore.hasCode, isTrue);
      expect(await RecoveryCodeStore.validate(code), isTrue);
      // Typed loosely
      expect(
          await RecoveryCodeStore.validate(
              code.toLowerCase().replaceAll('-', ' ')),
          isTrue);
      expect(await RecoveryCodeStore.validate('AAAA-AAAA-AAAA'), isFalse);
    });

    test('only a scrambled version is kept', () async {
      final code = await RecoveryCodeStore.generate();
      final stored = ConfigProvider.instance.get(Settings.recoveryCodeHash);
      expect(stored, startsWith(r'$argon2id$'));
      expect(stored.contains(RecoveryCodeStore.normalize(code)), isFalse);
    });

    test('a new code cancels the old one; clearing removes it', () async {
      final old = await RecoveryCodeStore.generate();
      final fresh = await RecoveryCodeStore.generate();
      expect(await RecoveryCodeStore.validate(old), isFalse);
      expect(await RecoveryCodeStore.validate(fresh), isTrue);
      await RecoveryCodeStore.clear();
      expect(RecoveryCodeStore.hasCode, isFalse);
      expect(await RecoveryCodeStore.validate(fresh), isFalse);
    });
  });

  group('Unlock screen', () {
    useTemporaryConfig();

    testWidgets('welcome back with the name in italics', (tester) async {
      await tester.runAsync(() =>
          ConfigProvider.instance.set(Settings.homeGreetingName, 'Hanah'));
      await tester.pumpWidget(_app(Builder(builder: unlockTitle)));
      final rich = tester.widget<RichText>(find.byType(RichText).first);
      expect(rich.text.toPlainText(), 'Welcome back, Hanah');
      final name = (rich.text as TextSpan)
          .children!
          .first
          .toPlainText(); // the outer Text.rich span
      expect(name, contains('Hanah'));
      var italic = false;
      rich.text.visitChildren((span) {
        if (span is TextSpan &&
            span.text == 'Hanah' &&
            span.style?.fontStyle == FontStyle.italic) {
          italic = true;
        }
        return true;
      });
      expect(italic, isTrue);
    });

    testWidgets('no name keeps "Unlock the app"', (tester) async {
      await tester.pumpWidget(_app(Builder(builder: unlockTitle)));
      expect(find.text('Unlock the app'), findsOneWidget);
    });

    testWidgets('forgot password and a clear check mark', (tester) async {
      var asked = false;
      await tester.pumpWidget(_app(AuthPopup(
        mode: AuthPopupMode.unlock,
        title: 'Unlock the app',
        showBiometrics: false,
        dismissable: true,
        onForgotPassword: (_) async {
          asked = true;
          return false;
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      expect(asked, isTrue);

      final colorScheme =
          Theme.of(tester.element(find.byType(AlertDialog))).colorScheme;
      final check = tester.widget<IconButton>(find.ancestor(
          of: find.byIcon(Icons.check_rounded),
          matching: find.byType(IconButton)));
      expect(check.style!.foregroundColor!.resolve({}), colorScheme.onPrimary);
    });

    testWidgets('no forgot button elsewhere', (tester) async {
      await tester.pumpWidget(_app(const AuthPopup(
        mode: AuthPopupMode.unlock,
        title: 'Enter password',
        showBiometrics: false,
        dismissable: true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsNothing);
    });
  }, skip: Platform.environment.containsKey('SKIP_SLOW'));
}
