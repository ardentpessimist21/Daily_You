// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

// Update L2: the work done on each frame while the keyboard slides up over a
// long entry. Built like the editor page: Scaffold, action bar overlay, the
// metadata card, and the text box in a SliverFillRemaining.
//
// Timings here come from a debug build on a desktop, so they don't match a
// phone; the counts do. Run with BENCH=1 to print them:
//   BENCH=1 flutter test test/fork/update_l2_keyboard_bench_test.dart

import 'dart:io';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A long entry shaped like a real journal: headings, paragraphs with bold
/// and italics, bullets, checkboxes, quotes and dividers.
String longEntry(int targetLength) {
  final buffer = StringBuffer();
  var i = 0;
  while (buffer.length < targetLength) {
    buffer
      ..writeln('## Morning ${i + 1}')
      ..writeln()
      ..writeln('Woke up early and had **coffee** on the balcony. The '
          'plants needed water again, and the *monstera* has a new leaf '
          'unfurling. Wrote a few notes before work and tried to keep the '
          'morning slow for once.')
      ..writeln()
      ..writeln('- [x] Water the plants')
      ..writeln('- [ ] Finish the ~~assignment~~ reading')
      ..writeln('- Pick up groceries on the way home')
      ..writeln()
      ..writeln('> Small steps still count.')
      ..writeln()
      ..writeln('Afternoon shift was busy but fine. Talked with a resident '
          'about her garden for a while, which was the nicest part of the '
          'day. Need to remember the `handover` notes tomorrow.')
      ..writeln()
      ..writeln('---')
      ..writeln();
    i++;
  }
  return buffer.toString().substring(0, targetLength);
}

class CountingController extends MarkdownPreviewController {
  CountingController({super.text});

  /// Times the styled text was built from scratch
  int restyles = 0;

  @override
  TextSpan buildStyledSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    restyles++;
    return super.buildStyledSpan(
        context: context, style: style, withComposing: withComposing);
  }
}

/// Stands in for the system: owns the keyboard height.
class KeyboardHarness extends StatefulWidget {
  final Widget child;

  const KeyboardHarness({super.key, required this.child});

  @override
  State<KeyboardHarness> createState() => KeyboardHarnessState();
}

class KeyboardHarnessState extends State<KeyboardHarness> {
  double inset = 0;

  void setInset(double value) => setState(() => inset = value);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        viewInsets: EdgeInsets.only(bottom: inset),
        // Android: the nav bar padding goes away under the keyboard
        padding: media.padding.copyWith(
            bottom: (media.viewPadding.bottom - inset)
                .clamp(0.0, media.viewPadding.bottom)),
      ),
      child: widget.child,
    );
  }
}

/// Built like AddEditEntryPage
class EditorPage extends StatelessWidget {
  final CountingController controller;
  final FocusNode focusNode;
  final UndoHistoryController undoController;
  final String text;

  const EditorPage({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.undoController,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(),
      body: EditorActionBarOverlay(
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SizedBox(height: 160, child: Card.filled()),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: EntryTextEditor(
                        text: text,
                        focusNode: focusNode,
                        textEditingController: controller,
                        undoHistoryController: undoController,
                      ),
                    ),
                    Builder(
                      builder: (context) => SizedBox(
                          height: 16 + EditorActionBar.reservedHeight(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actionBar: EditorActionBar(
          controller: controller,
          focusNode: focusNode,
          undoController: undoController,
          showTemplateButton: false,
          mainActions: const [],
        ),
      ),
    );
  }
}

class KeyboardRun {
  final int frames;
  final int rebuilds;
  final int restyles;
  final int textBoxResizes;
  final int textBoxPaints;
  final double averageMs;

  const KeyboardRun({
    required this.frames,
    required this.rebuilds,
    required this.restyles,
    required this.textBoxResizes,
    required this.textBoxPaints,
    required this.averageMs,
  });

  @override
  String toString() => 'over $frames frames: '
      'widget rebuilds $rebuilds, text restyled $restyles, '
      'text box resized $textBoxResizes, repainted $textBoxPaints, '
      'avg ${averageMs.toStringAsFixed(1)} ms/frame (debug, desktop)';
}

class Editor {
  final controller = CountingController();
  final focusNode = FocusNode();
  final undo = UndoHistoryController();
  final key = GlobalKey<KeyboardHarnessState>();

  Future<void> open(WidgetTester tester, String text) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    tester.view.viewPadding = const FakeViewPadding(bottom: 66);
    tester.view.padding = const FakeViewPadding(bottom: 66);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: KeyboardHarness(
        key: key,
        child: EditorPage(
          controller: controller,
          focusNode: focusNode,
          undoController: undo,
          text: text,
        ),
      ),
    ));
    await tester.pump();
  }

  RenderEditable textBox(WidgetTester tester) =>
      tester.allRenderObjects.whereType<RenderEditable>().single;

  /// Moves the keyboard from its current height to [to] over [frames]
  /// frames, like Android's inset animation, then lets it settle.
  Future<KeyboardRun> slideKeyboard(WidgetTester tester,
      {required double to, int frames = 14}) async {
    final box = textBox(tester);
    final from = key.currentState!.inset;
    var rebuilds = 0;
    var paints = 0;
    var resizes = 0;
    debugOnRebuildDirtyWidget = (element, __) {
      rebuilds++;
      if (_printBench) {
        var inBar = false;
        element.visitAncestorElements((a) {
          if (a.widget is EditorActionBar) inBar = true;
          return !inBar;
        });
        final k = '${inBar ? "bar" : "page"}:${element.widget.runtimeType}';
        rebuildTypes[k] = (rebuildTypes[k] ?? 0) + 1;
      }
    };
    debugOnProfilePaint = (render) {
      if (render is RenderEditable) paints++;
    };
    controller.restyles = 0;
    var lastSize = box.size;
    final watch = Stopwatch()..start();
    try {
      for (var frame = 1; frame <= frames; frame++) {
        key.currentState!.setInset(from + (to - from) * frame / frames);
        await tester.pump(const Duration(milliseconds: 16));
        if (box.size != lastSize) resizes++;
        lastSize = box.size;
      }
      watch.stop();
      // Keyboard has stopped: give anything waiting for that a chance
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (box.size != lastSize) resizes++;
        lastSize = box.size;
      }
    } finally {
      debugOnRebuildDirtyWidget = null;
      debugOnProfilePaint = null;
    }
    return KeyboardRun(
      frames: frames,
      rebuilds: rebuilds,
      restyles: controller.restyles,
      textBoxResizes: resizes,
      textBoxPaints: paints,
      averageMs: watch.elapsedMicroseconds / frames / 1000,
    );
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    focusNode.dispose();
    undo.dispose();
  }
}

