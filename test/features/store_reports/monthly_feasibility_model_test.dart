import 'package:dental_lab_app/features/store_reports/data/models/monthly_feasibility_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyFeasibilityPointModel', () {
    test('parses a full month', () {
      final point = MonthlyFeasibilityPointModel.fromJson(const {
        'month': '2026-07-01',
        'revenue': 500000,
        'expenses': 100000,
        'purchases': 150000,
        'payrollCost': 200000,
        'netProfit': 50000,
        'cumulativeCash': 320000,
      });

      expect(point.month, DateTime.parse('2026-07-01'));
      expect(point.revenue, 500000);
      expect(point.netProfit, 50000);
      expect(point.cumulativeCash, 320000);
    });

    test('a bare month parses with everything at zero', () {
      final point = MonthlyFeasibilityPointModel.fromJson(const {});

      expect(point.month, isNull);
      expect(point.revenue, 0);
      expect(point.cumulativeCash, 0);
    });
  });

  group('MonthlyFeasibilityModel', () {
    test('parses one series per currency', () {
      final feasibility = MonthlyFeasibilityModel.fromJson(const {
        'currencies': [
          {
            'currency': {'id': 'c1', 'name': 'ليرة سورية'},
            'points': [
              {'month': '2026-07-01', 'netProfit': 50000},
            ],
          },
          {
            'currency': {'id': 'c2', 'name': 'دولار'},
            'points': [],
          },
        ],
      });

      expect(feasibility.currencies, hasLength(2));
      expect(feasibility.currencies.first.currency?.name, 'ليرة سورية');
      expect(feasibility.currencies.first.points.single.netProfit, 50000);
      expect(feasibility.currencies.last.points, isEmpty);
    });

    test('no currencies parses as an empty list, not an error', () {
      final feasibility = MonthlyFeasibilityModel.fromJson(const {});

      expect(feasibility.currencies, isEmpty);
    });
  });
}
