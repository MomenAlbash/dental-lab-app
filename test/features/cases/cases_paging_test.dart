import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_summary.dart';
import 'package:dental_lab_app/features/cases/data/models/cases_page_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockApiService extends Mock implements ApiService {}

CaseListItemModel _case(String id, [String stageId = 's1']) =>
    CaseListItemModel(
      id: id,
      caseNumber: id,
      stage: CaseStageSummary(stageId: stageId),
    );

List<CaseListItemModel> _cases(int from, int count) => [
  for (var i = from; i < from + count; i++) _case('$i'),
];

void main() {
  setUpAll(() => registerFallbackValue(CaseFiltersModel.empty));

  group('CasesPageModel', () {
    test('knows whether another page waits', () {
      final page = CasesPageModel.fromJson({
        'items': [
          {'id': 'a'},
        ],
        'page': 1,
        'pageSize': 30,
        'totalCount': 45,
      });

      expect(page.items.single.id, 'a');
      expect(page.hasMore, isTrue);
      expect(
        const CasesPageModel(page: 2, pageSize: 30, totalCount: 45).hasMore,
        isFalse,
      );
    });

    test('a bare list is one final page', () {
      final page = CasesPageModel.fromJson([
        {'id': 'a'},
        {'id': 'b'},
      ]);

      expect(page.items, hasLength(2));
      expect(page.hasMore, isFalse);
    });
  });

  group('CasesCubit paging', () {
    late _MockCasesRepo repo;
    late CasesCubit cubit;

    /// Pages of [perPage] out of [total] cases, the way the server answers.
    void serve({required int total, int perPage = CasesCubit.pageSize}) {
      when(
        () => repo.getCasesPage(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((call) async {
        final page = call.namedArguments[#page] as int;
        final from = (page - 1) * perPage;
        final count = (total - from).clamp(0, perPage);
        return Right<Failure, CasesPageModel>(
          CasesPageModel(
            items: _cases(from, count),
            page: page,
            pageSize: perPage,
            totalCount: total,
          ),
        );
      });
    }

    setUp(() {
      repo = _MockCasesRepo();
      when(
        () => repo.getPhaseCounts(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
        ),
      ).thenAnswer(
        (_) async =>
            Right<Failure, CasePhaseCountsModel>(CasePhaseCountsModel.empty),
      );
      when(
        () => repo.getSlaCounts(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
        ),
      ).thenAnswer(
        (_) async =>
            Right<Failure, CaseSlaCountsModel>(CaseSlaCountsModel.empty),
      );
      cubit = CasesCubit(repo);
    });

    tearDown(() => cubit.close());

    test('opens with the first page and knows more wait', () async {
      // The bug this replaces: the list asked for 200 and never for more, so
      // a laboratory with 350 cases silently showed 200.
      serve(total: 75);

      await cubit.getCases();

      final state = cubit.state as CasesLoaded;
      expect(state.cases, hasLength(30));
      expect(state.hasMore, isTrue);
    });

    test('loads every case, page after page, then stops', () async {
      serve(total: 75);
      await cubit.getCases();

      await cubit.loadMore();
      await cubit.loadMore();
      await cubit.loadMore();

      final state = cubit.state as CasesLoaded;
      expect(state.cases, hasLength(75));
      expect(state.cases.map((c) => c.id).toSet(), hasLength(75));
      expect(state.hasMore, isFalse);
      verify(
        () => repo.getCasesPage(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
          page: 3,
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
      verifyNever(
        () => repo.getCasesPage(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
          page: 4,
          pageSize: any(named: 'pageSize'),
        ),
      );
    });

    test('a case that shifted into the next page is not shown twice', () async {
      when(
        () => repo.getCasesPage(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((call) async {
        final page = call.namedArguments[#page] as int;
        return Right<Failure, CasesPageModel>(
          CasesPageModel(
            items: page == 1 ? _cases(0, 30) : _cases(29, 5),
            page: page,
            pageSize: 30,
            totalCount: 34,
          ),
        );
      });
      await cubit.getCases();

      await cubit.loadMore();

      expect((cubit.state as CasesLoaded).cases, hasLength(34));
    });

    test('a page emptied by the client-side filter looks further', () async {
      when(
        () => repo.getCasesPage(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((call) async {
        final page = call.namedArguments[#page] as int;
        return Right<Failure, CasesPageModel>(
          CasesPageModel(
            items: page < 3 ? const [] : _cases(0, 2),
            page: page,
            pageSize: 30,
            totalCount: 120,
          ),
        );
      });

      await cubit.getCases();

      expect((cubit.state as CasesLoaded).cases, hasLength(2));
    });

    test('the schedule gets every case, not the first page', () async {
      // It sorts by due date itself; a first page would silently leave out
      // everything that sorted after it.
      serve(total: 450, perPage: 200);

      await cubit.loadEverything();

      final state = cubit.state as CasesLoaded;
      expect(state.cases, hasLength(450));
      expect(state.hasMore, isFalse);
      verify(
        () => repo.getCasesPage(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
          page: any(named: 'page'),
          pageSize: 200,
        ),
      ).called(3);
    });

    test('a failed next page keeps what is shown', () async {
      serve(total: 75);
      await cubit.getCases();
      when(
        () => repo.getCasesPage(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
          page: 2,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => Left<Failure, CasesPageModel>(ServerFailure('down')),
      );

      await cubit.loadMore();

      final state = cubit.state as CasesLoaded;
      expect(state.cases, hasLength(30));
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
    });

    test('a page from before a reload is dropped', () async {
      serve(total: 75);
      await cubit.getCases();
      final slow = Completer<Either<Failure, CasesPageModel>>();
      when(
        () => repo.getCasesPage(
          search: any(named: 'search'),
          filters: any(named: 'filters'),
          page: 2,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) => slow.future);

      final pending = cubit.loadMore();
      await cubit.getCases();
      slow.complete(
        Right(
          CasesPageModel(
            items: _cases(900, 30),
            page: 2,
            pageSize: 30,
            totalCount: 75,
          ),
        ),
      );
      await pending;

      final ids = (cubit.state as CasesLoaded).cases.map((c) => c.id);
      expect(ids, isNot(contains('900')));
      expect(ids, hasLength(30));
    });
  });

  group('CasesRepo.getCasesPage', () {
    late _MockApiService api;
    late CasesRepo repo;

    void apiAnswers(Future<CasesPageModel> Function() answer) {
      when(
        () => api.getCasesPage(
          search: any(named: 'search'),
          doctorId: any(named: 'doctorId'),
          clinicId: any(named: 'clinicId'),
          patientId: any(named: 'patientId'),
          priorityId: any(named: 'priorityId'),
          stageIds: any(named: 'stageIds'),
          restorationStageIds: any(named: 'restorationStageIds'),
          overriddenRestorationIds: any(named: 'overriddenRestorationIds'),
          matchAnyAssignedStage: any(named: 'matchAnyAssignedStage'),
          laboratoryIds: any(named: 'laboratoryIds'),
          receivedFrom: any(named: 'receivedFrom'),
          receivedTo: any(named: 'receivedTo'),
          phaseTab: any(named: 'phaseTab'),
          slaParam: any(named: 'slaParam'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) => answer());
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CacheHelper.init();
      api = _MockApiService();
      repo = CasesRepo(api);
    });

    test('"my tasks" keeps a case matched on a restoration stage', () async {
      // The server matched this case on ANY assigned stage — here a
      // restoration stage — so its case stage need not be among stageIds.
      // Narrowing by case stage on top used to drop it.
      apiAnswers(
        () async => CasesPageModel(
          items: [_case('r', 'other')],
          pageSize: 30,
          totalCount: 1,
        ),
      );

      final result = await repo.getCasesPage(
        filters: const CaseFiltersModel(
          stageIds: {'s1'},
          matchAnyAssignedStage: true,
        ),
      );

      expect(
        result.getOrElse(() => const CasesPageModel()).items,
        hasLength(1),
      );
    });

    test('a later page failing is a failure, not stale cached rows', () async {
      apiAnswers(
        () => Future.error(
          DioException(requestOptions: RequestOptions(path: 'Cases')),
        ),
      );

      final result = await repo.getCasesPage(page: 2);

      expect(result.isLeft(), isTrue);
    });
  });
}
