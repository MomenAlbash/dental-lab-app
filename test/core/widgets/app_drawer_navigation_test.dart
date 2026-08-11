import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/back_navigation.dart';

void main() {
  late GoRouter router;

  /// A stand-in for each destination: just the drawer plus a label, so the
  /// test is about navigation rather than any one page's content.
  Widget page(String title, String route) => Scaffold(
    appBar: AppBar(title: Text(title)),
    drawer: AppDrawerWidget(currentRoute: route),
    body: Center(child: Text('محتوى $title')),
  );

  /// A phone-sized surface — the default 800x600 test view is shorter than a
  /// real screen and makes the drawer list behave unrealistically.
  void usePhoneScreen(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    await getIt.reset();
    getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

    router = GoRouter(
      initialLocation: Routes.homeScreen,
      routes: [
        GoRoute(
          path: Routes.homeScreen,
          builder: (_, _) => page('الرئيسية', Routes.homeScreen),
        ),
        GoRoute(
          path: Routes.doctorsListScreen,
          builder: (_, _) => page('الدكاترة', Routes.doctorsListScreen),
        ),
        GoRoute(
          path: Routes.clinicsListScreen,
          builder: (_, _) => page('العيادات', Routes.clinicsListScreen),
        ),
      ],
    );
  });

  tearDown(() => getIt.reset());

  Widget wrap() => MaterialApp.router(
    theme: AppTheme.light,
    routerConfig: router,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );

  /// Finds a row inside the drawer, scoped so the page behind it — which
  /// carries the same label in its app bar — cannot make the finder ambiguous.
  Finder drawerRow(String label) => find.descendant(
    of: find.byType(AppDrawerWidget),
    matching: find.text(label),
  );

  /// Opens the drawer and taps a destination, stepping into [group] first when
  /// the destination lives on the drawer's second level.
  Future<void> navigateTo(
    WidgetTester tester,
    String label, {
    String? group,
  }) async {
    // By icon, not by tooltip: the tooltip is localised to Arabic here.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    if (group != null) {
      await tester.tap(drawerRow(group).first);
      await tester.pumpAndSettle();
    }

    await tester.tap(drawerRow(label).first);
    await tester.pumpAndSettle();
  }

  /// Opens the drawer without navigating anywhere.
  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
  }

  group('the two levels', () {
    testWidgets('the root shows groups, not the destinations inside them', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(wrap());
      await openDrawer(tester);

      expect(drawerRow('الجهات'), findsOneWidget);
      expect(drawerRow('المستخدمين'), findsOneWidget); // the group row
      // Destinations stay hidden until their group is opened.
      expect(drawerRow('الدكاترة'), findsNothing);
      expect(drawerRow('الموظفين'), findsNothing);
      expect(drawerRow('العيادات'), findsNothing);
    });

    testWidgets('opening a group reveals its destinations and hides the rest', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(wrap());
      await openDrawer(tester);

      await tester.tap(drawerRow('الجهات').first);
      await tester.pumpAndSettle();

      expect(drawerRow('المرضى'), findsOneWidget);
      expect(drawerRow('الدكاترة'), findsOneWidget);
      expect(drawerRow('العيادات'), findsOneWidget);
      // Other groups are gone: this is a level, not an expansion.
      expect(drawerRow('المخابر'), findsNothing);
      expect(drawerRow('الرئيسية'), findsNothing);
    });

    testWidgets('the back arrow returns to the root', (tester) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(wrap());
      await openDrawer(tester);
      await tester.tap(drawerRow('الجهات').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(drawerRow('الرئيسية'), findsOneWidget);
      expect(drawerRow('الدكاترة'), findsNothing);
    });

    testWidgets('system back steps out of a group instead of closing', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(wrap());
      await openDrawer(tester);
      await tester.tap(drawerRow('الجهات').first);
      await tester.pumpAndSettle();

      await systemBack(tester);

      // Still open, back at the root — the drawer did not close.
      expect(drawerRow('الرئيسية'), findsOneWidget);
      expect(drawerRow('الدكاترة'), findsNothing);
    });

    testWidgets('the drawer reopens at the root after navigating', (
      tester,
    ) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(wrap());

      await navigateTo(tester, 'الدكاترة', group: 'الجهات');
      await openDrawer(tester);

      // Not still sitting inside the group it was last used from.
      expect(drawerRow('الجهات'), findsOneWidget);
      expect(drawerRow('الدكاترة'), findsNothing);
    });

    testWidgets('the group holding the current page is marked', (tester) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(wrap());
      await navigateTo(tester, 'الدكاترة', group: 'الجهات');
      await openDrawer(tester);

      final tile = tester.widget<ListTile>(
        find.ancestor(of: drawerRow('الجهات'), matching: find.byType(ListTile)),
      );
      expect(tile.selected, isTrue);
    });
  });

  testWidgets('a second drawer destination replaces the first', (tester) async {
    // The reported flow: Home → a page → drawer → another page. Back used to
    // walk through every page visited instead of returning to Home.
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    expect(find.text('محتوى الرئيسية'), findsOneWidget);

    await navigateTo(tester, 'الدكاترة', group: 'الجهات');
    expect(find.text('محتوى الدكاترة'), findsOneWidget);

    await navigateTo(tester, 'العيادات', group: 'الجهات');
    expect(find.text('محتوى العيادات'), findsOneWidget);

    await systemBack(tester);

    expect(find.text('محتوى الرئيسية'), findsOneWidget);
    expect(find.text('محتوى الدكاترة'), findsNothing);
  });

  testWidgets('back from the first destination returns to home', (
    tester,
  ) async {
    // Home must stay underneath — replacing here would leave nothing to pop
    // and back would exit the app.
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());

    await navigateTo(tester, 'الدكاترة', group: 'الجهات');
    await systemBack(tester);

    expect(find.text('محتوى الرئيسية'), findsOneWidget);
  });

  testWidgets('hopping across many destinations still leaves one page', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());

    await navigateTo(tester, 'الدكاترة', group: 'الجهات');
    await navigateTo(tester, 'العيادات', group: 'الجهات');
    await navigateTo(tester, 'الدكاترة', group: 'الجهات');
    await navigateTo(tester, 'العيادات', group: 'الجهات');

    await systemBack(tester);

    expect(find.text('محتوى الرئيسية'), findsOneWidget);
  });

  testWidgets('tapping home from a destination goes back to home', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());

    await navigateTo(tester, 'الدكاترة', group: 'الجهات');
    await navigateTo(tester, 'الرئيسية');

    expect(find.text('محتوى الرئيسية'), findsOneWidget);
  });

  testWidgets('tapping the destination already open just closes the drawer', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await navigateTo(tester, 'الدكاترة', group: 'الجهات');

    await navigateTo(tester, 'الدكاترة', group: 'الجهات');

    expect(find.text('محتوى الدكاترة'), findsOneWidget);
    await systemBack(tester);
    expect(find.text('محتوى الرئيسية'), findsOneWidget);
  });
}
