import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';

/// Picks the Arabic name when the server sent one, the English name
/// otherwise, and an empty string when it sent neither.
///
/// Every dashboard DTO that names a lookup entity carries the pair, exactly
/// like `CaseStageSummary.label` and `CaseListItemModel.priorityLabel` do for
/// the cases screens. Returning `''` rather than a placeholder is deliberate:
/// callers hide the row instead of showing an invented name.
String pickLocalizedName(String? nameAr, String? name) {
  final ar = nameAr?.trim();
  if (ar != null && ar.isNotEmpty) return ar;
  return name?.trim() ?? '';
}

/// How many cases sit under one priority (`CasePriorityCountDto`).
class CasePriorityCountModel {
  const CasePriorityCountModel({
    required this.priorityId,
    this.priorityName,
    this.priorityNameAr,
    this.count = 0,
  });

  final String priorityId;
  final String? priorityName;
  final String? priorityNameAr;
  final int count;

  String get label => pickLocalizedName(priorityNameAr, priorityName);

  factory CasePriorityCountModel.fromJson(Map<String, dynamic> json) {
    return CasePriorityCountModel(
      priorityId: json['priorityId'] as String? ?? '',
      priorityName: json['priorityName'] as String?,
      priorityNameAr: json['priorityNameAr'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}

/// How many cases sit at one workflow stage (`CaseStageCountDto`).
class CaseStageCountModel {
  const CaseStageCountModel({
    required this.stageId,
    this.stageName,
    this.stageNameAr,
    this.categoryId,
    this.categoryName,
    this.categoryNameAr,
    this.badgeVariant,
    this.count = 0,
  });

  final String stageId;
  final String? stageName;
  final String? stageNameAr;
  final String? categoryId;
  final String? categoryName;
  final String? categoryNameAr;

  /// Server-chosen colour name, resolved through `badgeVariantColor` — the
  /// same token set the priorities and case rows already paint with.
  final String? badgeVariant;

  final int count;

  String get label => pickLocalizedName(stageNameAr, stageName);
  String get categoryLabel => pickLocalizedName(categoryNameAr, categoryName);

  factory CaseStageCountModel.fromJson(Map<String, dynamic> json) {
    return CaseStageCountModel(
      stageId: json['stageId'] as String? ?? '',
      stageName: json['stageName'] as String?,
      stageNameAr: json['stageNameAr'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      categoryNameAr: json['categoryNameAr'] as String?,
      badgeVariant: json['badgeVariant'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }
}

/// Revenue for one month (`MonthlyRevenueDto`).
class MonthlyRevenueModel {
  const MonthlyRevenueModel({required this.month, this.revenue = 0});

  /// First day of the month the figure covers. Null when the server sent a
  /// value that will not parse — the point is dropped rather than charted at
  /// the epoch.
  final DateTime? month;

  /// Unitless on purpose: the endpoint sends no currency, so the UI labels
  /// this with the laboratory's currency rather than assuming one here.
  final double revenue;

  factory MonthlyRevenueModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueModel(
      month: DateTime.tryParse(json['month'] as String? ?? ''),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A doctor ranked by case volume (`TopDoctorDto`).
class TopDoctorModel {
  const TopDoctorModel({
    required this.doctorId,
    this.name,
    this.imagePath,
    this.caseCount = 0,
  });

  final String doctorId;
  final String? name;
  final String? imagePath;
  final int caseCount;

  factory TopDoctorModel.fromJson(Map<String, dynamic> json) {
    return TopDoctorModel(
      doctorId: json['doctorId'] as String? ?? '',
      name: json['name'] as String?,
      imagePath: json['imagePath'] as String?,
      caseCount: json['caseCount'] as int? ?? 0,
    );
  }
}

/// A case falling due soon (`UpcomingDueCaseDto`).
class UpcomingDueCaseModel {
  const UpcomingDueCaseModel({
    required this.id,
    this.caseNumber,
    this.doctorName,
    this.stageId,
    this.stageName,
    this.stageNameAr,
    this.expectedCompletionAt,
  });

  final String id;
  final String? caseNumber;
  final String? doctorName;
  final String? stageId;
  final String? stageName;
  final String? stageNameAr;
  final DateTime? expectedCompletionAt;

  String get stageLabel => pickLocalizedName(stageNameAr, stageName);

  /// Whole days until the case is due — negative once it is overdue. Both
  /// sides are compared at day granularity so a case due later today does not
  /// count as a day away.
  int? daysUntilDue({DateTime? now}) {
    final due = expectedCompletionAt;
    if (due == null) return null;
    final today = now ?? DateTime.now();
    final dueDay = DateTime(due.year, due.month, due.day);
    final nowDay = DateTime(today.year, today.month, today.day);
    return dueDay.difference(nowDay).inDays;
  }

  factory UpcomingDueCaseModel.fromJson(Map<String, dynamic> json) {
    return UpcomingDueCaseModel(
      id: json['id'] as String? ?? '',
      caseNumber: json['caseNumber'] as String?,
      doctorName: json['doctorName'] as String?,
      stageId: json['stageId'] as String?,
      stageName: json['stageName'] as String?,
      stageNameAr: json['stageNameAr'] as String?,
      expectedCompletionAt: DateTime.tryParse(
        json['expectedCompletionAt'] as String? ?? '',
      ),
    );
  }
}

/// One stage move in the laboratory's recent history (`RecentActivityDto`).
class RecentActivityModel {
  const RecentActivityModel({
    required this.caseId,
    this.caseNumber,
    this.changedByName,
    this.previousStageName,
    this.stageName,
    this.stageId,
    this.isReturn = false,
    this.changedAt,
    this.reason,
    this.note,
  });

  final String caseId;
  final String? caseNumber;
  final String? changedByName;
  final String? previousStageName;
  final String? stageName;
  final String? stageId;

  /// True when the case moved *backwards* — sent back for rework rather than
  /// advanced. The one field on this DTO that changes what the row means, so
  /// the UI marks it rather than rendering every entry identically.
  final bool isReturn;

  final DateTime? changedAt;
  final String? reason;
  final String? note;

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      caseId: json['caseId'] as String? ?? '',
      caseNumber: json['caseNumber'] as String?,
      changedByName: json['changedByName'] as String?,
      previousStageName: json['previousStageName'] as String?,
      stageName: json['stageName'] as String?,
      stageId: json['stageId'] as String?,
      isReturn: json['isReturn'] as bool? ?? false,
      changedAt: DateTime.tryParse(json['changedAt'] as String? ?? ''),
      reason: json['reason'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// How many cases sit in one lifecycle phase (`CasePhaseCountDto`).
///
/// **This is the funnel that reconciles.** The stage counts only describe
/// cases inside `InProduction` — every other phase is a checkpoint with no
/// stage row behind it — and a case in production can hold several stages at
/// once, so those counts do not add up to a number of cases at all. Every case
/// is in exactly one phase, so this column sums to the laboratory's total.
class CasePhaseCountModel {
  const CasePhaseCountModel({
    this.phase,
    this.count = 0,
    this.overdueCount = 0,
  });

  final CasePhase? phase;
  final int count;

  /// Of those, how many are past their promised date. Undelivered phases only
  /// — `Delivered` is terminal and cannot be late any more.
  final int overdueCount;

  String get label => phase?.label ?? '—';

  factory CasePhaseCountModel.fromJson(Map<String, dynamic> json) {
    return CasePhaseCountModel(
      phase: CasePhase.fromValue(json['phase'] as int?),
      count: json['count'] as int? ?? 0,
      overdueCount: json['overdueCount'] as int? ?? 0,
    );
  }
}

/// One day of intake against output (`CaseFlowPointDto`).
///
/// The two series are the point: a count of new cases on its own says how busy
/// the front desk was; put against deliveries it says whether the laboratory
/// is keeping up — which is the question a backlog answers. Quiet days come
/// back as zeroes so the axis stays constant.
class CaseFlowPointModel {
  const CaseFlowPointModel({this.date, this.created = 0, this.delivered = 0});

  final DateTime? date;
  final int created;
  final int delivered;

  /// Positive when more arrived than left that day — the backlog grew.
  int get net => created - delivered;

  factory CaseFlowPointModel.fromJson(Map<String, dynamic> json) {
    return CaseFlowPointModel(
      date: ApiTime.parseDate(json['date'] as String?),
      created: json['created'] as int? ?? 0,
      delivered: json['delivered'] as int? ?? 0,
    );
  }
}

/// What one user actually moved (`UserCaseWorkStatisticsDto`).
///
/// Attributed from real stage-to-stage transitions, and a case counts **once
/// per user** however many times they touched it — so this measures how much
/// of the laboratory's work passed through somebody, not how often they
/// pressed a button.
class UserCaseWorkModel {
  const UserCaseWorkModel({
    required this.userId,
    this.employeeId,
    this.userName,
    this.casesWorked = 0,
    this.transitionCount = 0,
    this.lastWorkedAt,
  });

  final String userId;
  final String? employeeId;
  final String? userName;

  /// Distinct cases this user moved.
  final int casesWorked;

  /// Individual moves — higher than [casesWorked] whenever somebody carried a
  /// case through several stages.
  final int transitionCount;

  final DateTime? lastWorkedAt;

  factory UserCaseWorkModel.fromJson(Map<String, dynamic> json) {
    return UserCaseWorkModel(
      userId: json['userId'] as String? ?? '',
      employeeId: json['employeeId'] as String?,
      userName: json['userName'] as String?,
      casesWorked: json['casesWorked'] as int? ?? 0,
      transitionCount: json['transitionCount'] as int? ?? 0,
      lastWorkedAt: DateTime.tryParse(json['lastWorkedAt'] as String? ?? ''),
    );
  }
}
