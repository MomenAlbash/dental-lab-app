import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';

/*
{
  "id": "...",
  "laboratoryId": "...",
  "name": "Zircon Crown",
  "nameAr": "تاج زيركون",
  "description": "...",
  "transparency": 0.5,
  "defaultPrice": 250000.0,
  "pricingType": 1,
  "isActive": true,
  "lowPriorityDurationMinutes": 4320,
  "normalPriorityDurationMinutes": 2880,
  "highPriorityDurationMinutes": 1440,
  "urgentPriorityDurationMinutes": 720,
  "stages": [ { "id": "...", "name": "التصميم", "order": 1, ... } ]
}
 */

/// A restoration type and the ordered workflow [stages] a restoration of this
/// type moves through inside the lab. Stages belong to the type — they are
/// not a separate lab-wide list.
class RestorationTypeModel {
  final String id;
  final String? laboratoryId;
  final String? name;
  final String? nameAr;
  final String? description;
  final double? transparency;
  final double defaultPrice;
  final int? pricingType;
  final bool isActive;
  final int? lowPriorityDurationMinutes;
  final int? normalPriorityDurationMinutes;
  final int? highPriorityDurationMinutes;
  final int? urgentPriorityDurationMinutes;
  final List<CaseWorkflowStageModel> stages;

  RestorationTypeModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.nameAr,
    this.description,
    this.transparency,
    this.defaultPrice = 0,
    this.pricingType,
    this.isActive = true,
    this.lowPriorityDurationMinutes,
    this.normalPriorityDurationMinutes,
    this.highPriorityDurationMinutes,
    this.urgentPriorityDurationMinutes,
    this.stages = const [],
  });

  /// Prefers the Arabic name for display, falling back to the base name.
  String get displayName =>
      (nameAr != null && nameAr!.isNotEmpty) ? nameAr! : (name ?? '—');

  factory RestorationTypeModel.fromJson(Map<String, dynamic> json) {
    final stages =
        (json['stages'] as List<dynamic>?)
            ?.map(
              (e) => CaseWorkflowStageModel.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        <CaseWorkflowStageModel>[];
    stages.sort((a, b) => a.order.compareTo(b.order));

    return RestorationTypeModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      transparency: (json['transparency'] as num?)?.toDouble(),
      defaultPrice: (json['defaultPrice'] as num?)?.toDouble() ?? 0,
      pricingType: json['pricingType'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      lowPriorityDurationMinutes: json['lowPriorityDurationMinutes'] as int?,
      normalPriorityDurationMinutes:
          json['normalPriorityDurationMinutes'] as int?,
      highPriorityDurationMinutes: json['highPriorityDurationMinutes'] as int?,
      urgentPriorityDurationMinutes:
          json['urgentPriorityDurationMinutes'] as int?,
      stages: stages,
    );
  }
}
