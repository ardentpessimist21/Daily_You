import 'package:daily_you/fork/editor_buttons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

TextEditingController _at(String text, int offset) =>
    TextEditingController(text: text)
      ..selection = TextSelection.collapsed(offset: offset);

void main() {
  group('format buttons light up inside their formatting (3.10.0)', () {
    test('bold, italic, quote, bullet and heading', () {
      expect(EditorButtons.isActive(EditorAction.bold, _at('a **bold** b', 5)),
          isTrue);
      expect(EditorButtons.isActive(EditorAction.bold, _at('a **bold** b', 1)),
          isFalse);
      expect(
          EditorButtons.isActive(EditorAction.italic, _at('_it_', 2)), isTrue);
      expect(
          EditorButtons.isActive(EditorAction.quote, _at('> said', 4)), isTrue);
      expect(EditorButtons.isActive(EditorAction.bulletList, _at('- one', 3)),
          isTrue);
      expect(EditorButtons.isActive(EditorAction.headingMenu, _at('## Day', 5)),
          isTrue);
      expect(
          EditorButtons.isActive(EditorAction.time, _at('**x**', 3)), isFalse);
    });

    test('a checklist line does not light the bullet button', () {
      expect(
          EditorButtons.isActive(EditorAction.bulletList, _at('- [ ] task', 8)),
          isFalse);
    });

    testWidgets('tapping a lit-up button takes the formatting off',
        (tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      })));
      final controller = _at('a **bold** b', 5);
      await EditorButtons.run(EditorAction.bold, context, controller);
      expect(controller.text, 'a bold b');
      final quote = _at('> said', 4);
      await EditorButtons.run(EditorAction.quote, context, quote);
      expect(quote.text, 'said');
    });
  });
}
