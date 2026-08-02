/// One workflow stage sent inline while creating a restoration type
/// (`ClinicCreateRestorationTypeStageRequest`).
class CreateRestorationTypeStageRequestModel {
  final String name;
  final int? order;
  final bool isFinal;

  CreateRestorationTypeStageRequestModel({
    required this.name,
    this.order,
    this.isFinal = false,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'order': order, 'isFinal': isFinal};
  }
}

/// Create payload for a restoration type. Required: [name], [defaultPrice].
/// The workflow [stages] this type moves through are sent inline.
class CreateRestorationTypeRequestModel {
  final String name;
  final String? nameAr;
  final String? description;
  final double? transparency;
  final double defaultPrice;
  final int? pricingType;
  final int? lowPriorityDurationMinutes;
  final int? normalPriorityDurationMinutes;
  final int? highPriorityDurationMinutes;
  final int? urgentPriorityDurationMinutes;
  final List<CreateRestorationTypeStageRequestModel> stages;

  CreateRestorationTypeRequestModel({
    required this.name,
    this.nameAr,
    this.description,
    this.transparency,
    required this.defaultPrice,
    this.pricingType,
    this.lowPriorityDurationMinutes,
    this.normalPriorityDurationMinutes,
    this.highPriorityDurationMinutes,
    this.urgentPriorityDurationMinutes,
    this.stages = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'transparency': transparency,
      'defaultPrice': defaultPrice,
      'pricingType': pricingType,
      'lowPriorityDurationMinutes': lowPriorityDurationMinutes,
      'normalPriorityDurationMinutes': normalPriorityDurationMinutes,
      'highPriorityDurationMinutes': highPriorityDurationMinutes,
      'urgentPriorityDurationMinutes': urgentPriorityDurationMinutes,
      'stages': stages.map((s) => s.toJson()).toList(),
    };
  }
}
