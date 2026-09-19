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

/// The spec's rule is **hidden**, not disabled: a destination the user cannot
/// open must not appear at all. These tests sign in as users with different
/// grants and assert on what the drawer offers.
void main() {
  Future<void> signInWith(Permissions permissions) async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    await getIt.reset();
    getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
    getIt.registerLazySingleton<SessionCubit>(
      () => SessionCubit(initial: permissions),
    );
  }

  Future<void> pumpDrawer(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          appBar: AppBar(),
          drawer: const AppDrawerWidget(currentRoute: Routes.homeScreen),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    // By icon, not by tooltip: the tooltip is localised to Arabic here.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
  }

  testWidgets('an admin sees every group', (tester) async {
    await signInWith(const Permissions(isAdmin: true, granted: {}));
    await pumpDrawer(tester);

    expect(find.text('الحالات'), findsWidgets);
    expect(find.text('الجهات'), findsOneWidget);
    expect(find.text('المستخدمين'), findsWidgets);
    expect(find.text('الفروع'), findsOneWidget);
  });

  testWidgets('a group with no permitted rows is hidden entirely', (
    tester,
  ) async {
    // Cases only — the people, roles and laboratory groups have nothing this
    // user may open.
    await signInWith(
      const Permissions(
        isAdmin: false,
        granted: {PermissionName.cases: PermissionType.read},
      ),
    );
    await pumpDrawer(tester);

    expect(find.text('الحالات'), findsWidgets);
    expect(find.text('الجهات'), findsNothing);
    expect(find.text('الفروع'), findsNothing);
  });

  testWidgets('a permitted group hides the rows inside it that are not', (
    tester,
  ) async {
    // Users but not Roles: the "المستخدمين" group opens, and the roles row is
    // gone from inside it.
    await signInWith(
      const Permissions(
        isAdmin: false,
        granted: {PermissionName.users: PermissionType.read},
      ),
    );
    await pumpDrawer(tester);

    await tester.tap(find.text('المستخدمين').first);
    await tester.pumpAndSettle();

    expect(find.text('الموظفين'), findsOneWidget);
    expect(find.text('الأدوار'), findsNothing);
  });

  testWidgets('a user with no grants at all sees no groups', (tester) async {
    await signInWith(Permissions.empty);
    await pumpDrawer(tester);

    expect(find.text('الجهات'), findsNothing);
    expect(find.text('الفروع'), findsNothing);
    // Home and settings are open to any authenticated user, so they stay.
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('read on a module is enough to see its rows', (tester) async {
    await signInWith(
      const Permissions(
        isAdmin: false,
        granted: {PermissionName.branches: PermissionType.read},
      ),
    );
    await pumpDrawer(tester);

    expect(find.text('الفروع'), findsOneWidget);
  });
}
