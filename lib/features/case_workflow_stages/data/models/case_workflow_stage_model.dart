import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';

/// A department or person attached to a stage (`StageAssigneeDto`).
class StageAssigneeModel {
  const StageAssigneeModel({
    required this.id,
    this.name,
    this.nameAr,
    this.isPrimary = false,
  });

  final String id;
  final String? name;
  final String? nameAr;

  /// The first entry — a presentation hint for compact rows, granting nothing
  /// the others do not.
  final bool isPrimary;

  String get label {
    final ar = nameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return name?.trim() ?? '';
  }

  factory StageAssigneeModel.fromJson(Map<String, dynamic> json) {
    return StageAssigneeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

/// One stage of a **restoration type's** route (`ClinicCaseWorkflowStageDto`).
///
/// Not to be confused with `CaseStageModel`, which is a stage of the *case's*
/// own workflow. The difference matters: only this one carries the manufactur-
/// ing concerns — a checkpoint that may reject, and the intake gate that
/// decides whether the stage is cut onto a given case at all
/// ([appliesTo] — a route carries a traditional head and a digital head, and
/// the server prunes the one that does not apply).
///
/// Expected duration lives on the restoration *type* now, one row per
/// priority level (`ClinicRestorationTypeDto.durations`) — not here. A stage
/// used to carry its own per-priority durations; the API dropped that column
/// along with `isStart`/`isFinal`/`joinMode`/`assigneePolicy`/
/// `requiredOptionId` — none of them exist on the live DTO any more.
class CaseWorkflowStageModel {
  const CaseWorkflowStageModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.nameAr,
    this.key,
    this.order = 0,
    this.imagePath,
    this.isActive = true,
    this.isCheckpoint = false,
    this.isExternal = false,
    this.isOptional = false,
    this.sendBackToStageId,
    this.nextStageId,
    this.appliesTo = RouteStageAppliesTo.any,
    this.departments = const [],
    this.users = const [],
    this.excludedUsers = const [],
    this.restorationTypeId,
    this.rootStageId,
    this.version = 1,
    this.effectiveFrom,
    this.effectiveTo,
    this.restorationCount = 0,
    this.restorationsOnThisVersion = 0,
  });

  final String id;
  final String? laboratoryId;
  final String? name;
  final String? nameAr;

  /// The lab's own stable handle for the stage, used by failure reasons to
  /// name a default send-back target.
  final String? key;

  final int order;
  final String? imagePath;
  final bool isActive;

  /// May reject: failing it needs a coded reason and a send-back target.
  final bool isCheckpoint;

  /// Out of the building — pauses the turnaround clock.
  final bool isExternal;

  /// The try-in switch: true means this stage is cut only onto a restoration
  /// that opted into it at case creation; false means every restoration that
  /// reaches it.
  final bool isOptional;

  /// Where a rejection sends the unit — same route and pipeline, smaller
  /// `order`. Null means undeclared, and the server then offers every earlier
  /// stage as a rework target.
  final String? sendBackToStageId;

  /// Forward override for this stage only — same route and pipeline, greater
  /// `order`. Null means plain `order` sequencing applies.
  final String? nextStageId;

  /// Which intake this stage is cut for.
  final RouteStageAppliesTo appliesTo;

  /// Who may work it. **Additive**: every member of every listed department
  /// PLUS every listed person. Both empty is legal — a lab may draw its flow
  /// before filling in an org chart.
  final List<StageAssigneeModel> departments;

  /// Named users allowed to work the stage — `users` on the wire.
  final List<StageAssigneeModel> users;

  /// People carved out of an assigned department.
  final List<StageAssigneeModel> excludedUsers;

  final String? restorationTypeId;

  /// The stage's identity across every version of it — stable through
  /// renames, renumberings and retirements. What a history report groups by.
  final String? rootStageId;

  /// 1 for a stage nobody has edited since it was declared, incrementing by
  /// one on every fork. Higher is newer.
  final int version;

  /// When this version started applying to newly-cut restorations.
  final DateTime? effectiveFrom;

  /// When this version was retired by the next fork — null while it is still
  /// the active one.
  final DateTime? effectiveTo;

  /// How many restorations are sitting on this stage right now — the figure
  /// worth knowing before retiring a stage, since it is the work that would
  /// be stranded.
  final int restorationCount;

  /// How many restorations have this version anywhere in their plan —
  /// walking it, not standing on it. Non-zero here is what an edit forks away
  /// from instead of updating in place.
  final int restorationsOnThisVersion;

  String get displayName {
    final ar = nameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return name?.trim() ?? '';
  }

  /// True when this stage is cut onto a case taken in via [method].
  bool appliesToIntake(ImpressionMethod? method) => appliesTo.appliesTo(method);

  static List<StageAssigneeModel> _assignees(dynamic value) =>
      (value as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(StageAssigneeModel.fromJson)
          .toList() ??
      const [];

  factory CaseWorkflowStageModel.fromJson(Map<String, dynamic> json) {
    return CaseWorkflowStageModel(
      id: json['id'] as String? ?? '',
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      key: json['key'] as String?,
      order: json['order'] as int? ?? 0,
      imagePath: json['imagePath'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isCheckpoint: json['isCheckpoint'] as bool? ?? false,
      isExternal: json['isExternal'] as bool? ?? false,
      isOptional: json['isOptional'] as bool? ?? false,
      sendBackToStageId: json['sendBackToStageId'] as String?,
      nextStageId: json['nextStageId'] as String?,
      appliesTo: RouteStageAppliesTo.fromValue(json['appliesTo'] as int?),
      departments: _assignees(json['departments']),
      users: _assignees(json['users']),
      excludedUsers: _assignees(json['excludedUsers']),
      restorationTypeId: json['restorationTypeId'] as String?,
      rootStageId: json['rootStageId'] as String?,
      version: json['version'] as int? ?? 1,
      effectiveFrom: DateTime.tryParse(json['effectiveFrom'] as String? ?? ''),
      effectiveTo: DateTime.tryParse(json['effectiveTo'] as String? ?? ''),
      restorationCount: json['restorationCount'] as int? ?? 0,
      restorationsOnThisVersion: json['restorationsOnThisVersion'] as int? ?? 0,
    );
  }
}
