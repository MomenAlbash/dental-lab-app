import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_summary_model.dart';

/// One independently-loaded slice of the dashboard.
///
/// The screen is eight separate requests, so a single screen-wide
/// loading/loaded/error triple would mean the slowest one holds up everything
/// and the one that fails blanks the rest. Each section carries its own state
/// instead, and the UI renders whatever has arrived.
sealed class DashboardSection<T> {
  const DashboardSection();

  /// The value if this section has loaded, otherwise null — lets a widget ask
  /// "do I have data" without a pattern match when it does not care why.
  T? get valueOrNull => switch (this) {
    SectionData<T>(:final value) => value,
    _ => null,
  };
}

/// Not requested yet. Deferred sections sit here until the user scrolls to
/// them.
class SectionIdle<T> extends DashboardSection<T> {
  const SectionIdle();
}

class SectionLoading<T> extends DashboardSection<T> {
  const SectionLoading();
}

class SectionData<T> extends DashboardSection<T> {
  const SectionData(this.value);
  final T value;
}

class SectionError<T> extends DashboardSection<T> {
  const SectionError(this.message);
  final String message;
}

/// The whole dashboard: one section per endpoint.
class DashboardState {
  const DashboardState({
    this.summary = const SectionIdle(),
    this.recentCases = const SectionIdle(),
    this.casesByStage = const SectionIdle(),
    this.casesByPhase = const SectionIdle(),
    this.caseFlow = const SectionIdle(),
    this.userCaseWork = const SectionIdle(),
    this.casesByPriority = const SectionIdle(),
    this.upcomingDueCases = const SectionIdle(),
    this.topDoctors = const SectionIdle(),
    this.revenueByMonth = const SectionIdle(),
    this.recentActivity = const SectionIdle(),
  });

  /// Loaded as soon as the screen opens — the counters and the recent cases
  /// are what the user came for.
  final DashboardSection<DashboardSummaryModel> summary;
  final DashboardSection<List<CaseListItemModel>> recentCases;

  /// Loaded on demand, once the user scrolls far enough to want them.
  final DashboardSection<List<CaseStageCountModel>> casesByStage;

  /// The lifecycle funnel. Kept beside [casesByStage] rather than replacing
  /// it: the stage chart describes cases inside production, this one every
  /// case in the laboratory, and only this one sums to the total.
  final DashboardSection<List<CasePhaseCountModel>> casesByPhase;

  /// Arrivals against deliveries — whether the lab is keeping up.
  final DashboardSection<List<CaseFlowPointModel>> caseFlow;

  /// What each user actually moved this period.
  final DashboardSection<List<UserCaseWorkModel>> userCaseWork;
  final DashboardSection<List<CasePriorityCountModel>> casesByPriority;
  final DashboardSection<List<UpcomingDueCaseModel>> upcomingDueCases;
  final DashboardSection<List<TopDoctorModel>> topDoctors;
  final DashboardSection<List<MonthlyRevenueModel>> revenueByMonth;
  final DashboardSection<List<RecentActivityModel>> recentActivity;

  /// True once the deferred half has been asked for, so scrolling back and
  /// forth does not refire six requests.
  bool get deferredRequested => casesByStage is! SectionIdle;

  DashboardState copyWith({
    DashboardSection<DashboardSummaryModel>? summary,
    DashboardSection<List<CaseListItemModel>>? recentCases,
    DashboardSection<List<CaseStageCountModel>>? casesByStage,
    DashboardSection<List<CasePhaseCountModel>>? casesByPhase,
    DashboardSection<List<CaseFlowPointModel>>? caseFlow,
    DashboardSection<List<UserCaseWorkModel>>? userCaseWork,
    DashboardSection<List<CasePriorityCountModel>>? casesByPriority,
    DashboardSection<List<UpcomingDueCaseModel>>? upcomingDueCases,
    DashboardSection<List<TopDoctorModel>>? topDoctors,
    DashboardSection<List<MonthlyRevenueModel>>? revenueByMonth,
    DashboardSection<List<RecentActivityModel>>? recentActivity,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      recentCases: recentCases ?? this.recentCases,
      casesByStage: casesByStage ?? this.casesByStage,
      casesByPhase: casesByPhase ?? this.casesByPhase,
      caseFlow: caseFlow ?? this.caseFlow,
      userCaseWork: userCaseWork ?? this.userCaseWork,
      casesByPriority: casesByPriority ?? this.casesByPriority,
      upcomingDueCases: upcomingDueCases ?? this.upcomingDueCases,
      topDoctors: topDoctors ?? this.topDoctors,
      revenueByMonth: revenueByMonth ?? this.revenueByMonth,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }
}
