/// Create payload for a restoration type. Required: [name], [defaultPrice].
class CreateRestorationTypeRequestModel {
  final String name;
  final String? nameAr;
  final String? description;
  final double? transparency;
  final double defaultPrice;
  final int? pricingType;
  final bool showInClinicApp;
  final int? displayOrder;

  CreateRestorationTypeRequestModel({
    required this.name,
    this.nameAr,
    this.description,
    this.transparency,
    required this.defaultPrice,
    this.pricingType,
    this.showInClinicApp = true,
    this.displayOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'transparency': transparency,
      'defaultPrice': defaultPrice,
      'pricingType': pricingType,
      'showInClinicApp': showInClinicApp,
      'displayOrder': displayOrder,
    };
  }
}
