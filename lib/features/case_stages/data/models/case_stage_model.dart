import 'package:dental_lab_app/features/case_stages/data/models/case_stage_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';

/// One stage in the laboratory's own case workflow (`CaseStatusDto`).
///
/// This replaced a fixed ten-value `CaseStatus` enum: the lab now draws its
/// own flow, names it in its own words, and the app never matches on the text.
/// Behaviour is read off the flags below.
///
/// Not to be confused with two other things called "stage":
/// * `CaseWorkflowStageModel` (features/case_workflow_stages) — a stage of a
///   *restoration type's* route.
/// * `CaseStageInstanceModel` (features/cases) — a live instance of *this*
///   stage on one particular case.
class CaseStageModel {
  /// This VERSION's id — what a case's plan points at, and what a move
  /// posts back. Changes when an edit forks the stage (see
  /// [rootStageId]/[version]): re-read after such a save rather than
  /// patching a held copy in place.
  final String id;
  final String? name;
  final String? nameAr;

  /// Before the restorations run their routes, or after every one of them
  /// finishes. The barrier half is what makes packing and invoicing wait.
  final CaseStageTiming timing;

  /// Where a rejection sends the work — must be a stage of the same pipeline
  /// with a **smaller** `order`. Null means "not declared", and the server
  /// then offers every earlier stage as a rework target rather than refusing.
  final String? sendBackToStageId;

  /// Overrides "the next `order` step" for this stage only — must be a stage
  /// of the same pipeline with a **greater** `order`. Exists because two
  /// stages sharing an `order` run in parallel and would otherwise always
  /// converge on the same follow-up; this is how one branch diverges.
  final String? nextStageId;

  /// THE FLOW. Stages sharing a number run in parallel; the next distinct
  /// number opens once every stage on this one is done.
  final int order;

  /// Out of the building — pauses the turnaround clock.
  final bool isExternal;

  /// Offered rather than always cut onto the case: the case form asks
  /// whether this case wants it, and only the chosen ones are sent.
  final bool isOptional;

  /// A design-token *name* (`success`, `warning`, `destructive`, …), resolved
  /// through `badgeVariantColor`. Never a hex — a stored colour would ignore
  /// the tenant's brand and break in dark mode.
  final String? badgeVariant;

  /// Moving here demands written text; the move sheet must enforce it.
  final bool requiresReason;

  /// The intake fork: whether this stage is cut onto a case taken by
  /// impression, by scanner, or either.
  ///
  /// The same `RouteStageAppliesTo` a restoration stage carries — the case
  /// workflow forks the same way, so a lab that scans skips the impression
  /// stages and vice versa.
  final RouteStageAppliesTo appliesTo;

  final bool isActive;

  /// Who may work the stage. Additive: every member of every listed department
  /// PLUS every listed person. Both empty is legal.
  final List<String> departmentIds;

  /// Named users allowed to work this stage — `userIds` on the wire.
  final List<String> userIds;

  /// People carved out of an assigned department.
  final List<String> excludedUserIds;

  /// How many cases are sitting on this stage right now — the filter sheet
  /// shows it rather than counting a paged list client-side.
  final int caseCount;

  /// The stage's identity across every version of it — stable through
  /// renames, renumberings and retirements. What a history report groups by.
  final String? rootStageId;

  /// 1 for the original, incrementing per fork. Higher is newer.
  final int version;

  /// How many cases are walking this exact version right now — the number a
  /// save should warn with, since anything but zero means the edit forks the
  /// stage instead of landing in place (`ForkIfInUseAsync`).
  final int casesOnThisVersion;

  /// When this version started applying to newly-created cases.
  final DateTime? effectiveFrom;

  /// When the next fork retired this version — null while it is the live
  /// one.
  final DateTime? effectiveTo;

  const CaseStageModel({
    required this.id,
    this.name,
    this.nameAr,
    this.timing = CaseStageTiming.beforeRestorations,
    this.sendBackToStageId,
    this.nextStageId,
    this.order = 0,
    this.isExternal = false,
    this.isOptional = false,
    this.badgeVariant,
    this.requiresReason = false,
    this.appliesTo = RouteStageAppliesTo.any,
    this.isActive = true,
    this.departmentIds = const [],
    this.userIds = const [],
    this.excludedUserIds = const [],
    this.caseCount = 0,
    this.rootStageId,
    this.version = 1,
    this.casesOnThisVersion = 0,
    this.effectiveFrom,
    this.effectiveTo,
  });

  /// Arabic first, English as the fallback. Empty — not a dash — when the lab
  /// wrote neither, so callers can hide the badge instead of showing a
  /// placeholder where a stage name should be.
  String get displayName {
    final ar = nameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return name?.trim() ?? '';
  }

  /// True when this stage is cut onto a case taken in via [method].
  bool appliesToIntake(ImpressionMethod? method) => appliesTo.appliesTo(method);

  static List<String> _ids(dynamic value) =>
      (value as List<dynamic>?)?.map((e) => e as String).toList() ?? const [];

  factory CaseStageModel.fromJson(Map<String, dynamic> json) {
    return CaseStageModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      timing: CaseStageTiming.fromApi(json['timing'] as int?),
      sendBackToStageId: json['sendBackToStageId'] as String?,
      nextStageId: json['nextStageId'] as String?,
      order: json['order'] as int? ?? 0,
      isExternal: json['isExternal'] as bool? ?? false,
      isOptional: json['isOptional'] as bool? ?? false,
      badgeVariant: json['badgeVariant'] as String?,
      requiresReason: json['requiresReason'] as bool? ?? false,
      appliesTo: RouteStageAppliesTo.fromValue(json['appliesTo'] as int?),
      isActive: json['isActive'] as bool? ?? true,
      departmentIds: _ids(json['departmentIds']),
      userIds: _ids(json['userIds']),
      excludedUserIds: _ids(json['excludedUserIds']),
      caseCount: json['caseCount'] as int? ?? 0,
      rootStageId: json['rootStageId'] as String?,
      version: json['version'] as int? ?? 1,
      casesOnThisVersion: json['casesOnThisVersion'] as int? ?? 0,
      effectiveFrom: DateTime.tryParse(json['effectiveFrom'] as String? ?? ''),
      effectiveTo: DateTime.tryParse(json['effectiveTo'] as String? ?? ''),
    );
  }
}
