import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_filters_sheet.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

class _MockClinicsRepo extends Mock implements ClinicsRepo {}

class _MockPatientsRepo extends Mock implements PatientsRepo {}

const _normal = CasePriorityModel(id: 'p1', nameAr: 'عادية');
const _urgent = CasePriorityModel(id: 'p2', nameAr: 'مستعجلة');

/// A row the lab has since deactivated. It must not be offered as a filter,
/// because the case form cannot file anything under it either.
const _retired = CasePriorityModel(id: 'p3', nameAr: 'قديمة', isActive: false);

/// The sheet plus the cubits `openCaseFiltersSheet` provides for it. Not an
/// app on its own — the caller decides whether it sits on a page or inside a
/// modal sheet.
Widget _sheet(
  CasePrioritiesRepo prioritiesRepo, {
  CaseFiltersModel initial = CaseFiltersModel.empty,
}) {
  final doctorsRepo = _MockDoctorsRepo();
  when(() => doctorsRepo.getDoctors()).thenAnswer(
    (_) async => Right<Failure, List<DoctorModel>>([
      DoctorModel(id: 'd1', firstName: 'أحمد', lastName: 'الخطيب'),
    ]),
  );

  final clinicsRepo = _MockClinicsRepo();
  when(() => clinicsRepo.getClinics()).thenAnswer(
    (_) async => Right<Failure, List<ClinicModel>>([
      ClinicModel(id: 'c1', name: 'عيادة النور'),
    ]),
  );

  final patientsRepo = _MockPatientsRepo();
  when(() => patientsRepo.getPatients()).thenAnswer(
    (_) async => Right<Failure, List<PatientModel>>([
      PatientModel(id: 'pt1', firstName: 'خالد', lastName: 'المصري'),
      PatientModel(id: 'pt2', firstName: 'ليلى', lastName: 'حدّاد'),
    ]),
  );

  return MultiBlocProvider(
    providers: [
      // Mirrors what openCaseFiltersSheet provides.
      BlocProvider(
        create: (_) => CasePrioritiesCubit(prioritiesRepo)..getCasePriorities(),
      ),
      BlocProvider(create: (_) => DoctorsCubit(doctorsRepo)..getDoctors()),
      BlocProvider(create: (_) => ClinicsCubit(clinicsRepo)..getClinics()),
      BlocProvider(create: (_) => PatientsCubit(patientsRepo)..getPatients()),
    ],
    child: CaseFiltersSheet(initial: initial),
  );
}

Widget _app({required Widget home}) => MaterialApp(
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

void main() {
  late _MockCasePrioritiesRepo prioritiesRepo;

  setUp(() {
    prioritiesRepo = _MockCasePrioritiesRepo();
    when(
      () => prioritiesRepo.getCasePriorities(includeInactive: true),
    ).thenAnswer(
      (_) async => Right<Failure, List<CasePriorityModel>>(const [
        _normal,
        _urgent,
        _retired,
      ]),
    );
    when(
      () => prioritiesRepo.getCasePriorities(includeInactive: false),
    ).thenAnswer(
      (_) async =>
          Right<Failure, List<CasePriorityModel>>(const [_normal, _urgent]),
    );
  });

  testWidgets('offers the lab\'s configured priorities, not a fixed set', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(home: Scaffold(body: _sheet(prioritiesRepo))));
    await tester.pumpAndSettle();

    expect(find.text('عادية'), findsOneWidget);
    expect(find.text('مستعجلة'), findsOneWidget);
    // Deactivated rows are not offerable — the form cannot use them either.
    expect(find.text('قديمة'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('applying a priority pops with its id and label', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    CaseFiltersModel? applied;
    await tester.pumpWidget(
      _app(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  // Opened the way the page opens it, so the pop value is the
                  // one CasesCubit would receive.
                  applied = await showModalBottomSheet<CaseFiltersModel>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _sheet(prioritiesRepo),
                  );
                },
                child: const Text('فتح'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('عادية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق الفلاتر'));
    await tester.pumpAndSettle();

    expect(applied?.priorityId, 'p1');
    expect(applied?.priorityName, 'عادية');
    expect(applied?.activeCount, 1);
  });

  testWidgets('picking a patient pops with that patient\'s id', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    CaseFiltersModel? applied;
    await tester.pumpWidget(
      _app(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  applied = await showModalBottomSheet<CaseFiltersModel>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _sheet(prioritiesRepo),
                  );
                },
                child: const Text('فتح'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();

    // The lookup only lists its options once focused.
    final patientField = find.widgetWithText(TextField, 'كل المرضى');
    await tester.ensureVisible(patientField);
    await tester.pumpAndSettle();
    await tester.tap(patientField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ليلى حدّاد').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('تطبيق الفلاتر'));
    await tester.pumpAndSettle();

    expect(applied?.patientId, 'pt2');
    expect(applied?.patientName, 'ليلى حدّاد');
    expect(applied?.activeCount, 1);
  });

  testWidgets('clearing resets the patient along with everything else', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    CaseFiltersModel? applied;
    await tester.pumpWidget(
      _app(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  applied = await showModalBottomSheet<CaseFiltersModel>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _sheet(
                      prioritiesRepo,
                      // Reopened with a patient already filtered on.
                      initial: const CaseFiltersModel(
                        patientId: 'pt1',
                        patientName: 'خالد المصري',
                      ),
                    ),
                  );
                },
                child: const Text('فتح'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('مسح الكل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق الفلاتر'));
    await tester.pumpAndSettle();

    expect(applied?.patientId, isNull);
    expect(applied?.isEmpty, isTrue);
  });
}
