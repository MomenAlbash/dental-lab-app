import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CasePhaseCountModel', () {
    test('the phase column reconciles — every case sits in exactly one', () {
      final phases = [
        for (final json in const [
          {'phase': 1, 'count': 4},
          {'phase': 3, 'count': 9},
          {'phase': 5, 'count': 2},
          {'phase': 6, 'count': 7},
        ])
          CasePhaseCountModel.fromJson(json),
      ];

      expect(
        phases.fold<int>(0, (sum, phase) => sum + phase.count),
        22,
      );
    });

    test('an unknown phase degrades to a dash instead of throwing', () {
      final phase = CasePhaseCountModel.fromJson(const {
        'phase': 99,
        'count': 3,
      });

      expect(phase.phase, isNull);
      expect(phase.label, '—');
      expect(phase.count, 3);
    });

    test('overdueCount is read separately from the phase total', () {
      final phase = CasePhaseCountModel.fromJson(const {
        'phase': 3,
        'count': 9,
        'overdueCount': 3,
      });

      expect(phase.count, 9);
      expect(phase.overdueCount, 3);
      expect(phase.phase, CasePhase.inProduction);
    });
  });

  group('CaseFlowPointModel', () {
    test('net is positive on a day the backlog grew', () {
      final point = CaseFlowPointModel.fromJson(const {
        'date': '2026-09-12',
        'created': 10,
        'delivered': 4,
      });

      expect(point.net, 6);
    });

    test('net is negative on a day the laboratory caught up', () {
      final point = CaseFlowPointModel.fromJson(const {
        'date': '2026-09-12',
        'created': 2,
        'delivered': 7,
      });

      expect(point.net, -5);
    });

    test('a quiet day parses as zeroes, keeping the axis constant', () {
      final point = CaseFlowPointModel.fromJson(const {'date': '2026-09-12'});

      expect(point.created, 0);
      expect(point.delivered, 0);
      expect(point.net, 0);
      expect(point.date, isNotNull);
    });
  });

  group('UserCaseWorkModel', () {
    test('transitions exceed cases when one user carried a case onward', () {
      final work = UserCaseWorkModel.fromJson(const {
        'userId': 'u1',
        'userName': 'سامر',
        'casesWorked': 6,
        'transitionCount': 11,
      });

      expect(work.casesWorked, 6);
      expect(work.transitionCount, 11);
    });

    test('a user who never worked a case parses without a last-worked date', () {
      final work = UserCaseWorkModel.fromJson(const {'userId': 'u1'});

      expect(work.lastWorkedAt, isNull);
      expect(work.casesWorked, 0);
    });
  });
}
