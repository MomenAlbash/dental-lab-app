import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The luminance of the drawer's own panel, whatever gradient it is painting.
double panelLuminance(WidgetTester tester) {
  final decorated = tester.widgetList<Container>(
    find.descendant(of: find.byType(Drawer), matching: find.byType(Container)),
  );

  for (final container in decorated) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.gradient != null) {
      final colors = decoration.gradient!.colors;
      return colors.first.computeLuminance();
    }
  }

  fail('the drawer paints no gradient panel');
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    await getIt.reset();
    getIt
      ..registerLazySingleton<ThemeCubit>(() => ThemeCubit())
      ..registerLazySingleton<SessionCubit>(
        () => SessionCubit(
          initial: const Permissions(isAdmin: true, granted: {}),
        ),
      );
  });

  tearDown(() => getIt.reset());

  Future<void> pumpDrawer(WidgetTester tester, ThemeData theme) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          drawer: const AppDrawerWidget(currentRoute: Routes.homeScreen),
          body: const SizedBox(),
        ),
      ),
    );

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('the panel is light in the light theme', (tester) async {
    // The drawer used to be pinned to the logo's charcoal in both themes, so a
    // light app had one dark panel bolted to its side.
    await pumpDrawer(tester, AppTheme.light);

    expect(panelLuminance(tester), greaterThan(0.5));
  });

  testWidgets('the panel stays dark in the dark theme', (tester) async {
    await pumpDrawer(tester, AppTheme.dark);

    expect(panelLuminance(tester), lessThan(0.2));
  });

  testWidgets('labels are readable against the light panel', (tester) async {
    // The labels were hardcoded white, which only worked because the panel
    // underneath was always dark. On a light panel they vanished.
    await pumpDrawer(tester, AppTheme.light);

    final label = tester.widget<Text>(find.text('مخبر الأسنان'));

    expect(label.style?.color, isNotNull);
    expect(label.style!.color!.computeLuminance(), lessThan(0.5));
  });

  testWidgets('labels stay light against the dark panel', (tester) async {
    await pumpDrawer(tester, AppTheme.dark);

    final label = tester.widget<Text>(find.text('مخبر الأسنان'));

    expect(label.style!.color!.computeLuminance(), greaterThan(0.5));
  });
}
