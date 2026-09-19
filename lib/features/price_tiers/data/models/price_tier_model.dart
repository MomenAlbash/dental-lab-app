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

/// A doctor this tier prices (`PriceTierDoctorDto`).
class PriceTierDoctorModel {
  final String id;

  /// The lab's own visible doctor number, not a database key.
  final int? number;

  final String? fullName;
  final String? clinicName;

  const PriceTierDoctorModel({
    required this.id,
    this.number,
    this.fullName,
    this.clinicName,
  });

  String get displayName => fullName?.trim() ?? '';

  factory PriceTierDoctorModel.fromJson(Map<String, dynamic> json) {
    return PriceTierDoctorModel(
      id: json['id'] as String? ?? '',
      number: json['number'] as int?,
      fullName: json['fullName'] as String?,
      clinicName: json['clinicName'] as String?,
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

  /// The doctors billed at this tier. Only sent on the detail endpoint — the
  /// list endpoint carries [doctorCount] alone.
  final List<PriceTierDoctorModel> doctors;

  final int doctorCount;

  PriceTierModel({
    required this.id,
    this.name,
    this.description,
    this.isActive = true,
    this.restorationPrices = const [],
    this.pricedRestorationCount = 0,
    this.totalRestorationTypeCount = 0,
    this.doctors = const [],
    this.doctorCount = 0,
  });

  /// A tier nobody is billed at is priced but unused — worth saying, since it
  /// looks identical to a working one.
  bool get hasNoDoctors => doctorCount == 0 && doctors.isEmpty;

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
      doctors:
          (json['doctors'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PriceTierDoctorModel.fromJson)
              .toList() ??
          const [],
      doctorCount: json['doctorCount'] as int? ?? 0,
    );
  }
}
