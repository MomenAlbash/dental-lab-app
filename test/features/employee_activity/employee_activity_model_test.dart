import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmployeeActivityFiltersModel.toQuery', () {
    test('list filters repeat their key, which is what the binder reads', () {
      final query = const EmployeeActivityFiltersModel(
        userIds: ['u1', 'u2'],
      ).toQuery();

      // A comma-joined single value binds as one id whose name happens to
      // contain a comma, and silently matches nothing.
      expect(query, contains('UserIds=u1'));
      expect(query, contains('UserIds=u2'));
      expect(query, isNot(contains('u1%2Cu2')));
    });

    test('kinds go out as their wire values', () {
      final query = const EmployeeActivityFiltersModel(
        kinds: [ActivityKind.caseStageMove, ActivityKind.scannerSession],
      ).toQuery();

      expect(query, contains('Kinds=2'));
      expect(query, contains('Kinds=4'));
    });

    test('the defaults omit the include flags, since both are on', () {
      final query = const EmployeeActivityFiltersModel().toQuery();

      expect(query, isNot(contains('IncludeReturns')));
      expect(query, isNot(contains('IncludeRejected')));
    });

    test('excluding returns is sent explicitly', () {
      final query = const EmployeeActivityFiltersModel(
        includeReturns: false,
      ).toQuery();

      expect(query, contains('IncludeReturns=false'));
    });

    test('paging is always sent', () {
      final query = const EmployeeActivityFiltersModel(
        page: 3,
        pageSize: 20,
      ).toQuery();

      expect(query, contains('Page=3'));
      expect(query, contains('PageSize=20'));
    });

    test('a case number is encoded rather than pasted in raw', () {
      final query = const EmployeeActivityFiltersModel(
        caseNumber: 'C 12/3',
      ).toQuery();

      expect(query, isNot(contains('C 12/3')));
      expect(query, contains('CaseNumber='));
    });
  });

  group('EmployeeActivityFiltersModel.hasAnyFilter', () {
    test('the bare defaults count as no filter', () {
      expect(const EmployeeActivityFiltersModel().hasAnyFilter, isFalse);
    });

    test('turning a default off counts as a filter', () {
      expect(
        const EmployeeActivityFiltersModel(includeReturns: false).hasAnyFilter,
        isTrue,
      );
    });
  });

  group('EmployeeActivitySummaryModel', () {
    test('returnRate is the share of events that were rework', () {
      final summary = EmployeeActivitySummaryModel.fromJson(const {
        'totalEvents': 200,
        'returns': 50,
      });

      expect(summary.returnRate, 0.25);
    });

    test('a quiet period has no rework problem, not a divide by zero', () {
      final summary = EmployeeActivitySummaryModel.fromJson(const {
        'totalEvents': 0,
        'returns': 0,
      });

      expect(summary.returnRate, 0);
    });

    test('activeEmployees is read as sent — it is not the roster size', () {
      final summary = EmployeeActivitySummaryModel.fromJson(const {
        'activeEmployees': 4,
        'byEmployee': [
          {'userId': 'u1', 'name': 'سامر', 'count': 90},
          {'userId': 'u2', 'name': 'ليلى', 'count': 60},
        ],
      });

      expect(summary.activeEmployees, 4);
      expect(summary.byEmployee, hasLength(2));
    });
  });

  group('ActivityTimelineItemModel', () {
    test('moveLabel pairs origin and destination in Arabic', () {
      final item = ActivityTimelineItemModel.fromJson(const {
        'userId': 'u1',
        'stageNameAr': 'التلميع',
        'fromStageNameAr': 'التشطيب',
      });

      expect(item.moveLabel, 'التشطيب ← التلميع');
    });

    test('a first move into a route has no origin to show', () {
      final item = ActivityTimelineItemModel.fromJson(const {
        'userId': 'u1',
        'stageNameAr': 'الاستلام',
      });

      expect(item.moveLabel, 'الاستلام');
    });

    test('the internal name stands in when there is no Arabic one', () {
      final item = ActivityTimelineItemModel.fromJson(const {
        'userId': 'u1',
        'stageName': 'Polishing',
      });

      expect(item.stageLabel, 'Polishing');
    });

    test('a repeat pass needs attention even without a return flag', () {
      final item = ActivityTimelineItemModel.fromJson(const {
        'userId': 'u1',
        'attempt': 2,
      });

      expect(item.isReturn, isFalse);
      expect(item.needsAttention, isTrue);
    });

    test('an ordinary first-pass move needs no attention', () {
      final item = ActivityTimelineItemModel.fromJson(const {
        'userId': 'u1',
        'attempt': 1,
      });

      expect(item.needsAttention, isFalse);
    });

    test('a rejection is distinguished from a plain return', () {
      final item = ActivityTimelineItemModel.fromJson(const {
        'userId': 'u1',
        'isReturn': true,
        'isRejected': true,
        'reason': 'الطبعة ناقصة',
      });

      expect(item.isRejected, isTrue);
      expect(item.reason, 'الطبعة ناقصة');
    });
  });

  group('ActivityTimelineModel', () {
    test('hasMore is true while pages remain', () {
      final timeline = ActivityTimelineModel.fromJson(const {
        'items': [],
        'page': 1,
        'totalPages': 4,
      });

      expect(timeline.hasMore, isTrue);
    });

    test('the last page has no more', () {
      final timeline = ActivityTimelineModel.fromJson(const {
        'items': [],
        'page': 4,
        'totalPages': 4,
      });

      expect(timeline.hasMore, isFalse);
    });
  });

  group('EmployeeActivityDailyModel', () {
    test('returns are counted apart from the total', () {
      final row = EmployeeActivityDailyModel.fromJson(const {
        'userId': 'u1',
        'totalCount': 40,
        'returns': 9,
        'distinctCases': 12,
      });

      expect(row.totalCount, 40);
      expect(row.returns, 9);
      // Cases touched, counted once each — not the number of moves.
      expect(row.distinctCases, 12);
    });

    test('a single event gives no span rather than a zero-length one', () {
      final row = EmployeeActivityDailyModel.fromJson(const {
        'userId': 'u1',
        'firstAt': '2026-09-12T09:00:00Z',
      });

      expect(row.spanLabel, '—');
    });
  });

  group('ActivityKind', () {
    test('every wire value maps to a labelled kind', () {
      for (final kind in ActivityKind.values) {
        expect(ActivityKind.fromValue(kind.value), kind);
        expect(kind.label, isNotEmpty);
      }
    });

    test('an unknown value degrades to null', () {
      expect(ActivityKind.fromValue(99), isNull);
    });
  });
}
