import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:dental_lab_app/features/dashboard/data/repos/dashboard_repo.dart';
import 'package:dental_lab_app/features/dashboard/logic/dashboard/dashboard_cubit.dart';
import 'package:dental_lab_app/features/dashboard/logic/dashboard/dashboard_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDashboardRepo extends Mock implements DashboardRepo {}

void main() {
  late _MockDashboardRepo repo;

  const summary = DashboardSummaryModel(totalCases: 9);

  /// Every deferred endpoint answers with an empty list unless a test says
  /// otherwise, so a test only has to stub the one call it is about.
  void stubDeferredSuccess() {
    when(
      () => repo.getCasesByStage(),
    ).thenAnswer((_) async => right(const <CaseStageCountModel>[]));
    when(
      () => repo.getCasesByPriority(),
    ).thenAnswer((_) async => right(const <CasePriorityCountModel>[]));
    when(
      () => repo.getUpcomingDueCases(),
    ).thenAnswer((_) async => right(const <UpcomingDueCaseModel>[]));
    when(
      () => repo.getTopDoctors(),
    ).thenAnswer((_) async => right(const <TopDoctorModel>[]));
    when(
      () => repo.getRevenueByMonth(),
    ).thenAnswer((_) async => right(const <MonthlyRevenueModel>[]));
    when(
      () => repo.getRecentActivity(),
    ).thenAnswer((_) async => right(const <RecentActivityModel>[]));
    when(
      () => repo.getCasesByPhase(),
    ).thenAnswer((_) async => right(const <CasePhaseCountModel>[]));
    when(
      () => repo.getCaseFlow(),
    ).thenAnswer((_) async => right(const <CaseFlowPointModel>[]));
    when(
      () => repo.getUserCaseWork(),
    ).thenAnswer((_) async => right(const <UserCaseWorkModel>[]));
  }

  void stubEssentialsSuccess() {
    when(() => repo.getSummary()).thenAnswer((_) async => right(summary));
    when(
      () => repo.getRecentCases(),
    ).thenAnswer((_) async => right(<CaseListItemModel>[]));
  }

  setUp(() {
    repo = _MockDashboardRepo();
  });

  test('starts with every section idle', () {
    final cubit = DashboardCubit(repo);

    expect(cubit.state.summary, isA<SectionIdle<DashboardSummaryModel>>());
    expect(cubit.state.deferredRequested, isFalse);
  });

  test('loadEssentials fills the summary and recent cases', () async {
    stubEssentialsSuccess();
    final cubit = DashboardCubit(repo);

    await cubit.loadEssentials();

    expect(cubit.state.summary.valueOrNull, summary);
    expect(cubit.state.recentCases.valueOrNull, isEmpty);
  });

  test('loadEssentials does not touch the deferred sections', () async {
    stubEssentialsSuccess();
    final cubit = DashboardCubit(repo);

    await cubit.loadEssentials();

    expect(
      cubit.state.casesByStage,
      isA<SectionIdle<List<CaseStageCountModel>>>(),
    );
    expect(cubit.state.deferredRequested, isFalse);
    verifyNever(() => repo.getCasesByStage());
  });

  test('one failing section does not blank the others', () async {
    when(
      () => repo.getSummary(),
    ).thenAnswer((_) async => left(ServerFailure('انقطع الاتصال')));
    when(
      () => repo.getRecentCases(),
    ).thenAnswer((_) async => right(<CaseListItemModel>[]));
    final cubit = DashboardCubit(repo);

    await cubit.loadEssentials();

    expect(cubit.state.summary, isA<SectionError<DashboardSummaryModel>>());
    expect((cubit.state.summary as SectionError).message, 'انقطع الاتصال');
    expect(
      cubit.state.recentCases,
      isA<SectionData<List<CaseListItemModel>>>(),
    );
  });

  test('loadDeferred fetches every breakdown once', () async {
    stubDeferredSuccess();
    final cubit = DashboardCubit(repo);

    await cubit.loadDeferred();
    await cubit.loadDeferred();

    expect(cubit.state.deferredRequested, isTrue);
    // The second call is the scroll listener firing again — it must not
    // re-request six endpoints.
    verify(() => repo.getCasesByStage()).called(1);
    verify(() => repo.getTopDoctors()).called(1);
  });

  test('loadDeferred(force: true) re-fetches', () async {
    stubDeferredSuccess();
    final cubit = DashboardCubit(repo);

    await cubit.loadDeferred();
    await cubit.loadDeferred(force: true);

    verify(() => repo.getCasesByStage()).called(2);
  });

  test(
    'refresh leaves the deferred half alone when it was never shown',
    () async {
      stubEssentialsSuccess();
      final cubit = DashboardCubit(repo);

      await cubit.loadEssentials();
      await cubit.refresh();

      verify(() => repo.getSummary()).called(2);
      verifyNever(() => repo.getCasesByStage());
    },
  );

  test('refresh reloads the deferred half once it has been shown', () async {
    stubEssentialsSuccess();
    stubDeferredSuccess();
    final cubit = DashboardCubit(repo);

    await cubit.loadEssentials();
    await cubit.loadDeferred();
    await cubit.refresh();

    verify(() => repo.getSummary()).called(2);
    verify(() => repo.getCasesByStage()).called(2);
  });
}
