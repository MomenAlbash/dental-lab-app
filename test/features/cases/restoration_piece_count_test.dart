import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/route_definition_model.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/route_preview/route_preview_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_restorations_step.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRestorationTypesRepo extends Mock implements RestorationTypesRepo {}

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockAccountingRepo extends Mock implements AccountingRepo {}

void main() {
  late _MockRestorationTypesRepo typesRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    typesRepo = _MockRestorationTypesRepo();
    when(() => typesRepo.getRestorationTypes()).thenAnswer(
      (_) async => Right<Failure, List<RestorationTypeModel>>([
        RestorationTypeModel(id: 'rt1', name: 'زيركون', nameAr: 'زيركون'),
      ]),
    );

    final casesRepo = _MockCasesRepo();
    when(() => casesRepo.getRouteDefinition(any())).thenAnswer(
      (_) async => Right<Failure, RouteDefinitionModel>(
        const RouteDefinitionModel(restorationTypeId: 'rt1'),
      ),
    );

    final accountingRepo = _MockAccountingRepo();
    when(
      () => accountingRepo.getCurrencies(),
    ).thenAnswer((_) async => Right<Failure, List<CurrencyModel>>(const []));

    await getIt.reset();
    getIt
      ..registerFactory<RoutePreviewCubit>(() => RoutePreviewCubit(casesRepo))
      ..registerLazySingleton<AccountingRepo>(() => accountingRepo)
      // The form asks the session whether prices may be shown; an admin keeps
      // the price field on screen so the layout under test is the full one —
      // which is also what makes it load the currency picker.
      ..registerLazySingleton<SessionCubit>(
        () => SessionCubit(
          initial: const Permissions(isAdmin: true, granted: {}),
        ),
      );
  });

  tearDown(() => getIt.reset());

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  RestorationTypesCubit(typesRepo)..getRestorationTypes(),
            ),
            BlocProvider(create: (_) => getIt<RoutePreviewCubit>()),
          ],
          child: const AddRestorationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the quantity field is labelled as a piece count', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('عدد القطع'), findsOneWidget);
    expect(find.text('الكمية'), findsNothing);
  });

  testWidgets('an empty piece count is refused', (tester) async {
    await pumpPage(tester);

    final field = find.widgetWithText(TextFormField, '1');
    await tester.enterText(field, '');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('عدد القطع مطلوب'), findsOneWidget);
  });

  testWidgets('zero pieces is refused', (tester) async {
    // A restoration line for no units is not an order.
    await pumpPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '1'), '0');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('عدد القطع لا يقل عن 1'), findsOneWidget);
  });

  testWidgets('the count is free while no teeth are charted', (tester) async {
    // A line entered before the chart is filled in is incomplete, not wrong —
    // blocking it would stop the user halfway through their own order of work.
    await pumpPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '1'), '3');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('لا يطابق الأسنان'), findsNothing);
  });
}
