/// One workflow stage sent inline while updating a restoration type
/// (`ClinicUpdateRestorationTypeStageRequest`). Pass [id] to update an
/// existing stage in place; omit it to create a new one. Any existing stage
/// left out of the list is removed — this is a full replace.
class UpdateRestorationTypeStageRequestModel {
  final String? id;
  final String name;
  final int? order;
  final bool isFinal;
  final bool isActive;

  UpdateRestorationTypeStageRequestModel({
    this.id,
    required this.name,
    this.order,
    this.isFinal = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'order': order,
      'isFinal': isFinal,
      'isActive': isActive,
    };
  }
}

/// Update payload for a restoration type — same as create plus [isActive].
/// [stages] is a full replace: existing stages are matched by [id]
/// (`UpdateRestorationTypeStageRequestModel.id`), new ones omit it, and any
/// existing stage left out of the list is removed.
class UpdateRestorationTypeRequestModel {
  final String? name;
  final String? nameAr;
  final String? description;
  final double? transparency;
  final double? defaultPrice;
  final int? pricingType;
  final bool? isActive;
  final int? lowPriorityDurationMinutes;
  final int? normalPriorityDurationMinutes;
  final int? highPriorityDurationMinutes;
  final int? urgentPriorityDurationMinutes;
  final List<UpdateRestorationTypeStageRequestModel>? stages;

  UpdateRestorationTypeRequestModel({
    this.name,
    this.nameAr,
    this.description,
    this.transparency,
    this.defaultPrice,
    this.pricingType,
    this.isActive,
    this.lowPriorityDurationMinutes,
    this.normalPriorityDurationMinutes,
    this.highPriorityDurationMinutes,
    this.urgentPriorityDurationMinutes,
    this.stages,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'transparency': transparency,
      'defaultPrice': defaultPrice,
      'pricingType': pricingType,
      'isActive': isActive,
      'lowPriorityDurationMinutes': lowPriorityDurationMinutes,
      'normalPriorityDurationMinutes': normalPriorityDurationMinutes,
      'highPriorityDurationMinutes': highPriorityDurationMinutes,
      'urgentPriorityDurationMinutes': urgentPriorityDurationMinutes,
      if (stages != null) 'stages': stages!.map((s) => s.toJson()).toList(),
    };
  }
}
