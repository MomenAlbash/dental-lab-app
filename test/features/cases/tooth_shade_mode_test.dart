import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/route_definition_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/route_preview/route_preview_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
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
      ..registerLazySingleton<SessionCubit>(
        () => SessionCubit(
          initial: const Permissions(isAdmin: true, granted: {}),
        ),
      );
  });

  tearDown(() => getIt.reset());

  /// Opens the form the same way the case wizard does — pushed as a route —
  /// so its popped [RestorationEntry] can be captured.
  Future<RestorationEntry?> openAndSubmit(
    WidgetTester tester, {
    RestorationEntry? initial,
    required Future<void> Function(WidgetTester) act,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    RestorationEntry? result;
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<RestorationEntry>(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (_) =>
                              RestorationTypesCubit(typesRepo)
                                ..getRestorationTypes(),
                        ),
                        BlocProvider(create: (_) => getIt<RoutePreviewCubit>()),
                      ],
                      child: AddRestorationPage(initial: initial),
                    ),
                  ),
                );
              },
              child: const Text('فتح'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();

    await act(tester);

    return result;
  }

  testWidgets('a new line opens on "عام" with a shade already filled in', (
    tester,
  ) async {
    await openAndSubmit(
      tester,
      act: (tester) async {
        expect(find.text('عام'), findsOneWidget);
        expect(find.text('مخصص'), findsOneWidget);
        // The undivided tooth already carries a default — not blank, and not
        // demanding three taps before the line can be submitted.
        expect(find.text('A1'), findsOneWidget);
      },
    );
  });

  testWidgets('a uniform pick fills all three zones with the same shade', (
    tester,
  ) async {
    final entry = await openAndSubmit(
      tester,
      act: (tester) async {
        // A type has to be picked before "إضافة" does anything at all.
        await tester.tap(find.widgetWithText(TextField, 'اختر التعويض'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('زيركون').last);
        await tester.pumpAndSettle();

        // The mock type carries no per-currency prices, so the plain price
        // field is the one that renders — and it is required.
        final priceField = find.widgetWithText(
          TextFormField,
          'أدخل سعر الوحدة',
        );
        await tester.ensureVisible(priceField);
        await tester.enterText(priceField, '100');
        await tester.pumpAndSettle();

        // Opens the shade-picker sheet — the tooth already shows the
        // default "A1", tapping it is how any shade gets changed.
        await tester.ensureVisible(find.text('A1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('A2'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('إضافة'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('إضافة'));
        await tester.pumpAndSettle();
      },
    );

    expect(entry, isNotNull);
    expect(entry!.shadeCervical, 'A2');
    expect(entry.shadeMiddle, 'A2');
    expect(entry.shadeIncisal, 'A2');
  });

  testWidgets('reopening a line with three different zones shows "مخصص"', (
    tester,
  ) async {
    final initial = RestorationEntry(
      restorationTypeId: 'rt1',
      restorationName: 'زيركون',
      shadeLayout: 'Vita Classical',
      shadeCervical: 'A3',
      shadeMiddle: 'A2',
      shadeIncisal: 'A1',
    );

    await openAndSubmit(
      tester,
      initial: initial,
      act: (tester) async {
        expect(find.text('العنقي'), findsOneWidget);
        expect(find.text('الوسط'), findsOneWidget);
        expect(find.text('القاطع'), findsOneWidget);
      },
    );
  });

  testWidgets('reopening a line saved with one colour everywhere shows "عام"', (
    tester,
  ) async {
    final initial = RestorationEntry(
      restorationTypeId: 'rt1',
      restorationName: 'زيركون',
      shadeLayout: 'Vita Classical',
      shadeCervical: 'B2',
      shadeMiddle: 'B2',
      shadeIncisal: 'B2',
    );

    await openAndSubmit(
      tester,
      initial: initial,
      act: (tester) async {
        expect(find.text('لون السن'), findsOneWidget);
        expect(find.text('العنقي'), findsNothing);
      },
    );
  });
}
