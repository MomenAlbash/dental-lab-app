import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseFiltersModel caseStatus', () {
    test('counts as an active filter', () {
      const filters = CaseFiltersModel(caseStatus: CaseStatus.rejected);

      expect(filters.activeCount, 1);
      expect(filters.isEmpty, isFalse);
    });

    test('copyWith carries the status forward when not overridden', () {
      const filters = CaseFiltersModel(caseStatus: CaseStatus.inProgress);

      expect(filters.copyWith().caseStatus, CaseStatus.inProgress);
    });

    test('copyWith clears the status only when asked', () {
      const filters = CaseFiltersModel(caseStatus: CaseStatus.inProgress);

      expect(filters.copyWith(clearCaseStatus: true).caseStatus, isNull);
    });
  });

  group('CaseFiltersModel patient', () {
    const filters = CaseFiltersModel(
      patientId: 'pt1',
      patientName: 'خالد المصري',
    );

    test('counts as an active filter', () {
      expect(filters.activeCount, 1);
      expect(filters.isEmpty, isFalse);
    });

    test('the label rides along with the id', () {
      expect(filters.copyWith().patientId, 'pt1');
      expect(filters.copyWith().patientName, 'خالد المصري');
    });

    test('clearing drops the id and its label together', () {
      final cleared = filters.copyWith(clearPatient: true);

      expect(cleared.patientId, isNull);
      // A stale name left behind would show the sheet a patient that is no
      // longer being filtered on.
      expect(cleared.patientName, isNull);
      expect(cleared.isEmpty, isTrue);
    });

    test('counts alongside the other filters rather than replacing them', () {
      const both = CaseFiltersModel(patientId: 'pt1', priorityId: 'p1');

      expect(both.activeCount, 2);
    });
  });
}
