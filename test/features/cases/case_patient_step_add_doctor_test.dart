import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_patient_step.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records the reload the step asks for after a doctor is added; the list
/// itself stays as handed in, which is enough for the assignment under test.
class _StubDoctorsCubit extends Cubit<DoctorsState> implements DoctorsCubit {
  _StubDoctorsCubit(super.initialState);

  int reloads = 0;

  @override
  Future<void> getDoctors() async => reloads++;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPatientsCubit extends Cubit<PatientsState> implements PatientsCubit {
  _StubPatientsCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPrioritiesCubit extends Cubit<CasePrioritiesState>
    implements CasePrioritiesCubit {
  _StubPrioritiesCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _StubDoctorsCubit doctorsCubit;
  late String? selectedDoctorId;
  late String? selectedClinicId;
  late DoctorModel? doctorToReturn;

  setUp(() {
    selectedDoctorId = null;
    selectedClinicId = null;
    doctorToReturn = DoctorModel(
      id: 'd-new',
      firstName: 'سامر',
      lastName: 'حداد',
      clinicId: 'c-9',
    );
  });

  Widget wrap({required List<DoctorModel> doctors}) {
    doctorsCubit = _StubDoctorsCubit(DoctorsLoaded(doctors));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CasePatientStep(
                patientId: null,
                onPatientChanged: (_, _) {},
                referenceController: TextEditingController(),
                notesController: TextEditingController(),
                doctorId: selectedDoctorId,
                onDoctorChanged: (doctorId, clinicId) {
                  selectedDoctorId = doctorId;
                  selectedClinicId = clinicId;
                },
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
        // Stands in for the doctor form: it pops the created doctor, which is
        // exactly the contract the step depends on.
        GoRoute(
          path: '/doctors/form',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(doctorToReturn),
                child: const Text('احفظ'),
              ),
            ),
          ),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<DoctorsCubit>.value(value: doctorsCubit),
        BlocProvider<PatientsCubit>.value(
          value: _StubPatientsCubit(const PatientsInitial()),
        ),
        BlocProvider<CasePrioritiesCubit>.value(
          value: _StubPrioritiesCubit(const CasePrioritiesInitial()),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets('an add-doctor button sits beside the doctor field', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        doctors: [DoctorModel(id: 'd-1', firstName: 'أحمد')],
      ),
    );
    await tester.pumpAndSettle();

    // Two add buttons on the step — the doctor field's is the first, the
    // patient field's follows it.
    expect(find.byIcon(Icons.person_add_alt_1_outlined), findsNWidgets(2));
  });

  testWidgets('a doctor added from the field is assigned to it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        doctors: [DoctorModel(id: 'd-1', firstName: 'أحمد')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('احفظ'));
    await tester.pumpAndSettle();

    // The whole point: the user does not have to go find the doctor they just
    // created — the field already holds it, clinic included.
    expect(selectedDoctorId, 'd-new');
    expect(selectedClinicId, 'c-9');
    expect(doctorsCubit.reloads, 1);
  });

  testWidgets('leaving the doctor form without saving changes nothing', (
    tester,
  ) async {
    doctorToReturn = null;
    await tester.pumpWidget(
      wrap(
        doctors: [DoctorModel(id: 'd-1', firstName: 'أحمد')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('احفظ'));
    await tester.pumpAndSettle();

    expect(selectedDoctorId, isNull);
    expect(doctorsCubit.reloads, 0);
  });
}
