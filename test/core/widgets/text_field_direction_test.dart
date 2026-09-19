import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<TextField> pumpField(
  WidgetTester tester, {
  TextInputType? keyboardType,
  TextDirection? textDirection,
  TextDirection page = TextDirection.rtl,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: page,
        child: Scaffold(
          body: AppTextFormField(
            hintText: 'hint',
            validator: (_) => null,
            keyboardType: keyboardType,
            textDirection: textDirection,
          ),
        ),
      ),
    ),
  );

  return tester.widget<TextField>(find.byType(TextField));
}

void main() {
  group('content direction', () {
    test('numberWithOptions is recognised despite being a fresh instance', () {
      // It is built per call, so identity comparison never matches it — the
      // decimal price fields were the ones this had to catch.
      expect(
        const TextInputType.numberWithOptions(decimal: true) ==
            TextInputType.number,
        isFalse,
      );
    });

    testWidgets('a number field is forced LTR inside an RTL page', (
      tester,
    ) async {
      // Digits are bidi-weak: inherited RTL runs their logical order opposite
      // to the screen, so the caret at the visual left sat at the start of the
      // text and backspace had nothing to delete.
      final field = await pumpField(tester, keyboardType: TextInputType.number);

      expect(field.textDirection, TextDirection.ltr);
    });

    testWidgets('a decimal number field is forced LTR too', (tester) async {
      final field = await pumpField(
        tester,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      );

      expect(field.textDirection, TextDirection.ltr);
    });

    testWidgets('phone, email and url fields are forced LTR', (tester) async {
      for (final type in [
        TextInputType.phone,
        TextInputType.emailAddress,
        TextInputType.url,
      ]) {
        final field = await pumpField(tester, keyboardType: type);
        expect(field.textDirection, TextDirection.ltr, reason: '$type');
      }
    });

    testWidgets('a free-text field keeps the page direction', (tester) async {
      // Arabic names and notes must stay RTL — this fix is only for fields
      // that can never hold Arabic.
      final field = await pumpField(tester, keyboardType: TextInputType.text);

      expect(field.textDirection, isNull);
    });

    testWidgets('an explicit direction wins over the derived one', (
      tester,
    ) async {
      final field = await pumpField(
        tester,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.rtl,
      );

      expect(field.textDirection, TextDirection.rtl);
    });
  });

  group('alignment', () {
    testWidgets('a number field still aligns to the RTL page edge', (
      tester,
    ) async {
      // Only the bidi order needed fixing. Letting an LTR field jump to the
      // left edge would rearrange every form for a bug about deletion.
      final field = await pumpField(tester, keyboardType: TextInputType.number);

      expect(field.textAlign, TextAlign.right);
    });

    testWidgets('an LTR page aligns left', (tester) async {
      final field = await pumpField(
        tester,
        keyboardType: TextInputType.number,
        page: TextDirection.ltr,
      );

      expect(field.textAlign, TextAlign.left);
    });
  });
}
