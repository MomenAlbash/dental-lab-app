import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/auth/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const LoginPage(),
  );

  testWidgets('Login renders without overflow at 360dp width', (tester) async {
    // Small-phone breakpoint (~360dp width) per CLAUDE.md Section C.6.
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('مرحباً بك'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login shows validation errors when submitted empty', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('اسم المستخدم مطلوب'), findsOneWidget);
    expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);
  });
}
