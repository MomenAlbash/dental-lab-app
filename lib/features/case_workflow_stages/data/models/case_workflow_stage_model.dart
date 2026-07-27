/*
{
  "id": "...",
  "laboratoryId": "...",
  "name": "التصميم",
  "order": 1,
  "isActive": true,
  "isFinal": false
}
 */

class CaseWorkflowStageModel {
  final String id;
  final String? laboratoryId;
  final String? name;
  final int order;
  final bool isActive;
  final bool isFinal;

  CaseWorkflowStageModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.order = 0,
    this.isActive = true,
    this.isFinal = false,
  });

  factory CaseWorkflowStageModel.fromJson(Map<String, dynamic> json) {
    return CaseWorkflowStageModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isFinal: json['isFinal'] as bool? ?? false,
    );
  }
}
