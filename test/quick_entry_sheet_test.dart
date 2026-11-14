import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/quick_entry/quick_entry_sheet.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real Roboto from the Flutter SDK, so widths match a phone (the test font
/// draws every letter as a wide square). Skipped when it isn't there.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final name in files) {
      final file = File('${dir.path}/$name');
      if (file.existsSync()) {
        loader.addFont(Future.value(
            ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()))));
      }
    }
    await loader.load();
  }

  await load(
      'Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

void main() {
  setUpAll(_loadRoboto);
  testWidgets(
      'the keyboard stays up when the sheet switches to its compact layout',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // A phone like Hanah's, with large text (3.7.0.52 cut "New entry" short)
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
    final pill = tester.renderObject<RenderParagraph>(find
        .descendant(
            of: find.byType(OutlinedButton), matching: find.byType(RichText))
        .first);
    expect(pill.didExceedMaxLines, isFalse);
    expect(tester.state(field), same(before));
    expect(tester.testTextInput.hasAnyClients, isTrue);

    await tester.enterText(field, 'Night market');
    await tester.pump();
    expect(find.text('Night market'), findsOneWidget);
  });
}
