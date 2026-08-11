import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/font_scale_cubit.dart';
import 'package:dental_lab_app/features/settings/ui/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/back_navigation.dart';

void main() {
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    router = GoRouter(
      initialLocation: Routes.settingsScreen,
      routes: [
        GoRoute(
          path: Routes.settingsScreen,
          builder: (_, _) => const SettingsPage(),
        ),
        GoRoute(
          path: Routes.currenciesListScreen,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('شاشة العملات'))),
        ),
      ],
    );
  });

  /// Mirrors how `main.dart` wires the app: the chosen scale is applied in
  /// `MaterialApp.builder`. Without that here the test would exercise the
  /// selector but not the thing it is supposed to change.
  Widget wrap({ThemeData? theme}) => BlocProvider<FontScaleCubit>(
    create: (_) => FontScaleCubit(),
    child: MaterialApp.router(
      theme: theme ?? AppTheme.light,
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => BlocBuilder<FontScaleCubit, FontScale>(
        builder: (context, fontScale) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: applyFontScale(media.textScaler, fontScale),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    ),
  );

  void usePhoneScreen(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
  }

  testWidgets('lists the reference data at 360dp without overflow', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('العملات'), findsOneWidget);
    expect(find.text('الدول'), findsOneWidget);
    expect(find.text('المدن'), findsOneWidget);
    // A RenderFlex overflow surfaces here.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a card opens its screen and can be backed out of', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('العملات'));
    await tester.pumpAndSettle();
    expect(find.text('شاشة العملات'), findsOneWidget);

    // Pushed, not replaced: settings is still underneath to come back to.
    await systemBack(tester);
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('offers the three text sizes and applies the pick', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('حجم الخط'), findsOneWidget);
    expect(find.text('صغير'), findsOneWidget);
    expect(find.text('وسط'), findsOneWidget);
    expect(find.text('كبير'), findsOneWidget);

    // A settings label grows once the large option is chosen — the setting is
    // live, not just stored.
    final before = tester.getSize(find.text('العملات')).height;

    await tester.tap(find.text('كبير'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.text('العملات')).height, greaterThan(before));
  });

  testWidgets('the pick survives leaving and returning to the page', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('صغير'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('العملات'));
    await tester.pumpAndSettle();
    await systemBack(tester);

    // Read back from storage by a fresh cubit, not just held in memory.
    expect(FontScaleCubit().state, FontScale.small);
  });

  testWidgets('renders in the dark theme without exceptions', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap(theme: AppTheme.dark));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
