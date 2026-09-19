/// Which of the list's lifecycle tabs is selected (`CasePhaseTab`).
///
/// **Four tabs for six phases.** `Received` and `QualityCheck` have no tab of
/// their own: from the front desk both read as "the lab has it and hasn't
/// finished it", which is the question [inProduction] already answers, so they
/// fold into it rather than adding two tabs nobody asked for.
enum CasePhaseTab {
  /// Every case matching the filters, whatever phase it is in.
  all(null, 'الكل', 'الكل'),

  /// Logged, but the material has not arrived yet.
  newCases(1, 'بحاجة لاستلام', 'للاستلام'),
  inProduction(2, 'قيد الإنتاج', 'الإنتاج'),
  ready(3, 'بانتظار التسليم', 'للتسليم'),
  delivered(4, 'المسلّمة', 'مسلّمة');

  const CasePhaseTab(this.value, this.label, this.shortLabel);

  /// Null on [all] — the tab that exists by *not* sending the parameter.
  final int? value;
  final String label;

  /// For the tab strip, where five tiles share a phone's width and the full
  /// label would be ellipsed into something unreadable.
  final String shortLabel;
}

/// The list's SLA segment: one of three date questions, or none.
///
/// Mutually exclusive by construction rather than by rule — the server counts
/// each with its own query and the three filters exclude one another, so a
/// single selection is the honest control.
enum CaseSlaFilter {
  none(null, ''),
  late$('IsLate', 'تخطّت الوقت المتوقع'),
  dueToday('DueToday', 'مستحقة اليوم'),
  noExpectedCompletion('NoExpectedCompletion', 'بلا وقت تنفيذ متوقع');

  const CaseSlaFilter(this.param, this.label);

  /// The boolean query parameter this segment sets to `true`.
  final String? param;
  final String label;
}

/// How many cases sit behind each lifecycle tab
/// (`ClinicCasePhaseCountsDto`), under the same filters the list is showing.
class CasePhaseCountsModel {
  const CasePhaseCountsModel({
    this.all = 0,
    this.newCases = 0,
    this.inProduction = 0,
    this.ready = 0,
    this.delivered = 0,
  });

  static const empty = CasePhaseCountsModel();

  final int all;
  final int newCases;
  final int inProduction;
  final int ready;
  final int delivered;

  /// A badge is shown at zero, never hidden: "no cases waiting to be received"
  /// is an answer, and a tab that disappears at zero reads as broken.
  int countOf(CasePhaseTab tab) => switch (tab) {
    CasePhaseTab.all => all,
    CasePhaseTab.newCases => newCases,
    CasePhaseTab.inProduction => inProduction,
    CasePhaseTab.ready => ready,
    CasePhaseTab.delivered => delivered,
  };

  factory CasePhaseCountsModel.fromJson(Map<String, dynamic> json) {
    return CasePhaseCountsModel(
      all: json['all'] as int? ?? 0,
      newCases: json['new'] as int? ?? 0,
      inProduction: json['inProduction'] as int? ?? 0,
      ready: json['ready'] as int? ?? 0,
      delivered: json['delivered'] as int? ?? 0,
    );
  }
}

/// The three counts behind the SLA segment (`ClinicCaseSlaCountsDto`).
class CaseSlaCountsModel {
  const CaseSlaCountsModel({
    this.late$ = 0,
    this.dueToday = 0,
    this.noExpectedCompletion = 0,
  });

  static const empty = CaseSlaCountsModel();

  /// Past the promised date and still open.
  final int late$;

  /// Promised for today, not yet delivered.
  final int dueToday;

  /// Never given a promised date at all.
  final int noExpectedCompletion;

  int countOf(CaseSlaFilter filter) => switch (filter) {
    CaseSlaFilter.none => 0,
    CaseSlaFilter.late$ => late$,
    CaseSlaFilter.dueToday => dueToday,
    CaseSlaFilter.noExpectedCompletion => noExpectedCompletion,
  };

  factory CaseSlaCountsModel.fromJson(Map<String, dynamic> json) {
    return CaseSlaCountsModel(
      late$: json['late'] as int? ?? 0,
      dueToday: json['dueToday'] as int? ?? 0,
      noExpectedCompletion: json['noExpectedCompletion'] as int? ?? 0,
    );
  }
}

/// The stages the signed-in user may act on right now
/// (`ClinicMyWorkflowAssignmentsDto`).
///
/// The union of being named personally and belonging to a department the stage
/// lists, resolved through the employee's *active* membership — which is why
/// this is asked for rather than derived from the user's own record.
///
/// Deliberately not a list endpoint of its own: the two id lists are handed
/// straight to the case list's existing `StageIds`/`RestorationStageIds`
/// filters, so "my tasks" is the ordinary list with a filter, not a second
/// screen with its own rules.
class MyWorkflowAssignmentsModel {
  const MyWorkflowAssignmentsModel({
    this.caseStageIds = const [],
    this.restorationStageIds = const [],
  });

  static const empty = MyWorkflowAssignmentsModel();

  final List<String> caseStageIds;
  final List<String> restorationStageIds;

  /// Nothing assigned at all — the "my tasks" queue says so instead of showing
  /// every case in the laboratory.
  bool get isEmpty => caseStageIds.isEmpty && restorationStageIds.isEmpty;

  factory MyWorkflowAssignmentsModel.fromJson(Map<String, dynamic> json) {
    List<String> ids(String key) => [
      for (final id in json[key] as List<dynamic>? ?? const [])
        if (id is String) id,
    ];

    return MyWorkflowAssignmentsModel(
      caseStageIds: ids('caseStageIds'),
      restorationStageIds: ids('restorationStageIds'),
    );
  }
}
