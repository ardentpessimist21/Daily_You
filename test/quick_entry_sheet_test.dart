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

  // Update 68: 📎 in the text box opens Take photo, Record video, Record
  // audio and From gallery; the pie's keys map to them
  testWidgets('📎 opens the attach menu', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
    expect(find.byKey(const ValueKey('quick-entry-attachments')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('quick-entry-attach')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (final label in [
      'Take photo',
      'Record video',
      'Record audio',
      'From gallery'
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(QuickCapture.fromKey('photo'), QuickCapture.photo);
    expect(QuickCapture.fromKey('audio'), QuickCapture.audio);
    expect(QuickCapture.fromKey(null), isNull);
  });

  // 3.7.0.68: the pie's second ring
  test('the pie\'s keys carry the lens and auto record', () {
    final front = QuickCaptureRequest.parse('photo_front')!;
    expect(front.kind, QuickCapture.photo);
    expect(front.front, isTrue);
    final back = QuickCaptureRequest.parse('video_back')!;
    expect(back.kind, QuickCapture.video);
    expect(back.front, isFalse);
    final auto = QuickCaptureRequest.parse('audio_auto')!;
    expect(auto.kind, QuickCapture.audio);
    expect(auto.autoStart, isTrue);
    final plain = QuickCaptureRequest.parse('video')!;
    expect(plain.front, isNull);
    expect(plain.autoStart, isFalse);
    expect(QuickCaptureRequest.parse('nope'), isNull);
    expect(QuickCaptureRequest.parse(null), isNull);
  });

  // 3.7.0.68: with the keyboard up, 📎 leaves the text box focused
  testWidgets('📎 keeps the keyboard up', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final field = find.byType(TextField);
    final focus = tester.widget<TextField>(field).focusNode!;
    expect(focus.hasFocus, isTrue);
    await tester.tap(find.byKey(const ValueKey('quick-entry-attach')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Take photo'), findsOneWidget);
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    // 3.7.0.69: the menu sits above 📎, clear of the keyboard
    final clip =
        tester.getRect(find.byKey(const ValueKey('quick-entry-attach')));
    final last = tester.getRect(find.text('From gallery'));
    expect(last.bottom, lessThan(clip.top));
    expect(last.bottom, lessThan(2340 / 3 - 800 / 3));
  });
}
