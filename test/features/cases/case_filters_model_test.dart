import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseFiltersModel stages', () {
    test('an empty set is not an active filter', () {
      // The trap: stageIds defaults to `const {}`, which is non-null. Counting
      // it by null would make every filter set look active and light up the
      // filter button on a list nobody has filtered.
      const filters = CaseFiltersModel();

      expect(filters.activeCount, 0);
      expect(filters.isEmpty, isTrue);
    });

    test('any number of stages counts as one active filter', () {
      const filters = CaseFiltersModel(stageIds: {'s1', 's2', 's3'});

      expect(filters.activeCount, 1);
      expect(filters.isEmpty, isFalse);
    });

    test('copyWith carries the stages forward when not overridden', () {
      const filters = CaseFiltersModel(stageIds: {'s1'});

      expect(filters.copyWith().stageIds, {'s1'});
    });

    test('copyWith clears the stages only when asked', () {
      const filters = CaseFiltersModel(stageIds: {'s1'});

      expect(filters.copyWith(clearStages: true).stageIds, isEmpty);
    });
  });

  group('CaseFiltersModel received window', () {
    test('each bound counts on its own', () {
      final filters = CaseFiltersModel(receivedFrom: DateTime(2026, 3, 1));

      expect(filters.activeCount, 1);
      expect(filters.copyWith(clearReceivedFrom: true).receivedFrom, isNull);
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
