import 'dart:developer';

import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_summary_model.dart';

/// The `dashboard` endpoints — split out of
/// [ApiService], reached through the same instance.
extension DashboardApi on ApiService {
  // ---------------------------------------------------------------------
  // Dashboard
  //
  // Eight read-only endpoints, all scoped to the active laboratory by the
  // `X-Laboratory-Id` header the Api interceptor already injects. Each is
  // fetched independently so one slow or failing section cannot blank the
  // whole home screen — see `DashboardCubit`.
  // ---------------------------------------------------------------------


  /// `GET /Dashboard/summary`
  Future<DashboardSummaryModel> getDashboardSummary({String? token}) async {
    log('Fetching dashboard summary');

    final data = await Api().get(url: 'Dashboard/summary', token: token);

    return DashboardSummaryModel.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /Dashboard/cases-by-priority`
  Future<List<CasePriorityCountModel>> getDashboardCasesByPriority({
    String? token,
  }) async {
    log('Fetching dashboard cases by priority');

    final data = await Api().get(
      url: 'Dashboard/cases-by-priority',
      token: token,
    );

    return decodeJsonList(data, CasePriorityCountModel.fromJson);
  }

  /// `GET /Dashboard/cases-by-stage`
  Future<List<CaseStageCountModel>> getDashboardCasesByStage({
    String? token,
  }) async {
    log('Fetching dashboard cases by stage');

    final data = await Api().get(url: 'Dashboard/cases-by-stage', token: token);

    return decodeJsonList(data, CaseStageCountModel.fromJson);
  }

  /// `GET /Dashboard/cases-by-phase` — the funnel that reconciles.
  ///
  /// Unlike the stage counts, every case is in exactly one phase, so this
  /// column sums to the laboratory's total. See [CasePhaseCountModel].
  Future<List<CasePhaseCountModel>> getDashboardCasesByPhase({
    String? token,
  }) async {
    log('Fetching dashboard cases by phase');

    final data = await Api().get(url: 'Dashboard/cases-by-phase', token: token);

    return decodeJsonList(data, CasePhaseCountModel.fromJson);
  }

  /// `GET /Dashboard/case-flow` — arrivals against deliveries, per day.
  Future<List<CaseFlowPointModel>> getDashboardCaseFlow({
    int? days,
    String? token,
  }) async {
    log('Fetching dashboard case flow');

    final data = await Api().get(
      url: 'Dashboard/case-flow${days == null ? '' : '?days=$days'}',
      token: token,
    );

    return decodeJsonList(data, CaseFlowPointModel.fromJson);
  }

  /// `GET /Dashboard/user-case-work` — what each user actually moved.
  Future<List<UserCaseWorkModel>> getDashboardUserCaseWork({
    DateTime? fromDate,
    DateTime? toDate,
    String? token,
  }) async {
    log('Fetching dashboard user case work');

    final params = <String>[
      if (fromDate != null) 'fromDate=${ApiTime.formatDate(fromDate)}',
      if (toDate != null) 'toDate=${ApiTime.formatDate(toDate)}',
    ];

    final data = await Api().get(
      url:
          'Dashboard/user-case-work${params.isEmpty ? '' : '?${params.join('&')}'}',
      token: token,
    );

    return decodeJsonList(data, UserCaseWorkModel.fromJson);
  }

  /// `GET /Dashboard/revenue-by-month`
  Future<List<MonthlyRevenueModel>> getDashboardRevenueByMonth({
    int? months,
    String? token,
  }) async {
    log('Fetching dashboard revenue by month');

    final query = months == null ? '' : '?months=$months';
    final data = await Api().get(
      url: 'Dashboard/revenue-by-month$query',
      token: token,
    );

    return decodeJsonList(data, MonthlyRevenueModel.fromJson);
  }

  /// `GET /Dashboard/recent-cases` — returns a paged result whose rows are the
  /// same `ClinicCaseListItemDto` the cases list uses, so it reuses
  /// [CaseListItemModel] rather than introducing a near-duplicate model.
  Future<List<CaseListItemModel>> getDashboardRecentCases({
    int? count,
    String? token,
  }) async {
    log('Fetching dashboard recent cases');

    final query = count == null ? '' : '?count=$count';
    final data = await Api().get(
      url: 'Dashboard/recent-cases$query',
      token: token,
    );

    final items = data is Map<String, dynamic> ? data['items'] : data;

    return decodeJsonList(items, CaseListItemModel.fromJson);
  }

  /// `GET /Dashboard/top-doctors`
  Future<List<TopDoctorModel>> getDashboardTopDoctors({
    int? count,
    String? token,
  }) async {
    log('Fetching dashboard top doctors');

    final query = count == null ? '' : '?count=$count';
    final data = await Api().get(
      url: 'Dashboard/top-doctors$query',
      token: token,
    );

    return decodeJsonList(data, TopDoctorModel.fromJson);
  }

  /// `GET /Dashboard/upcoming-due-cases`
  Future<List<UpcomingDueCaseModel>> getDashboardUpcomingDueCases({
    int? days,
    String? token,
  }) async {
    log('Fetching dashboard upcoming due cases');

    final query = days == null ? '' : '?days=$days';
    final data = await Api().get(
      url: 'Dashboard/upcoming-due-cases$query',
      token: token,
    );

    return decodeJsonList(data, UpcomingDueCaseModel.fromJson);
  }

  /// `GET /Dashboard/recent-activity`
  Future<List<RecentActivityModel>> getDashboardRecentActivity({
    int? count,
    String? token,
  }) async {
    log('Fetching dashboard recent activity');

    final query = count == null ? '' : '?count=$count';
    final data = await Api().get(
      url: 'Dashboard/recent-activity$query',
      token: token,
    );

    return decodeJsonList(data, RecentActivityModel.fromJson);
  }


}
