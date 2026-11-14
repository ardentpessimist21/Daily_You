import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/quick_entry/quick_entry_sheet.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'the keyboard stays up when the sheet switches to its compact layout',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfigProvider>.value(
            value: ConfigProvider.instance),
        ChangeNotifierProvider<EntriesProvider>.value(
            value: EntriesProvider.instance),
        ChangeNotifierProvider<TagsProvider>.value(
            value: TagsProvider.instance),
      ],
      child: const MaterialApp(home: QuickEntryPage(ready: true)),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    final before = tester.state(field);
    expect(tester.testTextInput.hasAnyClients, isTrue);

    // The keyboard comes up: the sheet changes to its compact layout
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byTooltip('Open full editor'), findsOneWidget);
    expect(tester.state(field), same(before));
    expect(tester.testTextInput.hasAnyClients, isTrue);

    await tester.enterText(field, 'Night market');
    await tester.pump();
    expect(find.text('Night market'), findsOneWidget);
  });
}
