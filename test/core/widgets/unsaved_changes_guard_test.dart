import 'dart:async';

import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/unsaved_changes_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/back_navigation.dart';

void main() {
  const dialogTitle = 'تجاهل التعديلات؟';
  const stay = 'متابعة التعديل';
  const leave = 'خروج بدون حفظ';

  /// Hosts the guarded page behind a "home" screen so a pop is observable.
  /// [dirty] is read through the getter at pop time, and deliberately not held
  /// in widget state — that is the behaviour under test.
  Widget host({
    required ValueGetter<bool> isDirty,
    Object? popResult,
    ValueChanged<Object?>? onReturned,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final returned = await Navigator.of(context).push<Object?>(
                  MaterialPageRoute(
                    builder: (_) => UnsavedChangesGuard(
                      isDirty: isDirty,
                      child: Scaffold(
                        appBar: AppBar(title: const Text('النموذج')),
                        body: Center(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(popResult),
                            child: const Text('حفظ'),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                onReturned?.call(returned);
              },
              child: const Text('فتح'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    expect(find.text('النموذج'), findsOneWidget);
  }

  testWidgets('a clean form leaves immediately, with no dialog', (
    tester,
  ) async {
    await tester.pumpWidget(host(isDirty: () => false));
    await openForm(tester);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('النموذج'), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('a dirty form asks and stays put until answered', (tester) async {
    await tester.pumpWidget(host(isDirty: () => true));
    await openForm(tester);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
    expect(
      find.text('لديك تعديلات غير محفوظة، وإذا خرجت الآن ستفقدها.'),
      findsOneWidget,
    );
    expect(find.text(leave), findsOneWidget);
    expect(find.text(stay), findsOneWidget);
    expect(find.text('النموذج'), findsOneWidget);
  });

  testWidgets('choosing to keep editing stays on the form', (tester) async {
    await tester.pumpWidget(host(isDirty: () => true));
    await openForm(tester);
    await systemBack(tester);

    await tester.tap(find.text(stay));
    await tester.pumpAndSettle();

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('النموذج'), findsOneWidget);
  });

  testWidgets('choosing to discard leaves the form', (tester) async {
    await tester.pumpWidget(host(isDirty: () => true));
    await openForm(tester);
    await systemBack(tester);

    await tester.tap(find.text(leave));
    await tester.pumpAndSettle();

    expect(find.text('النموذج'), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('the app bar back button asks too, not just system back', (
    tester,
  ) async {
    await tester.pumpWidget(host(isDirty: () => true));
    await openForm(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text(dialogTitle), findsOneWidget);
  });

  testWidgets('a programmatic pop is not intercepted and keeps its result', (
    tester,
  ) async {
    // Regression: the guard sets canPop:false, which must not break a page's
    // own save-success pop. Only maybePop consults canPop.
    Object? returned;
    await tester.pumpWidget(
      host(
        isDirty: () => true,
        popResult: true,
        onReturned: (value) => returned = value,
      ),
    );
    await openForm(tester);

    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
    expect(returned, isTrue);
  });

  testWidgets('two back presses before the dialog mounts raise only one', (
    tester,
  ) async {
    await tester.pumpWidget(host(isDirty: () => true));
    await openForm(tester);

    // Fired back to back without settling in between, so both reach the guard
    // before the first dialog is on screen. Without the _isAsking latch this
    // stacks two identical dialogs. (Driven through maybePop rather than two
    // `popRoute` platform messages: dispatching those with no frame between
    // trips an assertion inside the framework's own observer plumbing.)
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    unawaited(navigator.maybePop());
    unawaited(navigator.maybePop());
    await tester.pumpAndSettle();

    expect(find.text(dialogTitle), findsOneWidget);
    expect(find.text('النموذج'), findsOneWidget);
  });

  testWidgets('back while the dialog is open cancels it and keeps the form', (
    tester,
  ) async {
    // Once the dialog is up it is the topmost route, so a second back
    // dismisses the dialog rather than the form — which reads as "cancel".
    await tester.pumpWidget(host(isDirty: () => true));
    await openForm(tester);
    await systemBack(tester);
    expect(find.text(dialogTitle), findsOneWidget);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('النموذج'), findsOneWidget);
  });

  testWidgets('dirtiness is read at pop time, not at build time', (
    tester,
  ) async {
    // Mutated without any setState — a canPop computed during build would
    // still be false here and let the user walk away silently.
    var dirty = false;
    await tester.pumpWidget(host(isDirty: () => dirty));
    await openForm(tester);

    dirty = true;
    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
  });

  testWidgets('the dialog fits a 360dp screen', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(isDirty: () => true));
    await openForm(tester);
    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
