import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_patient_step.dart';
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

class _MockPatientsRepo extends Mock implements PatientsRepo {}

CasePriorityModel _priority(String id, String nameAr) =>
    CasePriorityModel(id: id, nameAr: nameAr);

Widget _wrap({
  required List<CasePriorityModel> priorities,
  CasePriorityModel? selected,
  ValueChanged<CasePriorityModel?>? onChanged,
}) {
  final prioritiesRepo = _MockCasePrioritiesRepo();
  when(
    () => prioritiesRepo.getCasePriorities(
      includeInactive: any(named: 'includeInactive'),
    ),
  ).thenAnswer(
    (_) async => Right<Failure, List<CasePriorityModel>>(priorities),
  );

  final doctorsRepo = _MockDoctorsRepo();
  when(() => doctorsRepo.getDoctors()).thenAnswer(
    (_) async => Right<Failure, List<DoctorModel>>([
      DoctorModel(id: 'd1', firstName: 'أحمد', lastName: 'الخطيب'),
    ]),
  );

  final patientsRepo = _MockPatientsRepo();
  when(
    () => patientsRepo.getPatients(),
  ).thenAnswer((_) async => Right<Failure, List<PatientModel>>(const []));

  return MaterialApp(
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
              CasePrioritiesCubit(prioritiesRepo)..getCasePriorities(),
        ),
        BlocProvider(create: (_) => DoctorsCubit(doctorsRepo)..getDoctors()),
        BlocProvider(create: (_) => PatientsCubit(patientsRepo)..getPatients()),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: CasePatientStep(
            patientId: null,
            onPatientChanged: (_, _) {},
            referenceController: TextEditingController(),
            notesController: TextEditingController(),
            doctorId: null,
            onDoctorChanged: (_, _) {},
            priority: selected,
            onPriorityChanged: onChanged ?? (_) {},
            dueDate: null,
            onPickDueDate: () {},
            receivedAt: null,
            onPickReceivedAt: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Small-phone breakpoint per CLAUDE.md Section C.6.
  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('a short list reads as a segmented row at 360dp', (tester) async {
    useSmallPhone(tester);

    await tester.pumpWidget(
      _wrap(
        priorities: [
          _priority('p1', 'منخفضة'),
          _priority('p2', 'عادية'),
          _priority('p3', 'عالية'),
          _priority('p4', 'عاجلة'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    expect(find.text('عاجلة'), findsOneWidget);
    // A RenderFlex overflow surfaces here.
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a segment reports the whole priority', (tester) async {
    useSmallPhone(tester);

    CasePriorityModel? picked;
    await tester.pumpWidget(
      _wrap(
        priorities: [_priority('p1', 'عادية'), _priority('p2', 'عاجلة')],
        selected: _priority('p1', 'عادية'),
        onChanged: (value) => picked = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('عاجلة'));
    await tester.pumpAndSettle();

    expect(picked?.id, 'p2');
  });

  testWidgets('more than four priorities fall back to wrapping chips', (
    tester,
  ) async {
    useSmallPhone(tester);

    await tester.pumpWidget(
      _wrap(
        priorities: [
          for (var i = 1; i <= 5; i++) _priority('p$i', 'أولوية رقم $i'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Five evenly-divided segments would be unreadable at this width.
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty list points at the priorities screen', (tester) async {
    useSmallPhone(tester);

    await tester.pumpWidget(_wrap(priorities: const []));
    await tester.pumpAndSettle();

    expect(find.text('إدارة الأولويات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
