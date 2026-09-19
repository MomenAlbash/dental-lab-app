import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpField(
  WidgetTester tester, {
  required TextEditingController controller,
  FocusNode? focusNode,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AppTextFormField(
            hintText: 'hint',
            validator: (_) => null,
            keyboardType: TextInputType.number,
            controller: controller,
            focusNode: focusNode,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('focusing a field puts the caret after the last character', (
    tester,
  ) async {
    // Backspace deletes what is *before* the caret. Tapping a short value used
    // to leave the caret at position zero, where there is nothing before it —
    // so pressing delete did nothing and the field looked broken.
    final controller = TextEditingController(text: '40');
    addTearDown(controller.dispose);

    await pumpField(tester, controller: controller);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 2);
    expect(controller.selection.isCollapsed, isTrue);
  });

  testWidgets('deleting from that caret removes the last character', (
    tester,
  ) async {
    final controller = TextEditingController(text: '40');
    addTearDown(controller.dispose);

    await pumpField(tester, controller: controller);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // What the keyboard's backspace does at the caret.
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(controller.text, '4');
  });

  testWidgets('an empty field is left alone', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(tester, controller: controller);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a caret moved while already focused is not dragged back', (
    tester,
  ) async {
    // The jump only happens on focus *gain*; a user placing the caret
    // mid-number in a field they are already editing keeps it there.
    final controller = TextEditingController(text: '1234');
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await pumpField(tester, controller: controller, focusNode: focusNode);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 2);
  });

  testWidgets('re-entering a field jumps to the end again', (tester) async {
    final controller = TextEditingController(text: '1234');
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await pumpField(tester, controller: controller, focusNode: focusNode);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    controller.selection = const TextSelection.collapsed(offset: 1);
    focusNode.unfocus();
    await tester.pumpAndSettle();

    focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 4);
  });
}
