import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/areas/data/repos/areas_repo.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:dental_lab_app/features/zones/data/models/save_zone_request_models.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dental_lab_app/features/zones/data/repos/zones_repo.dart';
import 'package:dental_lab_app/features/zones/logic/zone_form/zone_form_cubit.dart';
import 'package:dental_lab_app/features/zones/logic/zone_form/zone_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockZonesRepo extends Mock implements ZonesRepo {}

class _MockAreasRepo extends Mock implements AreasRepo {}

class _MockUsersRepo extends Mock implements UsersRepo {}

class _MockAccountingRepo extends Mock implements AccountingRepo {}

void main() {
  group('ShippingDuration', () {
    test('splits a minute count into days, hours and minutes', () {
      final duration = ShippingDuration.fromMinutes(2 * 1440 + 3 * 60 + 15);

      expect(duration.days, 2);
      expect(duration.hours, 3);
      expect(duration.minutes, 15);
    });

    test('adds the parts back into the minutes the API stores', () {
      const duration = ShippingDuration(days: 1, hours: 2, minutes: 30);

      expect(duration.totalMinutes, 1440 + 120 + 30);
    });

    test('names only the parts that are set', () {
      expect(const ShippingDuration(days: 2, hours: 4).label, '2 يوم و4 ساعة');
      expect(const ShippingDuration().label, 'بدون مدة');
    });

    test('refuses more than the API\'s one-year ceiling', () {
      expect(const ShippingDuration(days: 365).exceedsMax, isFalse);
      expect(const ShippingDuration(days: 365, minutes: 1).exceedsMax, isTrue);
    });
  });

  group('ZoneModel', () {
    test('reads the shipping time and currency', () {
      final zone = ZoneModel.fromJson({
        'id': 'z1',
        'laboratoryId': 'l1',
        'returnDeliveryFee': 5000,
        'shippingCurrencyId': 'c1',
        'shippingMinutes': 2880,
      });

      expect(zone.returnDeliveryFee, 5000);
      expect(zone.shippingCurrencyId, 'c1');
      expect(zone.shippingMinutes, 2880);
    });
  });

  group('UpdateZoneRequestModel', () {
    test('sends the shipping time and currency', () {
      final json = const UpdateZoneRequestModel(
        shippingCurrencyId: 'c1',
        shippingMinutes: 90,
      ).toJson();

      expect(json['shippingCurrencyId'], 'c1');
      expect(json['shippingMinutes'], 90);
    });

    test('asks explicitly to remove the fee', () {
      // A null fee alone leaves the old one in place on the server, so
      // emptying the field used to change nothing.
      final json = const UpdateZoneRequestModel(
        clearReturnDeliveryFee: true,
      ).toJson();

      expect(json['clearReturnDeliveryFee'], isTrue);
    });

    test('leaves the clear flag out when keeping the fee', () {
      final json = const UpdateZoneRequestModel(returnDeliveryFee: 10).toJson();

      expect(json.containsKey('clearReturnDeliveryFee'), isFalse);
    });
  });

  group('ZoneFormCubit.loadCatalog', () {
    late _MockAreasRepo areasRepo;
    late _MockUsersRepo usersRepo;
    late _MockAccountingRepo accountingRepo;
    late ZoneFormCubit cubit;

    setUp(() {
      areasRepo = _MockAreasRepo();
      usersRepo = _MockUsersRepo();
      accountingRepo = _MockAccountingRepo();
      when(
        () => areasRepo.getAreas(),
      ).thenAnswer((_) async => const Right<Failure, List<AreaModel>>([]));
      when(
        () => usersRepo.getUsers(),
      ).thenAnswer((_) async => const Right<Failure, List<UserModel>>([]));
      cubit = ZoneFormCubit(
        _MockZonesRepo(),
        areasRepo,
        usersRepo,
        accountingRepo,
      );
    });

    tearDown(() => cubit.close());

    test('offers the currencies for the delivery fee', () async {
      when(() => accountingRepo.getCurrencies()).thenAnswer(
        (_) async => const Right<Failure, List<CurrencyModel>>([
          CurrencyModel(id: 'c1', code: 'USD'),
        ]),
      );

      await cubit.loadCatalog();

      final state = cubit.state as ZoneFormCatalogLoaded;
      expect(state.currencies.single.id, 'c1');
    });

    test('a failed currency list does not take the form down', () async {
      when(() => accountingRepo.getCurrencies()).thenAnswer(
        (_) async => Left<Failure, List<CurrencyModel>>(ServerFailure('down')),
      );

      await cubit.loadCatalog();

      final state = cubit.state as ZoneFormCatalogLoaded;
      expect(state.currencies, isEmpty);
    });
  });
}
