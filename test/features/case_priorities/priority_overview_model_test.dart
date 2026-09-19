import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PriorityQuotaLineModel', () {
    test('totalFree adds this period\'s bonus to the standing allowance', () {
      final line = PriorityQuotaLineModel.fromJson(const {
        'priorityId': 'p1',
        'freePerMonth': 3,
        'bonusFree': 2,
      });

      expect(line.totalFree, 5);
    });

    test('surchargeLabel carries the currency the server sent', () {
      final line = PriorityQuotaLineModel.fromJson(const {
        'priorityId': 'p1',
        'surcharge': 12,
        'currency': {'id': 'c1', 'code': 'USD', 'name': 'دولار'},
      });

      expect(line.surchargeLabel, contains('USD'));
    });

    test('surchargeLabel falls back to a bare figure without a currency', () {
      final line = PriorityQuotaLineModel.fromJson(const {
        'priorityId': 'p1',
        'surcharge': 12,
      });

      expect(line.surchargeLabel, '12.00');
    });

    test('priorityLabel prefers Arabic over the English name', () {
      final line = PriorityQuotaLineModel.fromJson(const {
        'priorityId': 'p1',
        'priorityName': 'Urgent',
        'priorityNameAr': 'عاجل',
      });

      expect(line.priorityLabel, 'عاجل');
    });
  });

  group('PriorityOverviewRowModel', () {
    test('hasOverride is true when any single line is negotiated', () {
      final row = PriorityOverviewRowModel.fromJson(const {
        'doctorId': 'd1',
        'lines': [
          {'priorityId': 'p1', 'isOverridden': false},
          {'priorityId': 'p2', 'isOverridden': true},
        ],
      });

      expect(row.hasOverride, isTrue);
    });

    test('unlimited levels are never counted as exhausted', () {
      final row = PriorityOverviewRowModel.fromJson(const {
        'doctorId': 'd1',
        'lines': [
          {'priorityId': 'p1', 'isUnlimited': true, 'remainingFree': 0},
          {'priorityId': 'p2', 'remainingFree': 0},
        ],
      });

      expect(row.exhaustedCount, 1);
    });
  });

  group('PriorityOverviewModel', () {
    test('overriddenCount counts doctors, not lines', () {
      final overview = PriorityOverviewModel.fromJson(const {
        'year': 2026,
        'month': 9,
        'doctors': [
          {
            'doctorId': 'd1',
            'lines': [
              {'priorityId': 'p1', 'isOverridden': true},
              {'priorityId': 'p2', 'isOverridden': true},
            ],
          },
          {
            'doctorId': 'd2',
            'lines': [
              {'priorityId': 'p1', 'isOverridden': false},
            ],
          },
        ],
      });

      expect(overview.overriddenCount, 1);
    });

    test('a malformed reset date leaves the period open rather than throwing', () {
      final overview = PriorityOverviewModel.fromJson(const {
        'periodResetsAt': 'not-a-date',
      });

      expect(overview.periodResetsAt, isNull);
    });
  });

  group('IncreasePriorityAllowanceRequestModel', () {
    test('a permanent raise sends the standing figure and no bonus', () {
      final json = const IncreasePriorityAllowanceRequestModel(
        permanent: true,
        newFreePerMonth: 8,
        bonusFree: 3,
      ).toJson();

      expect(json['newFreePerMonth'], 8);
      expect(json['bonusFree'], isNull);
    });

    test('a one-period top-up sends the bonus and no standing figure', () {
      final json = const IncreasePriorityAllowanceRequestModel(
        permanent: false,
        newFreePerMonth: 8,
        bonusFree: 3,
      ).toJson();

      expect(json['bonusFree'], 3);
      expect(json['newFreePerMonth'], isNull);
    });

    test('a free raise drops any amount left over from a paid draft', () {
      final json = const IncreasePriorityAllowanceRequestModel(
        permanent: true,
        newFreePerMonth: 8,
        paidAmount: 50,
        currencyId: 'c1',
      ).toJson();

      expect(json['paidAmount'], isNull);
      expect(json['currencyId'], isNull);
    });

    test('a paid raise keeps its amount and currency together', () {
      final json = const IncreasePriorityAllowanceRequestModel(
        permanent: false,
        bonusFree: 2,
        isPaid: true,
        paidAmount: 50,
        currencyId: 'c1',
      ).toJson();

      expect(json['paidAmount'], 50);
      expect(json['currencyId'], 'c1');
    });
  });

  group('BulkSetPriorityAllowanceRequestModel', () {
    test('only the listed doctors are written — it is not a replace', () {
      final json = const BulkSetPriorityAllowanceRequestModel(
        doctorIds: ['d1', 'd2'],
        freePerMonth: 5,
      ).toJson();

      expect(json['doctorIds'], ['d1', 'd2']);
    });

    test('a null allowance clears the override rather than setting zero', () {
      final json = const BulkSetPriorityAllowanceRequestModel(
        doctorIds: ['d1'],
      ).toJson();

      expect(json.containsKey('freePerMonth'), isTrue);
      expect(json['freePerMonth'], isNull);
    });
  });
}
