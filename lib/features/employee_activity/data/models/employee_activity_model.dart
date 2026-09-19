import 'package:dental_lab_app/core/helper/api_time_helper.dart';

/// The four kinds of thing the team-activity report counts (`ActivityKind`).
///
/// Every one is an **existing recorded event** — this report reads history, it
/// does not add a new clock. The per-stage work timers are deliberately off,
/// so "how long did this take" is not a question these numbers answer; "how
/// much moved through whom" is.
enum ActivityKind {
  restorationStageMove(1, 'نقل مرحلة تعويض'),
  caseStageMove(2, 'نقل مرحلة طلب'),
  casePhaseMove(3, 'نقل طور طلب'),
  scannerSession(4, 'جلسة سكنر');

  const ActivityKind(this.value, this.label);

  final int value;
  final String label;

  static ActivityKind? fromValue(int? value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}

/// A name and how often it came up (`ActivityCountDto`) — used for the top
/// stages, patients and restoration types on a daily row.
class ActivityCountModel {
  const ActivityCountModel({this.name, this.count = 0});

  final String? name;
  final int count;

  String get displayName {
    final value = name?.trim();
    return (value == null || value.isEmpty) ? '—' : value;
  }

  factory ActivityCountModel.fromJson(Map<String, dynamic> json) {
    return ActivityCountModel(
      name: json['name'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}

/// One employee on one day (`ClinicEmployeeActivityDailyDto`).
class EmployeeActivityDailyModel {
  const EmployeeActivityDailyModel({
    required this.userId,
    this.userName,
    this.userRole,
    this.date,
    this.totalCount = 0,
    this.restorationMoves = 0,
    this.caseMoves = 0,
    this.phaseMoves = 0,
    this.scannerSessions = 0,
    this.returns = 0,
    this.distinctCases = 0,
    this.firstAt,
    this.lastAt,
    this.topStages = const [],
    this.topPatients = const [],
    this.byRestorationType = const [],
  });

  final String userId;
  final String? userName;
  final String? userRole;

  /// The day these figures belong to, as the server grouped it. A count
  /// without the day it covers is not a fact.
  final String? date;

  final int totalCount;
  final int restorationMoves;
  final int caseMoves;
  final int phaseMoves;
  final int scannerSessions;

  /// Moves that sent work **backwards**. Counted separately rather than folded
  /// into the total: rework is not throughput, and a busy day that is mostly
  /// returns is the opposite of a productive one.
  final int returns;

  /// Cases touched, counted once each however many times they were moved — so
  /// this measures how much of the lab's work passed through somebody, not how
  /// often they pressed a button.
  final int distinctCases;

  final DateTime? firstAt;
  final DateTime? lastAt;

  final List<ActivityCountModel> topStages;
  final List<ActivityCountModel> topPatients;
  final List<ActivityCountModel> byRestorationType;

  String get displayName {
    final name = userName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  /// The working span, as first-to-last recorded event.
  ///
  /// **Not hours worked.** It is the distance between two moves, so a single
  /// event gives no span at all and a long gap in the middle is invisible —
  /// attendance is where hours are answered, not here.
  String get spanLabel {
    final first = firstAt;
    final last = lastAt;
    if (first == null || last == null) return '—';

    return '${ApiTime.displayDateTime(first)} → '
        '${ApiTime.displayDateTime(last)}';
  }

  factory EmployeeActivityDailyModel.fromJson(Map<String, dynamic> json) {
    List<ActivityCountModel> counts(String key) => [
      for (final entry in json[key] as List<dynamic>? ?? const [])
        if (entry is Map<String, dynamic>) ActivityCountModel.fromJson(entry),
    ];

    return EmployeeActivityDailyModel(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String?,
      userRole: json['userRole'] as String?,
      date: json['date'] as String?,
      totalCount: json['totalCount'] as int? ?? 0,
      restorationMoves: json['restorationMoves'] as int? ?? 0,
      caseMoves: json['caseMoves'] as int? ?? 0,
      phaseMoves: json['phaseMoves'] as int? ?? 0,
      scannerSessions: json['scannerSessions'] as int? ?? 0,
      returns: json['returns'] as int? ?? 0,
      distinctCases: json['distinctCases'] as int? ?? 0,
      firstAt: DateTime.tryParse(json['firstAt'] as String? ?? ''),
      lastAt: DateTime.tryParse(json['lastAt'] as String? ?? ''),
      topStages: counts('topStages'),
      topPatients: counts('topPatients'),
      byRestorationType: counts('byRestorationType'),
    );
  }
}

/// One employee's share of the period (`ActivityEmployeeCountDto`).
class ActivityEmployeeCountModel {
  const ActivityEmployeeCountModel({
    required this.userId,
    this.name,
    this.count = 0,
  });

  final String userId;
  final String? name;
  final int count;

  String get displayName {
    final value = name?.trim();
    return (value == null || value.isEmpty) ? '—' : value;
  }

  factory ActivityEmployeeCountModel.fromJson(Map<String, dynamic> json) {
    return ActivityEmployeeCountModel(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}

/// One day of the period (`ActivityDayCountDto`).
class ActivityDayCountModel {
  const ActivityDayCountModel({this.date, this.count = 0});

  final String? date;
  final int count;

  factory ActivityDayCountModel.fromJson(Map<String, dynamic> json) {
    return ActivityDayCountModel(
      date: json['date'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}

/// The whole team over a period (`ClinicEmployeeActivitySummaryDto`).
class EmployeeActivitySummaryModel {
  const EmployeeActivitySummaryModel({
    this.totalEvents = 0,
    this.activeEmployees = 0,
    this.casesTouched = 0,
    this.returns = 0,
    this.scannerSessions = 0,
    this.byEmployee = const [],
    this.byStage = const [],
    this.byDay = const [],
  });

  final int totalEvents;

  /// People who moved anything at all in the period — not the headcount. A
  /// team of twenty with four active is the finding, and reporting the roster
  /// size here would hide it.
  final int activeEmployees;

  final int casesTouched;
  final int returns;
  final int scannerSessions;

  final List<ActivityEmployeeCountModel> byEmployee;
  final List<ActivityCountModel> byStage;
  final List<ActivityDayCountModel> byDay;

  /// What share of the period's events were rework, `0.0`–`1.0`.
  ///
  /// Zero events gives zero rather than a divide-by-zero: a quiet period has
  /// no rework problem, it just has nothing in it.
  double get returnRate => totalEvents == 0 ? 0 : returns / totalEvents;

  factory EmployeeActivitySummaryModel.fromJson(Map<String, dynamic> json) {
    return EmployeeActivitySummaryModel(
      totalEvents: json['totalEvents'] as int? ?? 0,
      activeEmployees: json['activeEmployees'] as int? ?? 0,
      casesTouched: json['casesTouched'] as int? ?? 0,
      returns: json['returns'] as int? ?? 0,
      scannerSessions: json['scannerSessions'] as int? ?? 0,
      byEmployee: [
        for (final entry in json['byEmployee'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>)
            ActivityEmployeeCountModel.fromJson(entry),
      ],
      byStage: [
        for (final entry in json['byStage'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>) ActivityCountModel.fromJson(entry),
      ],
      byDay: [
        for (final entry in json['byDay'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>)
            ActivityDayCountModel.fromJson(entry),
      ],
    );
  }
}

/// One recorded event (`ClinicEmployeeActivityTimelineItemDto`).
class ActivityTimelineItemModel {
  const ActivityTimelineItemModel({
    required this.userId,
    this.at,
    this.kind,
    this.userName,
    this.userRole,
    this.caseId,
    this.caseNumber,
    this.restorationLabel,
    this.stageName,
    this.stageNameAr,
    this.fromStageName,
    this.fromStageNameAr,
    this.isReturn = false,
    this.isRejected = false,
    this.attempt = 0,
    this.doctorName,
    this.patientName,
    this.restorationTypeNameAr,
    this.reason,
    this.note,
    this.scannerSessionId,
    this.sessionNumber,
  });

  final DateTime? at;
  final ActivityKind? kind;

  final String userId;
  final String? userName;
  final String? userRole;

  final String? caseId;
  final String? caseNumber;
  final String? restorationLabel;

  final String? stageName;
  final String? stageNameAr;
  final String? fromStageName;
  final String? fromStageNameAr;

  /// Whether this move sent work backwards.
  final bool isReturn;

  /// Whether the stage was rejected rather than merely returned. Separate
  /// because a rejection carries a [reason] someone has to answer for, while a
  /// return can be routine.
  final bool isRejected;

  /// Which pass this is through the same stage. Above one, the work is being
  /// redone — which is what turns a row from a record into a question.
  final int attempt;

  final String? doctorName;
  final String? patientName;
  final String? restorationTypeNameAr;

  final String? reason;
  final String? note;

  final String? scannerSessionId;
  final String? sessionNumber;

  String get displayUser {
    final name = userName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  /// Arabic first, falling back to the internal name.
  String get stageLabel => _label(stageNameAr, stageName);
  String get fromStageLabel => _label(fromStageNameAr, fromStageName);

  static String _label(String? arabic, String? fallback) {
    final ar = arabic?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return fallback?.trim() ?? '';
  }

  /// `من التشطيب ← التلميع`, or just the destination when there is no origin —
  /// the first move into a route has nothing to come from.
  String get moveLabel {
    final to = stageLabel;
    final from = fromStageLabel;
    if (from.isEmpty) return to;
    if (to.isEmpty) return from;
    return '$from ← $to';
  }

  /// Whether the row is worth a second look: rework, a rejection, or a repeat
  /// pass through the same stage.
  bool get needsAttention => isReturn || isRejected || attempt > 1;

  factory ActivityTimelineItemModel.fromJson(Map<String, dynamic> json) {
    return ActivityTimelineItemModel(
      at: DateTime.tryParse(json['at'] as String? ?? ''),
      kind: ActivityKind.fromValue(json['kind'] as int?),
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String?,
      userRole: json['userRole'] as String?,
      caseId: json['caseId'] as String?,
      caseNumber: json['caseNumber'] as String?,
      restorationLabel: json['restorationLabel'] as String?,
      stageName: json['stageName'] as String?,
      stageNameAr: json['stageNameAr'] as String?,
      fromStageName: json['fromStageName'] as String?,
      fromStageNameAr: json['fromStageNameAr'] as String?,
      isReturn: json['isReturn'] as bool? ?? false,
      isRejected: json['isRejected'] as bool? ?? false,
      attempt: json['attempt'] as int? ?? 0,
      doctorName: json['doctorName'] as String?,
      patientName: json['patientName'] as String?,
      restorationTypeNameAr: json['restorationTypeNameAr'] as String?,
      reason: json['reason'] as String?,
      note: json['note'] as String?,
      scannerSessionId: json['scannerSessionId'] as String?,
      sessionNumber: json['sessionNumber'] as String?,
    );
  }
}

/// A page of the timeline (`ClinicEmployeeActivityTimelineDto`).
class ActivityTimelineModel {
  const ActivityTimelineModel({
    this.items = const [],
    this.page = 1,
    this.pageSize = 0,
    this.totalCount = 0,
    this.totalPages = 0,
  });

  final List<ActivityTimelineItemModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory ActivityTimelineModel.fromJson(Map<String, dynamic> json) {
    return ActivityTimelineModel(
      items: [
        for (final entry in json['items'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>)
            ActivityTimelineItemModel.fromJson(entry),
      ],
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

/// The filters every activity endpoint shares
/// (`ClinicEmployeeActivityQuery`).
class EmployeeActivityFiltersModel {
  const EmployeeActivityFiltersModel({
    this.from,
    this.to,
    this.userIds = const [],
    this.kinds = const [],
    this.stageIds = const [],
    this.doctorIds = const [],
    this.caseNumber,
    this.includeReturns = true,
    this.includeRejected = true,
    this.page = 1,
    this.pageSize = 50,
  });

  final DateTime? from;
  final DateTime? to;
  final List<String> userIds;
  final List<ActivityKind> kinds;
  final List<String> stageIds;
  final List<String> doctorIds;
  final String? caseNumber;

  /// Both default to **true**: the report is read to find rework as often as
  /// to count throughput, and quietly hiding returns would make a struggling
  /// week look like a good one.
  final bool includeReturns;
  final bool includeRejected;

  final int page;
  final int pageSize;

  static const empty = EmployeeActivityFiltersModel();

  bool get hasAnyFilter =>
      from != null ||
      to != null ||
      userIds.isNotEmpty ||
      kinds.isNotEmpty ||
      stageIds.isNotEmpty ||
      doctorIds.isNotEmpty ||
      (caseNumber?.isNotEmpty ?? false) ||
      !includeReturns ||
      !includeRejected;

  EmployeeActivityFiltersModel copyWith({
    DateTime? from,
    DateTime? to,
    List<String>? userIds,
    List<ActivityKind>? kinds,
    List<String>? stageIds,
    List<String>? doctorIds,
    String? caseNumber,
    bool? includeReturns,
    bool? includeRejected,
    int? page,
    int? pageSize,
  }) => EmployeeActivityFiltersModel(
    from: from ?? this.from,
    to: to ?? this.to,
    userIds: userIds ?? this.userIds,
    kinds: kinds ?? this.kinds,
    stageIds: stageIds ?? this.stageIds,
    doctorIds: doctorIds ?? this.doctorIds,
    caseNumber: caseNumber ?? this.caseNumber,
    includeReturns: includeReturns ?? this.includeReturns,
    includeRejected: includeRejected ?? this.includeRejected,
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
  );

  /// The query string these filters make, `?`-prefixed, or empty.
  ///
  /// Repeated keys for the list filters (`UserIds=a&UserIds=b`) — the shape
  /// ASP.NET's binder reads. A comma-joined single value binds as one id whose
  /// name happens to contain commas, and silently matches nothing.
  String toQuery() {
    final parts = <String>[];

    void add(String key, String value) =>
        parts.add('$key=${Uri.encodeQueryComponent(value)}');

    if (from != null) add('From', from!.toIso8601String());
    if (to != null) add('To', to!.toIso8601String());
    for (final id in userIds) {
      add('UserIds', id);
    }
    for (final kind in kinds) {
      add('Kinds', '${kind.value}');
    }
    for (final id in stageIds) {
      add('StageIds', id);
    }
    for (final id in doctorIds) {
      add('DoctorIds', id);
    }
    if (caseNumber?.isNotEmpty ?? false) add('CaseNumber', caseNumber!);
    if (!includeReturns) add('IncludeReturns', 'false');
    if (!includeRejected) add('IncludeRejected', 'false');
    add('Page', '$page');
    add('PageSize', '$pageSize');

    return '?${parts.join('&')}';
  }
}
