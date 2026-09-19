import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_breakdown_group.dart';
import 'package:flutter_test/flutter_test.dart';

/// A case row carrying [breakdown] as the server would send it — the key is
/// always present, so an explicit `null` can be told apart from an absent one.
Map<String, dynamic> _caseJson(dynamic breakdown) => {
  ..._caseWithoutBreakdown,
  'restorationBreakdown': breakdown,
};

/// A row from a server build that does not send the field at all.
const _caseWithoutBreakdown = <String, dynamic>{
  'id': 'c1',
  'caseNumber': '1247',
  'restorationsCount': 4,
};

Map<String, dynamic> _group({
  String? stageId = 's1',
  String? stageNameAr = 'التشطيب',
  String? stageName,
  String? typeAr = 'زيركون',
  String? typeEn,
  int count = 1,
}) => {
  'restorationTypeId': 't1',
  'restorationTypeName': typeEn,
  'restorationTypeNameAr': typeAr,
  'stageId': stageId,
  'stageName': stageName,
  'stageNameAr': stageNameAr,
  'count': count,
};

void main() {
  group('CaseRestorationBreakdownGroup', () {
    test('parses a group off a case row', () {
      final parsed = CaseRestorationBreakdownGroup.fromJson(
        _group(count: 2),
      );

      expect(parsed.restorationTypeLabel, 'زيركون');
      expect(parsed.stageLabel, 'التشطيب');
      expect(parsed.count, 2);
      expect(parsed.hasStarted, isTrue);
    });

    test('a missing count is zero rather than null', () {
      final parsed = CaseRestorationBreakdownGroup.fromJson(const {
        'restorationTypeNameAr': 'زيركون',
      });

      expect(parsed.count, 0);
    });

    test('labels prefer Arabic over English', () {
      final parsed = CaseRestorationBreakdownGroup.fromJson(
        _group(typeAr: 'زيركون', typeEn: 'Zirconia'),
      );

      expect(parsed.restorationTypeLabel, 'زيركون');
    });

    test('a blank Arabic name falls back to English, not just a null one', () {
      final parsed = CaseRestorationBreakdownGroup.fromJson(
        _group(typeAr: '   ', typeEn: 'Zirconia'),
      );

      expect(parsed.restorationTypeLabel, 'Zirconia');
    });

    test('an unnamed type is empty, never an invented placeholder', () {
      final parsed = CaseRestorationBreakdownGroup.fromJson(
        _group(typeAr: null, typeEn: null),
      );

      expect(parsed.restorationTypeLabel, isEmpty);
    });

    test('a null stageId reads as not started, not as an error', () {
      final parsed = CaseRestorationBreakdownGroup.fromJson(
        _group(stageId: null, stageNameAr: null),
      );

      expect(parsed.hasStarted, isFalse);
      expect(parsed.stageLabel, isEmpty);
    });

    test('a stage with an id but no name is not started', () {
      // Rendering a blank where a stage belongs reads as a fault; treating it
      // as unstarted at least says something the user can question.
      final parsed = CaseRestorationBreakdownGroup.fromJson(
        _group(stageId: 's1', stageNameAr: null, stageName: null),
      );

      expect(parsed.hasStarted, isFalse);
    });
  });

  group('CaseListItemModel.restorationBreakdown', () {
    test('an absent key parses to an empty list, not null', () {
      // A server build that predates the field must leave the row working.
      final parsed = CaseListItemModel.fromJson(_caseWithoutBreakdown);

      expect(parsed.restorationBreakdown, isEmpty);
      expect(parsed.hasRestorationBreakdown, isFalse);
    });

    test('an explicit null parses to an empty list', () {
      final parsed = CaseListItemModel.fromJson(_caseJson(null));

      expect(parsed.restorationBreakdown, isEmpty);
      expect(parsed.hasRestorationBreakdown, isFalse);
    });

    test('a breakdown of the wrong shape is dropped, never thrown', () {
      // The guard that stops one malformed row from failing the parse of
      // every row in the /Cases response and blanking the screen.
      expect(
        CaseListItemModel.fromJson(
          _caseJson({'unexpected': 'object'}),
        ).restorationBreakdown,
        isEmpty,
      );
      expect(
        CaseListItemModel.fromJson(_caseJson('nonsense')).restorationBreakdown,
        isEmpty,
      );
    });

    test('a malformed entry is skipped and the rest survive', () {
      final parsed = CaseListItemModel.fromJson(
        _caseJson([_group(typeAr: 'زيركون'), 'not a group', 42]),
      );

      expect(parsed.restorationBreakdown, hasLength(1));
      expect(
        parsed.restorationBreakdown.single.restorationTypeLabel,
        'زيركون',
      );
    });

    test('the breakdown keeps the order the server sent it in', () {
      final parsed = CaseListItemModel.fromJson(
        _caseJson([
          _group(stageNameAr: 'التلميع'),
          _group(stageNameAr: 'الصب'),
          _group(stageNameAr: 'التشطيب'),
        ]),
      );

      expect(
        parsed.restorationBreakdown.map((g) => g.stageLabel),
        ['التلميع', 'الصب', 'التشطيب'],
      );
    });

    test('a case with restorations offers the expander', () {
      final parsed = CaseListItemModel.fromJson(_caseJson([_group()]));

      expect(parsed.hasRestorationBreakdown, isTrue);
    });
  });

  group('CaseListItemModel.orderedRestorationBreakdown', () {
    test('groups that have not started are drawn last', () {
      final parsed = CaseListItemModel.fromJson(
        _caseJson([
          _group(stageId: null, stageNameAr: null, typeAr: 'بورسلان'),
          _group(stageNameAr: 'التشطيب', typeAr: 'زيركون'),
        ]),
      );

      expect(
        parsed.orderedRestorationBreakdown.map((g) => g.restorationTypeLabel),
        ['زيركون', 'بورسلان'],
      );
    });

    test('order is stable within the started and not-started halves', () {
      // A comparator-based sort would be free to scramble these; the
      // partition must not.
      final parsed = CaseListItemModel.fromJson(
        _caseJson([
          _group(stageNameAr: 'التلميع', typeAr: 'أ'),
          _group(stageId: null, stageNameAr: null, typeAr: 'ب'),
          _group(stageNameAr: 'الصب', typeAr: 'ج'),
          _group(stageId: null, stageNameAr: null, typeAr: 'د'),
        ]),
      );

      expect(
        parsed.orderedRestorationBreakdown.map((g) => g.restorationTypeLabel),
        ['أ', 'ج', 'ب', 'د'],
      );
    });

    test('an all-unstarted breakdown keeps its order untouched', () {
      final parsed = CaseListItemModel.fromJson(
        _caseJson([
          _group(stageId: null, stageNameAr: null, typeAr: 'أ'),
          _group(stageId: null, stageNameAr: null, typeAr: 'ب'),
        ]),
      );

      expect(
        parsed.orderedRestorationBreakdown.map((g) => g.restorationTypeLabel),
        ['أ', 'ب'],
      );
    });
  });
}
