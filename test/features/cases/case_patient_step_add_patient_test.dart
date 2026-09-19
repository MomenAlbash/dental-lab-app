import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_patient_step.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_state.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class _StubDoctorsCubit extends Cubit<DoctorsState> implements DoctorsCubit {
  _StubDoctorsCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPatientsCubit extends Cubit<PatientsState> implements PatientsCubit {
  _StubPatientsCubit(super.initialState);

  int reloads = 0;

  @override
  Future<void> getPatients({String? search}) async => reloads++;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPrioritiesCubit extends Cubit<CasePrioritiesState>
    implements CasePrioritiesCubit {
  _StubPrioritiesCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the real form cubit so the sheet can be driven without an
/// API — and records what the sheet asked it to create.
class _StubPatientFormCubit extends Cubit<PatientFormState>
    implements PatientFormCubit {
  _StubPatientFormCubit() : super(const PatientFormInitial());

  CreatePatientRequestModel? lastRequest;

  @override
  Future<void> createPatient(CreatePatientRequestModel request) async {
    lastRequest = request;
    emit(const PatientFormSubmitting());
    emit(
      PatientFormSuccess(
        PatientModel(
          id: 'p-new',
          firstName: request.firstName,
          lastName: request.lastName,
          doctorId: request.doctorId,
          clinicId: request.clinicId,
        ),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _StubPatientsCubit patientsCubit;
  late _StubPatientFormCubit formCubit;
  late String? selectedPatientId;
  late PatientModel? selectedPatient;

  setUp(() {
    selectedPatientId = null;
    selectedPatient = null;
    formCubit = _StubPatientFormCubit();
    getIt.registerFactory<PatientFormCubit>(() => formCubit);
  });

  tearDown(() => getIt.unregister<PatientFormCubit>());

  Widget wrap({String? doctorId}) {
    patientsCubit = _StubPatientsCubit(const PatientsLoaded([]));

    return MultiBlocProvider(
      providers: [
        BlocProvider<DoctorsCubit>.value(
          value: _StubDoctorsCubit(
            DoctorsLoaded([
              DoctorModel(id: 'd-1', firstName: 'أحمد', clinicId: 'c-9'),
            ]),
          ),
        ),
        BlocProvider<PatientsCubit>.value(value: patientsCubit),
        BlocProvider<CasePrioritiesCubit>.value(
          value: _StubPrioritiesCubit(const CasePrioritiesInitial()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CasePatientStep(
              patientId: null,
              onPatientChanged: (id, patient) {
                selectedPatientId = id;
                selectedPatient = patient;
              },
              referenceController: TextEditingController(),
              notesController: TextEditingController(),
              doctorId: doctorId,
              onDoctorChanged: (_, _) {},
              priority: null,
              onPriorityChanged: (_) {},
              dueDate: null,
              onPickDueDate: () {},
              receivedAt: null,
              onPickReceivedAt: () {},
              isRepeatCase: false,
              onCaseKindChanged: (_) {},
              previousCaseLabel: null,
              onPickPreviousCase: () {},
            ),
          ),
        ),
      ),
    );
  }

  /// The patient button is the second add-person button on the step; the first
  /// belongs to the doctor field above it.
  Finder patientAddButton() =>
      find.byIcon(Icons.person_add_alt_1_outlined).at(1);

  testWidgets('the quick-add sheet is out of reach until a doctor is picked', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(patientAddButton());
    await tester.pumpAndSettle();

    // A patient must be filed under a doctor, so there is nothing to submit.
    expect(find.text('مريض جديد'), findsNothing);
  });

  testWidgets('a patient added by name is filed under the selected doctor', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(doctorId: 'd-1'));
    await tester.pumpAndSettle();

    await tester.tap(patientAddButton());
    await tester.pumpAndSettle();

    expect(find.text('مريض جديد'), findsOneWidget);

    // Targeted through its hint, not by index: the case form has text fields
    // of its own behind the sheet.
    await tester.enterText(
      find.ancestor(
        of: find.text('الاسم الأول'),
        matching: find.byType(TextFormField),
      ),
      'ليلى',
    );
    await tester.tap(find.text('إضافة المريض'));
    await tester.pumpAndSettle();

    // The name is all the user typed; the doctor and clinic come from the
    // fields already answered above it.
    expect(formCubit.lastRequest?.firstName, 'ليلى');
    expect(formCubit.lastRequest?.lastName, isNull);
    expect(formCubit.lastRequest?.doctorId, 'd-1');
    expect(formCubit.lastRequest?.clinicId, 'c-9');

    // And it lands in the field without the user going to find it.
    expect(selectedPatientId, 'p-new');
    expect(selectedPatient?.fullName, 'ليلى');
    expect(patientsCubit.reloads, 1);
  });

  testWidgets('an empty name is refused', (tester) async {
    await tester.pumpWidget(wrap(doctorId: 'd-1'));
    await tester.pumpAndSettle();

    await tester.tap(patientAddButton());
    await tester.pumpAndSettle();

    await tester.tap(find.text('إضافة المريض'));
    await tester.pumpAndSettle();

    expect(find.text('الاسم الأول مطلوب'), findsOneWidget);
    expect(formCubit.lastRequest, isNull);
    expect(selectedPatientId, isNull);
  });
}
