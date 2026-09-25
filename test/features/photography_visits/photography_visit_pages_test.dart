import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/data/repos/photography_visits_repo.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_detail/photography_visit_detail_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_form/photography_visit_form_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/ui/photography_visit_detail_page.dart';
import 'package:dental_lab_app/features/photography_visits/ui/photography_visit_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockVisitsRepo extends Mock implements PhotographyVisitsRepo {}

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

class _MockPatientsRepo extends Mock implements PatientsRepo {}

class _MockEmployeesRepo extends Mock implements EmployeesRepo {}

class _MockAccountingRepo extends Mock implements AccountingRepo {}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late _MockAccountingRepo accounting;

  setUp(() {
    accounting = _MockAccountingRepo();
    when(() => accounting.getCurrencies()).thenAnswer(
      (_) async => const Right<Failure, List<CurrencyModel>>([
        CurrencyModel(id: 'c1', code: 'USD'),
      ]),
    );
  });

  tearDown(() async => getIt.reset());

  testWidgets('a visit fits a small phone, actions first', (tester) async {
    _phone(tester);
    final repo = _MockVisitsRepo();
    final employees = _MockEmployeesRepo();
    when(() => repo.getVisit('v1')).thenAnswer(
      (_) async => const Right<Failure, PhotographyVisitModel>(
        PhotographyVisitModel(
          id: 'v1',
          doctorId: 'd1',
          doctorName: 'د. سامر الأحمد',
          patientName: 'مريض باسم طويل جداً للاختبار',
          price: 50,
          currencyCode: 'USD',
          shade: PhotographyShadeNotes(toothShade: 'A2'),
        ),
      ),
    );
    when(
      () => employees.getEmployees(),
    ).thenAnswer((_) async => const Right<Failure, List<EmployeeModel>>([]));
    getIt.registerFactory<PhotographyVisitDetailCubit>(
      () => PhotographyVisitDetailCubit(repo, employees, accounting),
    );

    await tester.pumpWidget(
      _app(const PhotographyVisitDetailPage(visitId: 'v1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('إكمال الزيارة'), findsOneWidget);
    expect(find.text('د. سامر الأحمد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the request form fits a small phone', (tester) async {
    _phone(tester);
    final doctors = _MockDoctorsRepo();
    when(
      () => doctors.getDoctors(),
    ).thenAnswer((_) async => const Right<Failure, List<DoctorModel>>([]));
    getIt.registerFactory<PhotographyVisitFormCubit>(
      () => PhotographyVisitFormCubit(
        _MockVisitsRepo(),
        doctors,
        _MockPatientsRepo(),
        accounting,
      ),
    );

    await tester.pumpWidget(_app(const PhotographyVisitFormPage()));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الزيارة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
