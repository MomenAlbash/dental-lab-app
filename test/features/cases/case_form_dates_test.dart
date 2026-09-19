import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/case_stages/data/repos/case_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/repos/workflow_stages_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/optional_stages/optional_stages_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

class _MockPatientsRepo extends Mock implements PatientsRepo {}

class _MockRestorationTypesRepo extends Mock implements RestorationTypesRepo {}

class _MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

class _MockCaseStagesRepo extends Mock implements CaseStagesRepo {}

class _MockWorkflowStagesRepo extends Mock implements WorkflowStagesRepo {}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    final doctorsRepo = _MockDoctorsRepo();
    when(() => doctorsRepo.getDoctors()).thenAnswer(
      (_) async => Right<Failure, List<DoctorModel>>([
        DoctorModel(id: 'd1', firstName: 'أحمد', lastName: 'الخطيب'),
      ]),
    );

    final patientsRepo = _MockPatientsRepo();
    when(() => patientsRepo.getPatients()).thenAnswer(
      (_) async => Right<Failure, List<PatientModel>>([
        PatientModel(id: 'p1', firstName: 'خالد', lastName: 'المصري'),
      ]),
    );

    final typesRepo = _MockRestorationTypesRepo();
    when(() => typesRepo.getRestorationTypes()).thenAnswer(
      (_) async => Right<Failure, List<RestorationTypeModel>>(const []),
    );

    final prioritiesRepo = _MockCasePrioritiesRepo();
    when(
      () => prioritiesRepo.getCasePriorities(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<CasePriorityModel>>(const [
        CasePriorityModel(id: 'pr1', nameAr: 'عادية', isDefault: true),
      ]),
    );

    await getIt.reset();
    getIt.registerFactory<CasePrioritiesCubit>(
      () => CasePrioritiesCubit(prioritiesRepo),
    );
    getIt.registerFactory<CaseFormCubit>(() => CaseFormCubit(_MockCasesRepo()));
    getIt.registerFactory<DoctorsCubit>(() => DoctorsCubit(doctorsRepo));
    getIt.registerFactory<PatientsCubit>(() => PatientsCubit(patientsRepo));
    getIt.registerFactory<RestorationTypesCubit>(
      () => RestorationTypesCubit(typesRepo),
    );
    // The optional-stages step reaches for it as soon as the wizard builds.
    getIt.registerFactory<OptionalStagesCubit>(
      () =>
          OptionalStagesCubit(_MockCaseStagesRepo(), _MockWorkflowStagesRepo()),
    );
  });

  tearDown(() => getIt.reset());

  Widget wrap() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const CaseFormPage(),
  );

  Future<void> openWizard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  String isoToday() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  testWidgets('the received date is pre-filled with today', (tester) async {
    // A case is filed the day it arrives in all but a handful of instances,
    // so making every user pick today by hand taxes the common path.
    await openWizard(tester);

    expect(find.text(isoToday()), findsOneWidget);
    expect(find.text('اختر تاريخ استلام الحالة'), findsNothing);
  });

  testWidgets('the due date is still left blank', (tester) async {
    // Only the intake date is knowable without asking; promising a delivery
    // date on the user's behalf would be inventing a commitment.
    await openWizard(tester);

    expect(find.text('اختر تاريخ التسليم (اختياري)'), findsOneWidget);
  });

  testWidgets('received is asked before due', (tester) async {
    // The case is taken in first and promised second, and the delivery date is
    // judged against the intake date.
    await openWizard(tester);

    final received = tester.getTopLeft(find.text('تاريخ الاستلام')).dy;
    final due = tester.getTopLeft(find.text('تاريخ التسليم')).dy;

    expect(received, lessThan(due));
  });
}
