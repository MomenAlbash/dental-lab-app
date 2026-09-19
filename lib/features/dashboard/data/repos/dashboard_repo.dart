import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:dio/dio.dart';

/// Reads for the home dashboard.
///
/// Nothing here is cached for offline use. Every figure on this screen is a
/// live count or a "recent"/"upcoming" window, and a stale one is worse than
/// an honest error — a doctor reading yesterday's overdue list would act on
/// it. The list screens cache precisely because a stale case row still tells
/// you what that case is.
class DashboardRepo {
  DashboardRepo(this._apiService);

  final ApiService _apiService;

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  /// Runs [request] and maps whatever it throws onto a [Failure], so each
  /// section of the dashboard fails on its own instead of one bad response
  /// taking the screen down. [what] only ever reaches the log.
  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() request,
  ) async {
    try {
      return right(await request());
    } on DioException catch (e) {
      log('DioException while fetching $what: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching $what: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, DashboardSummaryModel>> getSummary() => _guard(
    'dashboard summary',
    () => _apiService.getDashboardSummary(token: _token),
  );

  Future<Either<Failure, List<CaseListItemModel>>> getRecentCases({
    int count = 5,
  }) => _guard(
    'dashboard recent cases',
    () => _apiService.getDashboardRecentCases(count: count, token: _token),
  );

  Future<Either<Failure, List<CaseStageCountModel>>> getCasesByStage() =>
      _guard(
        'dashboard cases by stage',
        () => _apiService.getDashboardCasesByStage(token: _token),
      );

  Future<Either<Failure, List<CasePriorityCountModel>>> getCasesByPriority() =>
      _guard(
        'dashboard cases by priority',
        () => _apiService.getDashboardCasesByPriority(token: _token),
      );

  Future<Either<Failure, List<UpcomingDueCaseModel>>> getUpcomingDueCases({
    int days = 7,
  }) => _guard(
    'dashboard upcoming due cases',
    () => _apiService.getDashboardUpcomingDueCases(days: days, token: _token),
  );

  Future<Either<Failure, List<TopDoctorModel>>> getTopDoctors({
    int count = 5,
  }) => _guard(
    'dashboard top doctors',
    () => _apiService.getDashboardTopDoctors(count: count, token: _token),
  );

  Future<Either<Failure, List<MonthlyRevenueModel>>> getRevenueByMonth({
    int months = 6,
  }) => _guard(
    'dashboard revenue by month',
    () => _apiService.getDashboardRevenueByMonth(months: months, token: _token),
  );

  Future<Either<Failure, List<RecentActivityModel>>> getRecentActivity({
    int count = 8,
  }) => _guard(
    'dashboard recent activity',
    () => _apiService.getDashboardRecentActivity(count: count, token: _token),
  );

  /// The lifecycle funnel — the one breakdown that sums to the total.
  Future<Either<Failure, List<CasePhaseCountModel>>> getCasesByPhase() =>
      _guard(
        'dashboard cases by phase',
        () => _apiService.getDashboardCasesByPhase(token: _token),
      );

  /// Arrivals against deliveries — whether the laboratory is keeping up.
  Future<Either<Failure, List<CaseFlowPointModel>>> getCaseFlow({
    int days = 14,
  }) => _guard(
    'dashboard case flow',
    () => _apiService.getDashboardCaseFlow(days: days, token: _token),
  );

  /// What each user actually moved, from real stage transitions.
  Future<Either<Failure, List<UserCaseWorkModel>>> getUserCaseWork({
    DateTime? fromDate,
    DateTime? toDate,
  }) => _guard(
    'dashboard user case work',
    () => _apiService.getDashboardUserCaseWork(
      fromDate: fromDate,
      toDate: toDate,
      token: _token,
    ),
  );
}
