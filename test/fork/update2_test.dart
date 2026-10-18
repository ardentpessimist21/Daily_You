// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/checklists.dart';
import 'package:daily_you/fork/editor_buttons.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Checklists.toggle', () {
    const text = 'Shift tasks\n- [ ] Care plans\n- [x] Meds round\n* [ ] Notes';

    test('counts every box', () {
      expect(Checklists.count(text), 3);
    });

    test('ticks the chosen box only', () {
      expect(Checklists.toggle(text, 0),
          'Shift tasks\n- [x] Care plans\n- [x] Meds round\n* [ ] Notes');
    });

    test('unticks a ticked box', () {
      expect(Checklists.toggle(text, 1),
          'Shift tasks\n- [ ] Care plans\n- [ ] Meds round\n* [ ] Notes');
    });

    test('ignores an index that does not exist', () {
      expect(Checklists.toggle(text, 9), text);
    });
  });

  group('Enter after a checklist item', () {
    late TextEditingController controller;
    late BulletListContinuation continuation;

    setUp(() {
      controller = TextEditingController();
      continuation = BulletListContinuation(controller);
    });
    tearDown(() => continuation.dispose());

    void type(String text) => controller.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));

    test('continues with a fresh unticked box', () {
      type('- [x] Meds round');
      type('- [x] Meds round\n');
      expect(controller.text, '- [x] Meds round\n- [ ] ');
    });

    test('an empty box ends the list', () {
      type('- [ ] Care plans\n- [ ] ');
      type('- [ ] Care plans\n- [ ] \n');
      expect(controller.text, '- [ ] Care plans\n');
    });

    test('plain bullets still continue as bullets', () {
      type('- milk');
      type('- milk\n');
      expect(controller.text, '- milk\n- ');
    });
  });

  group('insertOnOwnLine', () {
    test('mid-sentence starts a new line and leaves the cursor below', () {
      final controller = TextEditingController(text: 'Nagutom ako.');
      controller.selection = const TextSelection.collapsed(offset: 12);
      EditorButtons.insertOnOwnLine(controller, '11:55 AM');
      expect(controller.text, 'Nagutom ako.\n11:55 AM\n');
      expect(controller.selection.baseOffset, controller.text.length);
    });

    test('at the start of a line adds no blank line', () {
      final controller = TextEditingController(text: 'Hello\n');
      controller.selection = const TextSelection.collapsed(offset: 6);
      EditorButtons.insertOnOwnLine(controller, '---');
      expect(controller.text, 'Hello\n---\n');
    });
  });

  testWidgets('tapping a rendered checkbox reports the right index',
      (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScaledMarkdown(
          data: 'Today\n\n- [ ] first\n- [x] second\n- [ ] third\n',
          selectable: false,
          onCheckboxTap: tapped.add,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final empty = find.byIcon(Icons.check_box_outline_blank_rounded);
    final ticked = find.byIcon(Icons.check_box_rounded);
    expect(empty, findsNWidgets(2));
    expect(ticked, findsOneWidget);
    await tester.tap(empty.at(1)); // "third"
    await tester.tap(ticked); // "second"
    await tester.tap(empty.at(0)); // "first"
    expect(tapped, [2, 1, 0]);
    expect(tester.takeException(), isNull);
  });
}
