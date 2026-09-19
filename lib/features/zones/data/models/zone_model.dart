import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart'
    show ZoneRepresentativeModel;

/// `ClinicZoneAreaDto` — one of a zone's assigned areas, as the zone reads
/// it back (denormalised with its city, for display).
class ZoneAreaModel {
  final String id;
  final String areaId;
  final String? areaName;
  final String? areaNameAr;
  final String cityId;
  final String? cityName;

  const ZoneAreaModel({
    required this.id,
    required this.areaId,
    this.areaName,
    this.areaNameAr,
    required this.cityId,
    this.cityName,
  });

  factory ZoneAreaModel.fromJson(Map<String, dynamic> json) {
    return ZoneAreaModel(
      id: json['id'] as String,
      areaId: json['areaId'] as String,
      areaName: json['areaName'] as String?,
      areaNameAr: json['areaNameAr'] as String?,
      cityId: json['cityId'] as String,
      cityName: json['cityName'] as String?,
    );
  }
}

/// `ClinicZoneDto` — a delivery/coverage zone: the areas it spans and the
/// representatives who work it.
class ZoneModel {
  final String id;
  final String laboratoryId;
  final String? laboratoryName;
  final String? name;
  final String? nameAr;
  final String? description;
  final bool isActive;
  final List<ZoneAreaModel> areas;
  final List<ZoneRepresentativeModel> representatives;
  final int doctorCount;
  final double? returnDeliveryFee;
  final DateTime? createdAt;

  const ZoneModel({
    required this.id,
    required this.laboratoryId,
    this.laboratoryName,
    this.name,
    this.nameAr,
    this.description,
    this.isActive = true,
    this.areas = const [],
    this.representatives = const [],
    this.doctorCount = 0,
    this.returnDeliveryFee,
    this.createdAt,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    final rawAreas = json['areas'] as List<dynamic>? ?? const [];
    final rawReps = json['representatives'] as List<dynamic>? ?? const [];

    return ZoneModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String,
      laboratoryName: json['laboratoryName'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      areas: rawAreas
          .whereType<Map<String, dynamic>>()
          .map(ZoneAreaModel.fromJson)
          .toList(),
      representatives: rawReps
          .whereType<Map<String, dynamic>>()
          .map(ZoneRepresentativeModel.fromJson)
          .toList(),
      doctorCount: json['doctorCount'] as int? ?? 0,
      returnDeliveryFee: (json['returnDeliveryFee'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
