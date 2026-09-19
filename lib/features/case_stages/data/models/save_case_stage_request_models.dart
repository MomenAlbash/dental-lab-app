import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_enums.dart';

/// Body of `POST /case-statuses` and `PUT /case-statuses/{id}`
/// (`SaveCaseStatusRequest`).
///
/// Note what is *not* here: transitions. The API carries no edge table at
/// all — `PUT /case-statuses/transitions` answers 404 — so the flow is
/// [order] alone: a case runs the stages of its intake from the lowest one
/// that applies to the highest.
class SaveCaseStageRequestModel {
  const SaveCaseStageRequestModel({
    required this.name,
    this.nameAr,
    this.timing = CaseStageTiming.beforeRestorations,
    this.sendBackToStageId,
    this.nextStageId,
    this.order = 0,
    this.isExternal = false,
    this.isOptional = false,
    this.requiresReason = false,
    this.appliesTo = RouteStageAppliesTo.any,
    this.isActive = true,
    this.badgeVariant,
    this.departmentIds = const [],
    this.userIds = const [],
    this.excludedUserIds = const [],
  }) : assert(name.length > 0, 'A stage must be named.');

  final String name;
  final String? nameAr;

  /// Where a rejection sends the work — a stage of the same pipeline with a
  /// smaller `order`. Null leaves it undeclared, and the server then offers
  /// every earlier stage as a rework target.
  final String? sendBackToStageId;

  /// Forward override — a stage of the same pipeline with a greater `order`.
  /// Null means plain `order` sequencing applies.
  final String? nextStageId;

  /// The production barrier: `beforeRestorations` runs alongside the units,
  /// `afterRestorations` waits until every one of them is finished.
  final CaseStageTiming timing;

  /// THE FLOW — the step this stage occupies. Stages sharing a number run in
  /// parallel; the next distinct number opens only once every stage on this
  /// one is done.
  final int order;

  final bool isExternal;

  /// Offered per case instead of always cut onto it — the case form asks.
  final bool isOptional;

  final bool requiresReason;

  /// The intake fork — impression, scanner, or either.
  final RouteStageAppliesTo appliesTo;

  final bool isActive;

  /// A design-token name, never a hex.
  final String? badgeVariant;

  /// Who may work this stage. Additive — every member of every listed
  /// department PLUS every listed person. A sent-but-empty list means
  /// "nobody"; both empty is legal, since a lab may draw its flow before
  /// filling in an org chart.
  final List<String> departmentIds;

  /// Named users who may work this stage — `userIds` on the wire.
  final List<String> userIds;

  /// People inside a listed department who may *not* work it. The API keeps
  /// this alongside the two additive lists, so a department can be assigned
  /// with one person carved out of it.
  final List<String> excludedUserIds;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    if (nameAr != null && nameAr!.trim().isNotEmpty) 'nameAr': nameAr!.trim(),
    'order': order,
    'timing': timing.apiValue,
    // Sent as an explicit null when cleared: the pair is how a lab draws a
    // rework path and a branch, and omitting the key would read as "leave it
    // alone" — there would be no way to remove one once set.
    'sendBackToStageId': sendBackToStageId,
    'nextStageId': nextStageId,
    'isExternal': isExternal,
    'isOptional': isOptional,
    'requiresReason': requiresReason,
    'appliesTo': appliesTo.value,
    'isActive': isActive,
    if (badgeVariant != null && badgeVariant!.isNotEmpty)
      'badgeVariant': badgeVariant,
    'departmentIds': departmentIds,
    // `userIds`, not `employeeIds`: the field was named after the wrong
    // entity, so assigning a stage to a named person never reached the server
    // at all.
    'userIds': userIds,
    'excludedUserIds': excludedUserIds,
  };
}