final Map<String, int> rebuildTypes = {};
final bool _printBench = Platform.environment['BENCH'] == '1';

void _report(String label, KeyboardRun run) {
  // ignore: avoid_print
  if (_printBench) {
    // ignore: avoid_print
    print('L2 bench $label $run');
    final page = rebuildTypes.entries.where((e) => e.key.startsWith('page'));
    // ignore: avoid_print
    print('  page rebuilds: ${page.fold(0, (a, e) => a + e.value)} '
        '${(page.toList()..sort((a, b) => b.value - a.value)).take(12).map((e) => '${e.key}=${e.value}').join(', ')}');
    rebuildTypes.clear();
  }
}

void main() {
  for (final length in [3000, 30000]) {
    testWidgets('keyboard opening and closing over a $length-character entry',
        (tester) async {
      final text = longEntry(length);
      final editor = Editor();
      await editor.open(tester, text);
      editor.focusNode.requestFocus();
      await tester.pump();

      final opening = await editor.slideKeyboard(tester, to: 320);
      _report('$length chars, opening', opening);
      final closing = await editor.slideKeyboard(tester, to: 0);
      _report('$length chars, closing', closing);

      // While the keyboard moves, the entry isn't restyled, resized or
      // repainted on every frame: at most once when it stops
      for (final run in [opening, closing]) {
        expect(run.restyles, lessThanOrEqualTo(1));
        expect(run.textBoxResizes, lessThanOrEqualTo(1));
        // The cursor blinking also repaints it now and then
        expect(run.textBoxPaints, lessThanOrEqualTo(3));
      }

      await editor.close(tester);
    });
  }

  testWidgets('the toolbar rides on the keyboard on every frame',
      (tester) async {
    final editor = Editor();
    await editor.open(tester, longEntry(3000));
    editor.focusNode.requestFocus();
    await tester.pump();
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    double barBottom() => tester.getBottomLeft(find.byType(EditorActionBar)).dy;

    for (var frame = 1; frame <= 10; frame++) {
      final inset = 300.0 * frame / 10;
      editor.key.currentState!.setInset(inset);
      await tester.pump(const Duration(milliseconds: 16));
      expect(barBottom(), moreOrLessEquals(screen - inset));
    }
    await tester.pump(const Duration(milliseconds: 200));
    await editor.close(tester);
  });

  testWidgets(
      'once the keyboard stops, the page fits above it and the cursor '
      'is scrolled clear of the keyboard and toolbar', (tester) async {
    final editor = Editor();
    await editor.open(tester, longEntry(30000));
    final box = editor.textBox(tester);
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // Cursor low on the screen, where the keyboard will cover it
    final position = box.getPositionForPoint(Offset(200, screen - 120));
    editor.controller.selection =
        TextSelection.collapsed(offset: position.offset);
    editor.focusNode.requestFocus();
    await tester.pump();

    await editor.slideKeyboard(tester, to: 320);

    final scrollable = tester.getRect(find.byType(CustomScrollView));
    expect(scrollable.bottom, moreOrLessEquals(screen - 320));

    final caret = box.localToGlobal(box
        .getLocalRectForCaret(editor.controller.selection.extent)
        .bottomLeft);
    final barTop = tester.getTopLeft(find.byType(EditorActionBar)).dy;
    expect(caret.dy, lessThanOrEqualTo(barTop));
    expect(caret.dy, greaterThan(0));

    // Closing gives the page its full height back
    await editor.slideKeyboard(tester, to: 0);
    expect(tester.getRect(find.byType(CustomScrollView)).bottom,
        moreOrLessEquals(screen));
    await editor.close(tester);
  });

  testWidgets('typing still restyles the text straight away', (tester) async {
    final editor = Editor();
    await editor.open(tester, longEntry(3000));
    editor.focusNode.requestFocus();
    await tester.pump();
    editor.controller.restyles = 0;

    editor.controller.value = TextEditingValue(
      text: '**bold** ${editor.controller.text}',
      selection: const TextSelection.collapsed(offset: 8),
    );
    await tester.pump();
    expect(editor.controller.restyles, 1);
    final span = editor.textBox(tester).text! as TextSpan;
    expect(span.toPlainText(), startsWith('**bold** '));

    // Nothing changed: the same styled text is reused
    await tester.pump(const Duration(milliseconds: 16));
    expect(editor.controller.restyles, 1);
    await editor.close(tester);
  });
}
