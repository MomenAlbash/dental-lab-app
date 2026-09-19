import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_state.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_doctors_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDoctorsRepo extends Mock implements DoctorsRepo {}

class MockPriceTiersRepo extends Mock implements PriceTiersRepo {}

DoctorModel doctor({String? tierId, String? tierName}) => DoctorModel(
  id: 'd1',
  firstName: 'أحمد',
  lastName: 'الخطيب',
  phoneNumber: '0991234567',
  email: 'a@b.com',
  gender: DoctorGender.male,
  cityId: 'c1',
  city: CityModel(id: 'c1', name: 'دمشق'),
  clinicId: 'cl1',
  clinic: ClinicModel(id: 'cl1', name: 'عيادة النور'),
  priceTierId: tierId,
  priceTierName: tierName,
);

void main() {
  group('DoctorModel', () {
    test('parses the tier it is billed at and when it started', () {
      final parsed = DoctorModel.fromJson(const {
        'id': 'd1',
        'priceTierId': 't1',
        'priceTierName': 'الذهبية',
        'priceTierSince': '2026-03-01T00:00:00',
      });

      expect(parsed.priceTierId, 't1');
      expect(parsed.priceTierName, 'الذهبية');
      expect(parsed.priceTierSince, '2026-03-01T00:00:00');
    });
  });

  group('UpdateDoctorRequestModel', () {
    test('sends every key, nulls included', () {
      // The endpoint replaces rather than patches, so an omitted key is not
      // "leave alone" — this is why callers must resend the whole doctor.
      final json = UpdateDoctorRequestModel(priceTierId: 't1').toJson();

      expect(json['priceTierId'], 't1');
      expect(json.containsKey('firstName'), isTrue);
      expect(json['firstName'], isNull);
    });

    test('refuses a pricing note past the API cap', () {
      expect(
        () => UpdateDoctorRequestModel(pricingNote: 'x' * 501),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('DoctorDetailsCubit.setPriceTier', () {
    late MockDoctorsRepo repo;
    late MockPriceTiersRepo tiersRepo;
    late DoctorDetailsCubit cubit;

    setUpAll(() {
      registerFallbackValue(UpdateDoctorRequestModel());
      registerFallbackValue(
        const SetPriceTierDoctorsRequestModel(doctorIds: []),
      );
    });

    setUp(() {
      repo = MockDoctorsRepo();
      tiersRepo = MockPriceTiersRepo();
      cubit = DoctorDetailsCubit(repo, tiersRepo);
    });

    tearDown(() => cubit.close());

    Future<void> load({String? tierId}) async {
      when(
        () => repo.getDoctorById(any()),
      ).thenAnswer((_) async => right(doctor(tierId: tierId)));
      await cubit.getDoctor('d1');
    }

    test('resends the rest of the doctor so nothing is blanked', () async {
      // The bug this guards: sending only the tier would null out the name,
      // phone and clinic, because PUT /Doctors/{id} replaces the record.
      await load();
      when(
        () => repo.updateDoctor(
          id: any(named: 'id'),
          updateDoctorRequestBody: any(named: 'updateDoctorRequestBody'),
        ),
      ).thenAnswer((_) async => right(doctor(tierId: 't1')));

      await cubit.setPriceTier('t1');

      final body =
          verify(
                () => repo.updateDoctor(
                  id: 'd1',
                  updateDoctorRequestBody: captureAny(
                    named: 'updateDoctorRequestBody',
                  ),
                ),
              ).captured.first
              as UpdateDoctorRequestModel;

      expect(body.priceTierId, 't1');
      expect(body.firstName, 'أحمد');
      expect(body.phoneNumber, '0991234567');
      expect(body.clinicId, 'cl1');
      expect(body.cityId, 'c1');
      expect(body.gender, DoctorGender.male.apiValue);
    });

    test('removing goes through the tier, not a null on the doctor', () async {
      // `UpdateDoctorRequest` has no clear flag, and a null `priceTierId`
      // there reads as "leave it alone" — which is why "بلا شريحة" appeared to
      // do nothing. The tier's roster endpoint replaces, so it can drop a
      // doctor for real.
      await load(tierId: 't1');
      when(() => tiersRepo.getPriceTierById(any())).thenAnswer(
        (_) async => right(
          PriceTierModel.fromJson(const {
            'id': 't1',
            'doctors': [
              {'id': 'd1'},
              {'id': 'other'},
            ],
          }),
        ),
      );
      when(
        () => tiersRepo.setPriceTierDoctors(
          id: any(named: 'id'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => right(PriceTierModel.fromJson(const {'id': 't1'})),
      );

      await cubit.setPriceTier(null);

      final body =
          verify(
                () => tiersRepo.setPriceTierDoctors(
                  id: 't1',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as SetPriceTierDoctorsRequestModel;

      // Everyone else on the tier stays; only this doctor is dropped.
      expect(body.doctorIds, ['other']);
      verifyNever(
        () => repo.updateDoctor(
          id: any(named: 'id'),
          updateDoctorRequestBody: any(named: 'updateDoctorRequestBody'),
        ),
      );
    });

    test('removing a doctor who is on no tier does nothing', () async {
      await load();

      await cubit.setPriceTier(null);

      verifyNever(() => tiersRepo.getPriceTierById(any()));
    });

    test('a failed write reports the reason and keeps the doctor', () async {
      await load();
      when(
        () => repo.updateDoctor(
          id: any(named: 'id'),
          updateDoctorRequestBody: any(named: 'updateDoctorRequestBody'),
        ),
      ).thenAnswer((_) async => left(ServerFailure('مرفوض')));

      final states = <DoctorDetailsState>[];
      final subscription = cubit.stream.listen(states.add);
      await cubit.setPriceTier('t1');
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(
        states.whereType<DoctorDetailsActionError>().single.message,
        'مرفوض',
      );
      expect(states.last, isA<DoctorDetailsLoaded>());
    });
  });
}
