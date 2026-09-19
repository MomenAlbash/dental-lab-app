/// `ClinicCreateZoneRequest`.
class CreateZoneRequestModel {
  const CreateZoneRequestModel({
    required this.name,
    this.nameAr,
    this.description,
    this.isActive = true,
    this.areaIds = const [],
    this.representativeUserIds = const [],
    this.returnDeliveryFee,
  });

  final String name;
  final String? nameAr;
  final String? description;
  final bool isActive;
  final List<String> areaIds;
  final List<String> representativeUserIds;
  final double? returnDeliveryFee;

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameAr': nameAr,
    'description': description,
    'isActive': isActive,
    'areaIds': areaIds,
    'representativeUserIds': representativeUserIds,
    'returnDeliveryFee': returnDeliveryFee,
  };
}

/// `ClinicUpdateZoneRequest` — every field optional/nullable per the schema,
/// but the form always resends the full picked sets for `areaIds` and
/// `representativeUserIds` rather than a partial patch: the server
/// treats the arrays as a replacement, not a merge.
class UpdateZoneRequestModel {
  const UpdateZoneRequestModel({
    this.name,
    this.nameAr,
    this.description,
    this.isActive,
    this.areaIds = const [],
    this.representativeUserIds = const [],
    this.returnDeliveryFee,
  });

  final String? name;
  final String? nameAr;
  final String? description;
  final bool? isActive;
  final List<String> areaIds;
  final List<String> representativeUserIds;
  final double? returnDeliveryFee;

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameAr': nameAr,
    'description': description,
    'isActive': isActive,
    'areaIds': areaIds,
    'representativeUserIds': representativeUserIds,
    'returnDeliveryFee': returnDeliveryFee,
  };
}
