import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_cubit.dart';
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

import '../../helpers/back_navigation.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

class _MockPatientsRepo extends Mock implements PatientsRepo {}

class _MockRestorationTypesRepo extends Mock implements RestorationTypesRepo {}

class _MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

void main() {
  const dialogTitle = 'تجاهل التعديلات؟';

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
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CaseFormPage())),
            child: const Text('فتح'),
          ),
        ),
      ),
    ),
  );

  Future<void> openWizard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة حالة'), findsOneWidget);
  }

  testWidgets('an untouched wizard leaves without asking', (tester) async {
    await openWizard(tester);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('typing a reference number makes leaving ask first', (
    tester,
  ) async {
    await openWizard(tester);

    final reference = find.ancestor(
      of: find.text('أدخل الرقم المرجعي (اختياري)'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(reference);
    await tester.pumpAndSettle();
    await tester.enterText(reference, 'REF-7');
    await tester.pumpAndSettle();

    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
    expect(find.text('إضافة حالة'), findsOneWidget);
  });

  testWidgets('discarding exits the whole wizard', (tester) async {
    await openWizard(tester);

    final reference = find.ancestor(
      of: find.text('أدخل الرقم المرجعي (اختياري)'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(reference);
    await tester.pumpAndSettle();
    await tester.enterText(reference, 'REF-7');
    await tester.pumpAndSettle();

    await systemBack(tester);
    await tester.tap(find.text('خروج بدون حفظ'));
    await tester.pumpAndSettle();

    // The whole route is gone — back does not walk back through the steps.
    expect(find.text('إضافة حالة'), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('keeping the edits stays on the wizard', (tester) async {
    await openWizard(tester);

    final reference = find.ancestor(
      of: find.text('أدخل الرقم المرجعي (اختياري)'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(reference);
    await tester.pumpAndSettle();
    await tester.enterText(reference, 'REF-7');
    await tester.pumpAndSettle();

    await systemBack(tester);
    await tester.tap(find.text('متابعة التعديل'));
    await tester.pumpAndSettle();

    expect(find.text('إضافة حالة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
