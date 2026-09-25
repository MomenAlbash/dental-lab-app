import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';
import 'package:dental_lab_app/features/stage_pay/data/repos/stage_pay_repo.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_earnings/stage_earnings_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_rates/stage_rates_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/ui/widgets/stage_earnings_tab.dart';
import 'package:dental_lab_app/features/stage_pay/ui/widgets/stage_rates_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStagePayRepo extends Mock implements StagePayRepo {}

class _MockEmployeesRepo extends Mock implements EmployeesRepo {}

Widget _wrap<C extends Cubit<Object?>>(C cubit, Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: BlocProvider<C>.value(value: cubit, child: child),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late _MockStagePayRepo repo;

  setUp(() {
    repo = _MockStagePayRepo();
    registerFallbackValue(DateTime(2026));
  });

  testWidgets('prices fit a small phone with a type expanded', (tester) async {
    _phone(tester);
    when(() => repo.getRates()).thenAnswer(
      (_) async => const Right<Failure, List<StagePayRestorationTypeModel>>([
        StagePayRestorationTypeModel(
          restorationTypeId: 't1',
          laboratoryId: 'l1',
          nameAr: 'زيركون',
          stages: [
            StagePayRateModel(
              rootStageId: 's1',
              nameAr: 'تصميم رقمي طويل الاسم جداً',
              amount: 100,
            ),
          ],
        ),
      ]),
    );
    final cubit = StageRatesCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(_wrap(cubit, const StageRatesTab(canEdit: true)));
    await tester.tap(find.text('زيركون'));
    await tester.pumpAndSettle();

    expect(find.text('تصميم رقمي طويل الاسم جداً'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('earnings fit a small phone', (tester) async {
    _phone(tester);
    final employeesRepo = _MockEmployeesRepo();
    when(
      () => employeesRepo.getEmployees(),
    ).thenAnswer((_) async => const Right<Failure, List<EmployeeModel>>([]));
    when(
      () => repo.getEarnings(
        from: any(named: 'from'),
        to: any(named: 'to'),
        employeeId: any(named: 'employeeId'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<EmployeeStageEarningModel>>([
        EmployeeStageEarningModel(
          id: '1',
          employeeId: 'e1',
          employeeName: 'أحمد',
          caseNumber: '120',
          stageNameAr: 'تصميم',
          restorationTypeNameAr: 'زيركون',
          quantity: 3,
          unitAmount: 100,
          amount: 300,
          earnedAt: DateTime(2026, 9, 20),
        ),
      ]),
    );
    final cubit = StageEarningsCubit(repo, employeesRepo);
    addTearDown(cubit.close);
    await cubit.init();

    await tester.pumpWidget(_wrap(cubit, const StageEarningsTab()));
    await tester.pumpAndSettle();

    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('المجموع: 300.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
