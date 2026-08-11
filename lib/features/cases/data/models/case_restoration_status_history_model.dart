import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';

/*
{
  "stageId": "...",
  "stage": { ... },
  "previousStageId": "...",
  "previousStage": { ... },
  "orderNum": 1,
  "changedByName": "أحمد",
  "note": null,
  "changedAt": "2026-08-01T10:12:33.000Z"
}
 */

/// One entry in a restoration's workflow-stage timeline
/// (`ClinicCaseRestorationStatusHistoryDto`) — records each move from one
/// stage to the next, unlike [CaseStatusHistoryModel] which tracks the case's
/// overall status.
class CaseRestorationStatusHistoryModel {
  final String? stageId;
  final CaseWorkflowStageModel? stage;
  final String? previousStageId;
  final CaseWorkflowStageModel? previousStage;
  final int orderNum;
  final String? changedByName;
  final String? note;
  final DateTime? changedAt;

  CaseRestorationStatusHistoryModel({
    this.stageId,
    this.stage,
    this.previousStageId,
    this.previousStage,
    this.orderNum = 0,
    this.changedByName,
    this.note,
    this.changedAt,
  });

  factory CaseRestorationStatusHistoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CaseRestorationStatusHistoryModel(
      stageId: json['stageId'] as String?,
      stage: json['stage'] == null
          ? null
          : CaseWorkflowStageModel.fromJson(
              json['stage'] as Map<String, dynamic>,
            ),
      previousStageId: json['previousStageId'] as String?,
      previousStage: json['previousStage'] == null
          ? null
          : CaseWorkflowStageModel.fromJson(
              json['previousStage'] as Map<String, dynamic>,
            ),
      orderNum: json['orderNum'] as int? ?? 0,
      changedByName: json['changedByName'] as String?,
      note: json['note'] as String?,
      changedAt: json['changedAt'] != null
          ? DateTime.tryParse(json['changedAt'] as String)
          : null,
    );
  }
}
