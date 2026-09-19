import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

CaseListItemModel _case(String id) => CaseListItemModel(id: id, caseNumber: id);

void main() {
  late _MockCasesRepo repo;
  late CasesCubit cubit;

  /// The last filters the list was fetched with — what the tab bar and the
  /// date segment actually sent.
  CaseFiltersModel lastFilters() =>
      verify(
            () => repo.getCases(
              search: any(named: 'search'),
              filters: captureAny(named: 'filters'),
            ),
          ).captured.last
          as CaseFiltersModel;

  setUpAll(() => registerFallbackValue(CaseFiltersModel.empty));

  setUp(() {
    repo = _MockCasesRepo();
    when(
      () => repo.getCases(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<CaseListItemModel>>([_case('1')]),
    );
    when(
      () => repo.getPhaseCounts(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, CasePhaseCountsModel>(
        const CasePhaseCountsModel(all: 9, newCases: 2, inProduction: 7),
      ),
    );
    when(
      () => repo.getSlaCounts(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, CaseSlaCountsModel>(
        const CaseSlaCountsModel(late$: 3, dueToday: 1),
      ),
    );

    cubit = CasesCubit(repo);
  });

  tearDown(() => cubit.close());

  group('counts', () {
    test('the badges come from the server, not from counting the page', () async {
      // The list is one page; the counts are the whole laboratory under the
      // same filters. Counting the rows would have made "متأخرة: 3" mean
      // "3 of the 200 I happen to have".
      await cubit.getCases();

      final state = cubit.state as CasesLoaded;
      expect(state.cases.length, 1);
      expect(state.phaseCounts.all, 9);
      expect(state.slaCounts.late$, 3);
    });

    test('a failed count keeps the last badges and never fails the list', () async {
      await cubit.getCases();

      when(
        () => repo.getPhaseCounts(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
        ),
      ).thenAnswer(
        (_) async => Left<Failure, CasePhaseCountsModel>(
          ServerFailure('انقطع الاتصال'),
        ),
      );

      await cubit.getCases();

      final state = cubit.state as CasesLoaded;
      expect(state.phaseCounts.all, 9);
      expect(state.cases, isNotEmpty);
    });
  });

  group('phase tab', () {
    test('sends the tab as its own parameter', () async {
      await cubit.setPhaseTab(CasePhaseTab.ready);

      expect(lastFilters().phaseTab, CasePhaseTab.ready);
      expect(CasePhaseTab.ready.value, 3);
    });

    test('the "all" tab exists by sending nothing', () async {
      await cubit.setPhaseTab(CasePhaseTab.delivered);
      await cubit.setPhaseTab(CasePhaseTab.all);

      expect(lastFilters().phaseTab.value, isNull);
    });

    test('re-selecting the open tab does not refetch', () async {
      await cubit.getCases();
      await cubit.setPhaseTab(CasePhaseTab.all);

      verify(
        () => repo.getCases(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
        ),
      ).called(1);
    });

    test('changing the tab keeps the filters already applied', () async {
      await cubit.applyFilters(const CaseFiltersModel(doctorId: 'd1'));
      await cubit.setPhaseTab(CasePhaseTab.inProduction);

      final filters = lastFilters();
      expect(filters.doctorId, 'd1');
      expect(filters.phaseTab, CasePhaseTab.inProduction);
    });
  });

  group('SLA segment', () {
    test('tapping the selected chip clears it', () async {
      await cubit.toggleSlaFilter(CaseSlaFilter.late$);
      expect(lastFilters().sla, CaseSlaFilter.late$);

      await cubit.toggleSlaFilter(CaseSlaFilter.late$);
      expect(lastFilters().sla, CaseSlaFilter.none);
    });

    test('only one date question can be on at a time', () async {
      // The three exclude one another server-side, so the control is a single
      // selection rather than three independent switches.
      await cubit.toggleSlaFilter(CaseSlaFilter.late$);
      await cubit.toggleSlaFilter(CaseSlaFilter.dueToday);

      expect(lastFilters().sla, CaseSlaFilter.dueToday);
    });
  });

  group('my tasks', () {
    test('narrows to the stages the server says are assigned', () async {
      when(() => repo.getMyWorkflowAssignments()).thenAnswer(
        (_) async => Right<Failure, MyWorkflowAssignmentsModel>(
          const MyWorkflowAssignmentsModel(
            caseStageIds: ['cs1'],
            restorationStageIds: ['rs1', 'rs2'],
          ),
        ),
      );

      await cubit.setMyTasks(true);

      final filters = lastFilters();
      expect(filters.stageIds, {'cs1'});
      expect(filters.restorationStageIds, {'rs1', 'rs2'});
      expect(cubit.isMyTasks, isTrue);
    });

    test('nothing assigned says so instead of showing every case', () async {
      // An empty assignment list and "no cases" are different answers, and
      // falling back to the whole laboratory would hide the first one.
      when(() => repo.getMyWorkflowAssignments()).thenAnswer(
        (_) async => Right<Failure, MyWorkflowAssignmentsModel>(
          MyWorkflowAssignmentsModel.empty,
        ),
      );

      await cubit.setMyTasks(true);

      expect(cubit.state, isA<CasesNoAssignments>());
      verifyNever(
        () => repo.getCases(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
        ),
      );
    });

    test('switching back off drops the assignment filter', () async {
      when(() => repo.getMyWorkflowAssignments()).thenAnswer(
        (_) async => Right<Failure, MyWorkflowAssignmentsModel>(
          const MyWorkflowAssignmentsModel(caseStageIds: ['cs1']),
        ),
      );

      await cubit.setMyTasks(true);
      await cubit.setMyTasks(false);

      final filters = lastFilters();
      expect(filters.stageIds, isEmpty);
      expect(filters.restorationStageIds, isEmpty);
      expect(cubit.isMyTasks, isFalse);
    });
  });
}
