/// A restoration type's price within a price tier (`PriceTierRestorationDto`).
class PriceTierRestorationModel {
  final String id;
  final String restorationTypeId;
  final String? restorationTypeName;
  final double price;

  PriceTierRestorationModel({
    required this.id,
    required this.restorationTypeId,
    this.restorationTypeName,
    required this.price,
  });

  factory PriceTierRestorationModel.fromJson(Map<String, dynamic> json) {
    return PriceTierRestorationModel(
      id: json['id'] as String,
      restorationTypeId: json['restorationTypeId'] as String,
      restorationTypeName: json['restorationTypeName'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A price tier — a named price list clinics can be assigned to
/// (`PriceTierDto`). [restorationPrices] holds only the restoration types
/// that have been priced so far within this tier.
class PriceTierModel {
  final String id;
  final String? name;
  final String? description;
  final bool isActive;
  final List<PriceTierRestorationModel> restorationPrices;
  final int pricedRestorationCount;
  final int totalRestorationTypeCount;

  PriceTierModel({
    required this.id,
    this.name,
    this.description,
    this.isActive = true,
    this.restorationPrices = const [],
    this.pricedRestorationCount = 0,
    this.totalRestorationTypeCount = 0,
  });

  factory PriceTierModel.fromJson(Map<String, dynamic> json) {
    return PriceTierModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      restorationPrices:
          (json['restorationPrices'] as List<dynamic>?)
              ?.map(
                (e) => PriceTierRestorationModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      pricedRestorationCount: json['pricedRestorationCount'] as int? ?? 0,
      totalRestorationTypeCount: json['totalRestorationTypeCount'] as int? ?? 0,
    );
  }
}
