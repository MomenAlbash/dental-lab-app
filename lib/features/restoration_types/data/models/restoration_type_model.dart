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
  "showInClinicApp": true,
  "isActive": true,
  "displayOrder": 1
}
 */

class RestorationTypeModel {
  final String id;
  final String? laboratoryId;
  final String? name;
  final String? nameAr;
  final String? description;
  final double? transparency;
  final double defaultPrice;
  final int? pricingType;
  final bool showInClinicApp;
  final bool isActive;
  final int? displayOrder;

  RestorationTypeModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.nameAr,
    this.description,
    this.transparency,
    this.defaultPrice = 0,
    this.pricingType,
    this.showInClinicApp = true,
    this.isActive = true,
    this.displayOrder,
  });

  /// Prefers the Arabic name for display, falling back to the base name.
  String get displayName =>
      (nameAr != null && nameAr!.isNotEmpty) ? nameAr! : (name ?? '—');

  factory RestorationTypeModel.fromJson(Map<String, dynamic> json) {
    return RestorationTypeModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      transparency: (json['transparency'] as num?)?.toDouble(),
      defaultPrice: (json['defaultPrice'] as num?)?.toDouble() ?? 0,
      pricingType: json['pricingType'] as int?,
      showInClinicApp: json['showInClinicApp'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int?,
    );
  }
}
