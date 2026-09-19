import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_excluded_representatives/doctor_excluded_representatives_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_excluded_representatives/doctor_excluded_representatives_state.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dental_lab_app/features/zones/data/repos/zones_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDoctorsRepo extends Mock implements DoctorsRepo {}

class MockZonesRepo extends Mock implements ZonesRepo {}

const _rep1 = ZoneRepresentativeModel(id: 'r1', userId: 'u1', name: 'سارة');
const _rep2 = ZoneRepresentativeModel(id: 'r2', userId: 'u2', name: 'عمر');

ZoneModel _zone({List<ZoneRepresentativeModel> reps = const [_rep1, _rep2]}) =>
    ZoneModel(id: 'z1', laboratoryId: 'lab1', representatives: reps);

void main() {
  group('DoctorModel zone fields', () {
    test('reads the zone the doctor resolves to', () {
      final doctor = DoctorModel.fromJson(const {
        'id': 'd1',
        'zoneId': 'z1',
        'zoneNameAr': 'المزة',
        'zoneName': 'Mazzeh',
      });

      expect(doctor.zoneId, 'z1');
      expect(doctor.zoneDisplayName, 'المزة');
    });

    test('a doctor with no zone yet reads as null, not an error', () {
      final doctor = DoctorModel.fromJson(const {'id': 'd1'});

      expect(doctor.zoneId, isNull);
      expect(doctor.zoneDisplayName, isNull);
    });
  });

  late MockDoctorsRepo doctorsRepo;
  late MockZonesRepo zonesRepo;
  late DoctorExcludedRepresentativesCubit cubit;

  setUp(() {
    doctorsRepo = MockDoctorsRepo();
    zonesRepo = MockZonesRepo();
    cubit = DoctorExcludedRepresentativesCubit(doctorsRepo, zonesRepo);
  });

  tearDown(() => cubit.close());

  test('candidates are the zone reps minus who is already excluded', () async {
    when(
      () => doctorsRepo.getExcludedRepresentatives('d1'),
    ).thenAnswer((_) async => right(const [_rep1]));
    when(
      () => zonesRepo.getZoneById('z1'),
    ).thenAnswer((_) async => right(_zone()));

    await cubit.load(doctorId: 'd1', zoneId: 'z1');

    final loaded = cubit.state as DoctorExcludedRepresentativesLoaded;
    expect(loaded.excluded, [_rep1]);
    expect(loaded.candidates, [_rep2]);
  });

  test('a doctor with no zone has no candidates, not an error', () async {
    when(
      () => doctorsRepo.getExcludedRepresentatives('d1'),
    ).thenAnswer((_) async => right(const []));

    await cubit.load(doctorId: 'd1');

    final loaded = cubit.state as DoctorExcludedRepresentativesLoaded;
    expect(loaded.zoneRepresentatives, isEmpty);
    expect(loaded.candidates, isEmpty);
    verifyNever(() => zonesRepo.getZoneById(any()));
  });

  test('excluding a representative reloads the list', () async {
    when(
      () => doctorsRepo.getExcludedRepresentatives('d1'),
    ).thenAnswer((_) async => right(const []));
    when(
      () => zonesRepo.getZoneById('z1'),
    ).thenAnswer((_) async => right(_zone()));
    when(
      () => doctorsRepo.excludeRepresentative(
        doctorId: 'd1',
        userId: 'u1',
        reason: 'يصل متأخراً دائماً',
      ),
    ).thenAnswer((_) async => right(null));

    await cubit.load(doctorId: 'd1', zoneId: 'z1');

    // The reload after a successful exclude picks the fresh list back up —
    // stub it to now include the excluded representative.
    when(
      () => doctorsRepo.getExcludedRepresentatives('d1'),
    ).thenAnswer((_) async => right(const [_rep1]));

    await cubit.exclude(userId: 'u1', reason: 'يصل متأخراً دائماً');

    final loaded = cubit.state as DoctorExcludedRepresentativesLoaded;
    expect(loaded.excluded, [_rep1]);
    verify(
      () => doctorsRepo.excludeRepresentative(
        doctorId: 'd1',
        userId: 'u1',
        reason: 'يصل متأخراً دائماً',
      ),
    ).called(1);
  });

  test('removing an exclusion drops it from the list optimistically', () async {
    when(
      () => doctorsRepo.getExcludedRepresentatives('d1'),
    ).thenAnswer((_) async => right(const [_rep1, _rep2]));
    when(
      () => zonesRepo.getZoneById('z1'),
    ).thenAnswer((_) async => right(_zone()));
    when(
      () => doctorsRepo.removeExcludedRepresentative(
        doctorId: 'd1',
        userId: 'u1',
      ),
    ).thenAnswer((_) async => right(null));

    await cubit.load(doctorId: 'd1', zoneId: 'z1');
    await cubit.unexclude('u1');

    final loaded = cubit.state as DoctorExcludedRepresentativesLoaded;
    expect(loaded.excluded, [_rep2]);
  });

  test('a failed removal puts the row back and reports why', () async {
    when(
      () => doctorsRepo.getExcludedRepresentatives('d1'),
    ).thenAnswer((_) async => right(const [_rep1]));
    when(
      () => zonesRepo.getZoneById('z1'),
    ).thenAnswer((_) async => right(_zone()));
    when(
      () => doctorsRepo.removeExcludedRepresentative(
        doctorId: 'd1',
        userId: 'u1',
      ),
    ).thenAnswer((_) async => left(ServerFailure('مرفوض')));

    await cubit.load(doctorId: 'd1', zoneId: 'z1');

    final states = <DoctorExcludedRepresentativesState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.unexclude('u1');
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(
      states.whereType<DoctorExcludedRepresentativesMessage>().single.message,
      'مرفوض',
    );
    final last = states.last as DoctorExcludedRepresentativesLoaded;
    expect(last.excluded, [_rep1]);
  });
}
