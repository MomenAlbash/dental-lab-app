/*
{
  "id": "...",
  "laboratoryId": "...",
  "name": "التصميم",
  "order": 1,
  "imagePath": null,
  "isActive": true,
  "isFinal": false,
  "restorationTypeId": "..."
}
 */

/// A workflow stage belonging to a specific restoration type (e.g. "التصميم"
/// → "الطحن" → "التلميع" for a crown). Stages are no longer a
/// laboratory-wide list — every stage is scoped to [restorationTypeId].
class CaseWorkflowStageModel {
  final String id;
  final String? laboratoryId;
  final String? name;
  final int order;
  final String? imagePath;
  final bool isActive;
  final bool isFinal;
  final String? restorationTypeId;

  CaseWorkflowStageModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.order = 0,
    this.imagePath,
    this.isActive = true,
    this.isFinal = false,
    this.restorationTypeId,
  });

  factory CaseWorkflowStageModel.fromJson(Map<String, dynamic> json) {
    return CaseWorkflowStageModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      order: json['order'] as int? ?? 0,
      imagePath: json['imagePath'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isFinal: json['isFinal'] as bool? ?? false,
      restorationTypeId: json['restorationTypeId'] as String?,
    );
  }
}
