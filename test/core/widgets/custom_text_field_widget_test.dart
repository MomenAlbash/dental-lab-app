import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme, GlobalKey<FormState>? formKey}) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets('renders the hint and optional label', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppTextFormField(
          hintText: 'أدخل الاسم',
          textField: 'الاسم',
          validator: (_) => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أدخل الاسم'), findsOneWidget);
    expect(find.text('الاسم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the validator message on a failed submit', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      wrap(
        AppTextFormField(
          hintText: 'أدخل الاسم',
          validator: (value) =>
              (value == null || value.isEmpty) ? 'الحقل مطلوب' : null,
        ),
        formKey: formKey,
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();

    expect(find.text('الحقل مطلوب'), findsOneWidget);
    // The shake animation must settle rather than run forever.
    expect(tester.takeException(), isNull);
  });

  testWidgets('clears the error once the value becomes valid', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        AppTextFormField(
          controller: controller,
          hintText: 'أدخل الاسم',
          validator: (value) =>
              (value == null || value.isEmpty) ? 'الحقل مطلوب' : null,
        ),
        formKey: formKey,
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('الحقل مطلوب'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'أحمد');
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('الحقل مطلوب'), findsNothing);
  });

  testWidgets('applies the supplied hintStyle', (tester) async {
    // Regression test: hintStyle used to be declared but never passed to the
    // TextFormField, so callers' styling was silently dropped.
    const hintStyle = TextStyle(fontSize: 22, color: Color(0xFF00FF00));

    await tester.pumpWidget(
      wrap(
        const AppTextFormField(
          hintText: 'أدخل الاسم',
          hintStyle: hintStyle,
          validator: _noValidation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.hintStyle, hintStyle);
  });

  testWidgets('applies the supplied inputTextStyle', (tester) async {
    const inputStyle = TextStyle(fontSize: 19, color: Color(0xFF0000FF));

    await tester.pumpWidget(
      wrap(
        const AppTextFormField(
          hintText: 'أدخل الاسم',
          inputTextStyle: inputStyle,
          validator: _noValidation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).style, inputStyle);
  });

  testWidgets('obscureToggle reveals and re-hides the text', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppTextFormField(
          hintText: 'كلمة المرور',
          isObscureText: true,
          obscureToggle: true,
          validator: _noValidation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
  });

  testWidgets('does not dispose a caller-owned FocusNode', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      wrap(
        AppTextFormField(
          hintText: 'أدخل الاسم',
          focusNode: focusNode,
          validator: (_) => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Replacing the widget tree disposes the field's State.
    await tester.pumpWidget(wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    // Still usable — proof the widget did not dispose a node it does not own.
    expect(focusNode.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in the dark theme without exceptions', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppTextFormField(
          hintText: 'أدخل الاسم',
          textField: 'الاسم',
          validator: _noValidation,
        ),
        theme: AppTheme.dark,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أدخل الاسم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String? _noValidation(String? _) => null;
