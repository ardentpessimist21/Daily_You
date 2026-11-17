import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  test('birthday matches the day, and 29 Feb on 28 Feb in other years', () {
    final day = DateTime(1990, 6, 14);
    expect(Profile.isBirthdayOn(day, DateTime(2026, 6, 14, 9)), isTrue);
    expect(Profile.isBirthdayOn(day, DateTime(2026, 6, 15)), isFalse);
    final leapDay = DateTime(1996, 2, 29);
    expect(Profile.isBirthdayOn(leapDay, DateTime(2026, 2, 28)), isTrue);
    expect(Profile.isBirthdayOn(leapDay, DateTime(2028, 2, 28)), isFalse);
    expect(Profile.isBirthdayOn(leapDay, DateTime(2028, 2, 29)), isTrue);
  });

  test('ordinals', () {
    expect(
        [1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 32, 101, 111].map(Profile.ordinal),
        [
          '1st',
          '2nd',
          '3rd',
          '4th',
          '11th',
          '12th',
          '13th',
          '21st',
          '22nd',
          '23rd',
          '32nd',
          '101st',
          '111th'
        ]);
  });

  Widget host(Widget child) => ChangeNotifierProvider<ConfigProvider>.value(
        value: ConfigProvider.instance,
        child: MaterialApp(home: child),
      );

  testWidgets('first-run name screen, then the birthday screen',
      (tester) async {
    await tester.pumpWidget(host(const ProfileSetupPage()));
    expect(find.text('What should we call you?'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('When\'s your birthday?'), findsOneWidget);
    expect(
        find.text(
            'So Daily You can celebrate your day with you. It stays on your phone.'),
        findsOneWidget);
    // Done stays off until month, day and year are picked
    final done =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'));
    expect(done.onPressed, isNull);
  });

  testWidgets('Settings › Profile shows Name and Birthday', (tester) async {
    await tester.pumpWidget(host(const ProfileSettingsPage()));
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);
  });
}
