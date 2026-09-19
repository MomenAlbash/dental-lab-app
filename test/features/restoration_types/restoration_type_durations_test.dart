import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/save_priority_duration_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/save_restoration_type_price_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _price = [
  SaveRestorationTypePriceRequestModel(currencyId: 'c1', price: 100),
];

void main() {
  group('SavePriorityDurationRequestModel.fromTotalMinutes', () {
    test('splits a plain total into days plus a minute remainder', () {
      // The API stores whole days and an hours-and-minutes remainder, not one
      // combined minute count — a lab entering "3 days, 4 hours" must send
      // durationDays: 3, durationMinutes: 240, not durationMinutes: 4560.
      final model = SavePriorityDurationRequestModel.fromTotalMinutes(
        casePriorityId: 'p1',
        totalMinutes: 720,
      );

      expect(model.durationDays, 0);
      expect(model.durationMinutes, 720);
    });

    test('a total spanning more than one day carries the whole days too', () {
      final model = SavePriorityDurationRequestModel.fromTotalMinutes(
        casePriorityId: 'p1',
        totalMinutes: 4560, // 3 days, 4 hours
      );

      expect(model.durationDays, 3);
      expect(model.durationMinutes, 240);
    });
  });

  group('CreateRestorationTypeRequestModel', () {
    test('sends one duration row per priority the lab declared', () {
      // Not four fixed columns: the Low/Normal/High/Urgent keys belonged to
      // the retired CasePriority enum and the server drops them on the floor.
      final json = CreateRestorationTypeRequestModel(
        name: 'Zircon',
        prices: _price,
        durations: const [
          SavePriorityDurationRequestModel(
            casePriorityId: 'p1',
            durationDays: 0,
            durationMinutes: 720,
          ),
          SavePriorityDurationRequestModel(
            casePriorityId: 'p2',
            durationDays: 1,
            durationMinutes: 0,
          ),
        ],
      ).toJson();

      expect(json['durations'], [
        {'casePriorityId': 'p1', 'durationDays': 0, 'durationMinutes': 720},
        {'casePriorityId': 'p2', 'durationDays': 1, 'durationMinutes': 0},
      ]);
      expect(json.containsKey('lowPriorityDurationMinutes'), isFalse);
      expect(json.containsKey('urgentPriorityDurationMinutes'), isFalse);
      // There is no currency-less default price on the live API.
      expect(json.containsKey('defaultPrice'), isFalse);
    });

    test('a type with no estimates sends an empty list, not four nulls', () {
      final json = CreateRestorationTypeRequestModel(
        name: 'Zircon',
        prices: _price,
      ).toJson();

      expect(json['durations'], isEmpty);
    });

    test('refuses a type with no price — the server would too', () {
      // A restoration type with nobody able to price it is not a service the
      // laboratory offers; `ClinicCreateRestorationTypeRequest.prices`
      // requires at least one row.
      expect(
        () =>
            CreateRestorationTypeRequestModel(name: 'Zircon', prices: const []),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  test('the update request carries the same rows', () {
    final json = UpdateRestorationTypeRequestModel(
      name: 'Zircon',
      prices: _price,
      durations: const [
        SavePriorityDurationRequestModel(
          casePriorityId: 'p1',
          durationDays: 0,
          durationMinutes: 60,
        ),
      ],
    ).toJson();

    expect(json['durations'], [
      {'casePriorityId': 'p1', 'durationDays': 0, 'durationMinutes': 60},
    ]);
    expect(json.containsKey('defaultPrice'), isFalse);
  });

  group('RestorationTypeModel', () {
    test('reads the durations back, keyed by priority', () {
      final type = RestorationTypeModel.fromJson(const {
        'id': 't1',
        'name': 'Zircon',
        'durations': [
          {
            'casePriorityId': 'p1',
            'priorityNameAr': 'عاجلة',
            'durationMinutes': 720,
          },
        ],
      });

      expect(type.durations.single.casePriorityId, 'p1');
      expect(type.durations.single.durationMinutes, 720);
    });

    test('a type with no durations parses as an empty list', () {
      final type = RestorationTypeModel.fromJson(const {'id': 't1'});

      expect(type.durations, isEmpty);
    });

    test('the catalogue price is read off the first currency row', () {
      // Not a currency-less `defaultPrice` — the plain catalog response never
      // carried one, so a card that showed it always read "0".
      final type = RestorationTypeModel.fromJson(const {
        'id': 't1',
        'prices': [
          {
            'currencyId': 'c1',
            'currency': {'id': 'c1', 'name': 'ليرة سورية'},
            'price': 250000.0,
          },
        ],
      });

      expect(type.catalogPriceLabel, '250000 ليرة سورية');
    });

    test('an unpriced type has no catalogue price label', () {
      final type = RestorationTypeModel.fromJson(const {'id': 't1'});

      expect(type.catalogPriceLabel, isNull);
    });
  });
}
