import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPatientsRepo extends Mock implements PatientsRepo {}

class _FakeRequest extends Fake implements CreatePatientRequestModel {}

CreatePatientRequestModel _body() =>
    CreatePatientRequestModel(doctorId: 'd1', firstName: 'خالد');

void main() {
  late _MockPatientsRepo repo;
  late PatientFormCubit cubit;

  setUpAll(() => registerFallbackValue(_FakeRequest()));

  setUp(() {
    repo = _MockPatientsRepo();
    cubit = PatientFormCubit(repo);
  });

  tearDown(() => cubit.close());

  test('emits submitting then success with the saved patient', () async {
    final saved = PatientModel(id: 'p1', firstName: 'خالد');
    when(
      () => repo.updatePatient(
        id: any(named: 'id'),
        patientRequestBody: any(named: 'patientRequestBody'),
      ),
    ).thenAnswer((_) async => right(saved));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([isA<PatientFormSubmitting>(), isA<PatientFormSuccess>()]),
    );

    await cubit.updatePatient(id: 'p1', patientRequestBody: _body());
    await expectation;

    expect((cubit.state as PatientFormSuccess).patient, saved);
  });

  test('sends the edit to the id it was given', () async {
    when(
      () => repo.updatePatient(
        id: any(named: 'id'),
        patientRequestBody: any(named: 'patientRequestBody'),
      ),
    ).thenAnswer((_) async => right(PatientModel(id: 'p1')));

    final body = _body();
    await cubit.updatePatient(id: 'p1', patientRequestBody: body);

    verify(
      () => repo.updatePatient(id: 'p1', patientRequestBody: body),
    ).called(1);
  });

  test('surfaces the failure message when the edit is refused', () async {
    when(
      () => repo.updatePatient(
        id: any(named: 'id'),
        patientRequestBody: any(named: 'patientRequestBody'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('الطبيب غير موجود')));

    await cubit.updatePatient(id: 'p1', patientRequestBody: _body());

    expect(cubit.state, isA<PatientFormError>());
    expect((cubit.state as PatientFormError).message, 'الطبيب غير موجود');
  });
}
