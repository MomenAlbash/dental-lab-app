import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPatientsRepo extends Mock implements PatientsRepo {}

void main() {
  late _MockPatientsRepo repo;
  late PatientsCubit cubit;

  setUpAll(() {
    registerFallbackValue(PatientFiltersModel.empty);
  });

  setUp(() {
    repo = _MockPatientsRepo();
    cubit = PatientsCubit(repo);

    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => right(<PatientModel>[]));
  });

  tearDown(() => cubit.close());

  test('announces the delete, then reloads the list from the server', () async {
    when(() => repo.deletePatient('p1')).thenAnswer((_) async => right(null));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<PatientDeleted>(),
        isA<PatientsLoading>(),
        isA<PatientsLoaded>(),
      ]),
    );

    await cubit.deletePatient('p1');
    await expectation;

    verify(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).called(1);
  });

  test('reports a failed delete without reloading the list', () async {
    when(
      () => repo.deletePatient('p1'),
    ).thenAnswer((_) async => left(ServerFailure('للمريض حالات مسجّلة')));

    await cubit.deletePatient('p1');

    expect(cubit.state, isA<PatientDeleteError>());
    expect((cubit.state as PatientDeleteError).message, 'للمريض حالات مسجّلة');
    verifyNever(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    );
  });
}
