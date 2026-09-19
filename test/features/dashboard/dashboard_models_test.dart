import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardSummaryModel', () {
    test('reads every counter', () {
      final model = DashboardSummaryModel.fromJson(const {
        'totalCases': 12,
        'totalDoctors': 3,
        'totalClinics': 2,
        'totalPatients': 40,
        'totalLaboratories': 1,
      });

      expect(model.totalCases, 12);
      expect(model.totalDoctors, 3);
      expect(model.totalClinics, 2);
      expect(model.totalPatients, 40);
      expect(model.totalLaboratories, 1);
    });

    test('treats a missing counter as zero rather than throwing', () {
      final model = DashboardSummaryModel.fromJson(const {'totalCases': 5});

      expect(model.totalCases, 5);
      expect(model.totalPatients, 0);
    });
  });

  group('pickLocalizedName', () {
    test('prefers the Arabic name', () {
      expect(pickLocalizedName('تشطيب', 'Finishing'), 'تشطيب');
    });

    test('falls back to English when Arabic is blank', () {
      expect(pickLocalizedName('   ', 'Finishing'), 'Finishing');
    });

    test('returns empty when the server sent neither', () {
      expect(pickLocalizedName(null, null), '');
    });
  });

  group('CaseStageCountModel', () {
    test('parses names, badge variant and count', () {
      final model = CaseStageCountModel.fromJson(const {
        'stageId': 'stage-1',
        'stageName': 'Finishing',
        'stageNameAr': 'تشطيب',
        'categoryName': 'Production',
        'categoryNameAr': 'الإنتاج',
        'badgeVariant': 'warning',
        'count': 7,
      });

      expect(model.label, 'تشطيب');
      expect(model.categoryLabel, 'الإنتاج');
      expect(model.badgeVariant, 'warning');
      expect(model.count, 7);
    });
  });

  group('MonthlyRevenueModel', () {
    test('parses the month and revenue', () {
      final model = MonthlyRevenueModel.fromJson(const {
        'month': '2026-08-01',
        'revenue': 1250.5,
      });

      expect(model.month, DateTime(2026, 8, 1));
      expect(model.revenue, 1250.5);
    });

    test('drops an unparsable month instead of defaulting to the epoch', () {
      final model = MonthlyRevenueModel.fromJson(const {
        'month': 'not-a-date',
        'revenue': 10,
      });

      expect(model.month, isNull);
    });
  });

  group('UpcomingDueCaseModel.daysUntilDue', () {
    UpcomingDueCaseModel caseDue(DateTime? at) =>
        UpcomingDueCaseModel(id: 'c1', expectedCompletionAt: at);

    final now = DateTime(2026, 8, 12, 14, 30);

    test('counts whole days ahead', () {
      expect(caseDue(DateTime(2026, 8, 15)).daysUntilDue(now: now), 3);
    });

    test('a case due later today is zero days away, not one', () {
      expect(caseDue(DateTime(2026, 8, 12, 23, 59)).daysUntilDue(now: now), 0);
    });

    test('an overdue case is negative', () {
      expect(caseDue(DateTime(2026, 8, 10)).daysUntilDue(now: now), -2);
    });

    test('is null when the case has no due date', () {
      expect(caseDue(null).daysUntilDue(now: now), isNull);
    });
  });

  group('RecentActivityModel', () {
    test('parses a return', () {
      final model = RecentActivityModel.fromJson(const {
        'caseId': 'case-1',
        'caseNumber': 'C-100',
        'previousStageName': 'Finishing',
        'stageName': 'Modelling',
        'isReturn': true,
        'changedAt': '2026-08-12T10:00:00Z',
      });

      expect(model.isReturn, isTrue);
      expect(model.caseNumber, 'C-100');
      expect(model.changedAt, isNotNull);
    });

    test('defaults isReturn to false when absent', () {
      final model = RecentActivityModel.fromJson(const {'caseId': 'case-1'});

      expect(model.isReturn, isFalse);
    });
  });
}
