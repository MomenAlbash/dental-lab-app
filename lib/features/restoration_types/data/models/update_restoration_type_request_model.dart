/// Update payload for a restoration type — same as create plus [isActive].
class UpdateRestorationTypeRequestModel {
  final String? name;
  final String? nameAr;
  final String? description;
  final double? transparency;
  final double? defaultPrice;
  final int? pricingType;
  final bool? showInClinicApp;
  final bool? isActive;
  final int? displayOrder;

  UpdateRestorationTypeRequestModel({
    this.name,
    this.nameAr,
    this.description,
    this.transparency,
    this.defaultPrice,
    this.pricingType,
    this.showInClinicApp,
    this.isActive,
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
      'isActive': isActive,
      'displayOrder': displayOrder,
    };
  }
}
