import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_doctors_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_doctors/price_tier_doctors_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_doctors/price_tier_doctors_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPriceTiersRepo extends Mock implements PriceTiersRepo {}

PriceTierModel tier({List<Map<String, dynamic>> doctors = const []}) =>
    PriceTierModel.fromJson({
      'id': 't1',
      'name': 'الشريحة الذهبية',
      'doctors': doctors,
      'doctorCount': doctors.length,
    });

void main() {
  group('PriceTierModel', () {
    test('parses the doctors it prices', () {
      final model = tier(
        doctors: const [
          {
            'id': 'd1',
            'number': 12,
            'fullName': 'أحمد الخطيب',
            'clinicName': 'عيادة النور',
          },
        ],
      );

      expect(model.doctorCount, 1);
      expect(model.doctors.single.number, 12);
      expect(model.doctors.single.displayName, 'أحمد الخطيب');
      expect(model.doctors.single.clinicName, 'عيادة النور');
      expect(model.hasNoDoctors, isFalse);
    });

    test('a tier assigned to nobody says so', () {
      // It bills no one, and looks identical to a working tier until asked.
      expect(tier().hasNoDoctors, isTrue);
    });
  });

  group('SetPriceTierDoctorsRequestModel', () {
    test('sends an empty list so everyone can be unassigned', () {
      // The endpoint replaces the assignment wholesale, so an empty list is
      // the only way to remove the last doctor.
      final json = const SetPriceTierDoctorsRequestModel(
        doctorIds: [],
      ).toJson();

      expect(json['doctorIds'], isEmpty);
    });
  });

  group('PriceTierDoctorsCubit', () {
    late MockPriceTiersRepo repo;
    late PriceTierDoctorsCubit cubit;

    setUpAll(() {
      registerFallbackValue(
        const SetPriceTierDoctorsRequestModel(doctorIds: []),
      );
    });

    setUp(() {
      repo = MockPriceTiersRepo();
      cubit = PriceTierDoctorsCubit(repo);
    });

    tearDown(() => cubit.close());

    test('sorts by the lab\'s doctor number, nulls last', () async {
      when(() => repo.getPriceTierById(any())).thenAnswer(
        (_) async => right(
          tier(
            doctors: const [
              {'id': 'c', 'fullName': 'بلا رقم'},
              {'id': 'b', 'number': 9, 'fullName': 'تسعة'},
              {'id': 'a', 'number': 2, 'fullName': 'اثنان'},
            ],
          ),
        ),
      );

      await cubit.load('t1');

      final doctors = (cubit.state as PriceTierDoctorsLoaded).doctors;
      expect(doctors.map((d) => d.id), ['a', 'b', 'c']);
    });

    test('a save replaces the list with what the server returns', () async {
      when(
        () => repo.getPriceTierById(any()),
      ).thenAnswer((_) async => right(tier()));
      when(
        () => repo.setPriceTierDoctors(
          id: any(named: 'id'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => right(
          tier(
            doctors: const [
              {'id': 'd1', 'number': 1, 'fullName': 'أحمد'},
            ],
          ),
        ),
      );

      await cubit.load('t1');
      await cubit.setDoctors(['d1']);

      final body =
          verify(
                () => repo.setPriceTierDoctors(
                  id: 't1',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as SetPriceTierDoctorsRequestModel;

      expect(body.doctorIds, ['d1']);
      expect((cubit.state as PriceTierDoctorsLoaded).doctors, hasLength(1));
    });

    test('a failed save reports the reason and keeps the list', () async {
      when(() => repo.getPriceTierById(any())).thenAnswer(
        (_) async => right(
          tier(
            doctors: const [
              {'id': 'd1', 'fullName': 'أحمد'},
            ],
          ),
        ),
      );
      when(
        () => repo.setPriceTierDoctors(
          id: any(named: 'id'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => left(ServerFailure('الطبيب مرتبط بشريحة أخرى')),
      );

      await cubit.load('t1');

      final states = <PriceTierDoctorsState>[];
      final subscription = cubit.stream.listen(states.add);
      await cubit.setDoctors(['d1', 'd2']);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(
        states.whereType<PriceTierDoctorsMessage>().single.message,
        'الطبيب مرتبط بشريحة أخرى',
      );
      // A failed write must not replace a working screen with an error.
      expect(states.last, isA<PriceTierDoctorsLoaded>());
      expect((states.last as PriceTierDoctorsLoaded).doctors, hasLength(1));
    });
  });
}
