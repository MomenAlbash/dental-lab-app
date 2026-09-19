import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';

/// Body of `POST /restoration-type-stages`
/// (`ClinicCreateCaseWorkflowStageRequest`).
///
/// A restoration stage always belongs to a restoration type — a route is drawn
/// per type, so [restorationTypeId] is required by the API and by this model.
///
/// Note what is not here: `isStart`, `isFinal`, `joinMode`, `assigneePolicy`,
/// `defaultAssigneeUserId`, `requiredOptionId` and per-stage `durations`. None
/// of them exist on the live request — a route is ordered by [order] alone,
/// duration estimates moved to the restoration type
/// (`SaveRestorationTypeRequest.durations`), and a plain [isOptional] replaced
/// the option gate.
class CreateWorkflowStageRequestModel {
  const CreateWorkflowStageRequestModel({
    required this.name,
    required this.restorationTypeId,
    this.nameAr,
    this.key,
    this.order = 0,
    this.isCheckpoint = false,
    this.isExternal = false,
    this.isOptional = false,
    this.sendBackToStageId,
    this.nextStageId,
    this.appliesTo = RouteStageAppliesTo.any,
    this.departmentIds = const [],
    this.userIds = const [],
    this.excludedUserIds = const [],
  }) : assert(name.length > 0, 'A stage must be named.'),
       assert(
         restorationTypeId.length > 0,
         'A restoration stage belongs to a restoration type.',
       );

  final String name;
  final String restorationTypeId;
  final String? nameAr;

  /// The lab's stable handle, referenced by failure reasons naming a default
  /// send-back target.
  final String? key;

  final int order;

  /// May reject — failing it needs a coded reason and a send-back target.
  final bool isCheckpoint;

  final bool isExternal;

  /// Offered per case instead of always cut onto the route — the case form
  /// asks about it and sends the chosen ones as `selectedStageIds`.
  final bool isOptional;

  /// Where a rejection sends the unit — smaller `order`, same pipeline.
  final String? sendBackToStageId;

  /// Forward override — greater `order`, same pipeline.
  final String? nextStageId;

  /// The intake fork: which of the route's two heads this stage belongs to.
  final RouteStageAppliesTo appliesTo;

  /// Additive pools — every member of every listed department PLUS every
  /// listed person.
  final List<String> departmentIds;

  /// Named users allowed to work the stage — `userIds` on the wire.
  final List<String> userIds;

  /// People carved out of an assigned department.
  final List<String> excludedUserIds;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'restorationTypeId': restorationTypeId,
    if (nameAr != null && nameAr!.trim().isNotEmpty) 'nameAr': nameAr!.trim(),
    if (key != null && key!.trim().isNotEmpty) 'key': key!.trim(),
    'order': order,
    'isCheckpoint': isCheckpoint,
    'isExternal': isExternal,
    'isOptional': isOptional,
    'appliesTo': appliesTo.value,
    // The two declared exceptions to plain `order` sequencing. Sent as an
    // explicit null so a link the lab drew can be removed again.
    'sendBackToStageId': sendBackToStageId,
    'nextStageId': nextStageId,
    'departmentIds': departmentIds,
    // `userIds`, not `employeeIds` — the old key matched no field, so
    // assigning a stage to a named person never left the app.
    'userIds': userIds,
    'excludedUserIds': excludedUserIds,
  };
}

/// Body of `PUT /restoration-type-stages/{id}`
/// (`ClinicUpdateCaseWorkflowStageRequest`).
///
/// Partial update — every field is nullable and an omitted field means "leave
/// it alone". [clearSendBackTo]/[clearNextStage] exist because a plain `null`
/// cannot tell "not sent" apart from "remove the one that is there".
class UpdateWorkflowStageRequestModel {
  const UpdateWorkflowStageRequestModel({
    this.name,
    this.nameAr,
    this.key,
    this.order,
    this.isActive,
    this.isCheckpoint,
    this.isExternal,
    this.isOptional,
    this.sendBackToStageId,
    this.clearSendBackTo = false,
    this.nextStageId,
    this.clearNextStage = false,
    this.appliesTo,
    this.departmentIds,
    this.userIds,
    this.excludedUserIds,
  });

  final String? name;
  final String? nameAr;
  final String? key;
  final int? order;
  final bool? isActive;
  final bool? isCheckpoint;
  final bool? isExternal;
  final bool? isOptional;

  /// Where a rejection sends the unit — smaller `order`, same pipeline.
  final String? sendBackToStageId;

  /// Removes the rework target, so the server offers every earlier stage
  /// again. Omission means "leave alone" on this endpoint, so removing one
  /// needs saying.
  final bool clearSendBackTo;

  /// Forward override — greater `order`, same pipeline.
  final String? nextStageId;

  /// Removes the forward override, so plain `order` sequencing applies again.
  final bool clearNextStage;

  final RouteStageAppliesTo? appliesTo;

  /// Null leaves the pool alone; a sent-but-empty list means "nobody".
  final List<String>? departmentIds;
  final List<String>? userIds;
  final List<String>? excludedUserIds;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name!.trim(),
    if (nameAr != null) 'nameAr': nameAr!.trim(),
    if (key != null) 'key': key!.trim(),
    if (order != null) 'order': order,
    if (isActive != null) 'isActive': isActive,
    if (isCheckpoint != null) 'isCheckpoint': isCheckpoint,
    if (isExternal != null) 'isExternal': isExternal,
    if (isOptional != null) 'isOptional': isOptional,
    if (appliesTo != null) 'appliesTo': appliesTo!.value,
    if (sendBackToStageId != null) 'sendBackToStageId': sendBackToStageId,
    'clearSendBackTo': clearSendBackTo,
    if (nextStageId != null) 'nextStageId': nextStageId,
    'clearNextStage': clearNextStage,
    if (departmentIds != null) 'departmentIds': departmentIds,
    if (userIds != null) 'userIds': userIds,
    if (excludedUserIds != null) 'excludedUserIds': excludedUserIds,
  };
}
