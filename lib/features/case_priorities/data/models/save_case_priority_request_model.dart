/// Create/update payload for a case priority (`SaveCasePriorityRequest`).
/// The API uses the same body for both, so one model covers them.
class SaveCasePriorityRequestModel {
  final String name;
  final String? nameAr;
  final String? description;
  final int displayOrder;
  final bool isDefault;
  final bool isUnlimited;
  final int freePerMonth;
  final double surcharge;
  final String? badgeVariant;
  final bool isActive;

  const SaveCasePriorityRequestModel({
    required this.name,
    this.nameAr,
    this.description,
    this.displayOrder = 0,
    this.isDefault = false,
    this.isUnlimited = false,
    this.freePerMonth = 0,
    this.surcharge = 0,
    this.badgeVariant,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'displayOrder': displayOrder,
      'isDefault': isDefault,
      'isUnlimited': isUnlimited,
      'freePerMonth': freePerMonth,
      'surcharge': surcharge,
      'badgeVariant': badgeVariant,
      'isActive': isActive,
    };
  }
}
