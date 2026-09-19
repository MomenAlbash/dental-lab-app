import 'package:dental_lab_app/features/cities/data/models/city_model.dart';

/// `ClinicDto`.
class ClinicModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? imagePath;
  final bool isActive;
  final String? cityId;
  final CityModel? city;
  final String? laboratoryId;

  /// Only populated for the "all laboratories" browse case.
  final String? laboratoryName;
  final double? latitude;
  final double? longitude;

  /// The zone this clinic sits in **today** — read off its open, dated
  /// assignment spell, never a plain column. Null means unassigned.
  final String? zoneId;
  final String? zoneName;
  final String? zoneNameAr;

  final int doctorCount;
  final int patientCount;
  final int caseCount;

  final bool canDelete;
  final String? deleteMessage;

  ClinicModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.address,
    this.imagePath,
    this.isActive = true,
    this.cityId,
    this.city,
    this.laboratoryId,
    this.laboratoryName,
    this.latitude,
    this.longitude,
    this.zoneId,
    this.zoneName,
    this.zoneNameAr,
    this.doctorCount = 0,
    this.patientCount = 0,
    this.caseCount = 0,
    this.canDelete = true,
    this.deleteMessage,
  });

  /// Convenience accessor for the city name whether it arrives nested under
  /// [city] or only as a bare id.
  String? get cityName => city?.name;

  /// Arabic first, English as the fallback — empty when the lab named
  /// neither, so a caller can hide the chip instead of showing a placeholder.
  String get zoneDisplayName {
    final ar = zoneNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return zoneName?.trim() ?? '';
  }

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      imagePath: json['imagePath'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      cityId: json['cityId'] as String?,
      city: json['city'] == null
          ? null
          : CityModel.fromJson(json['city'] as Map<String, dynamic>),
      laboratoryId: json['laboratoryId'] as String?,
      laboratoryName: json['laboratoryName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      zoneId: json['zoneId'] as String?,
      zoneName: json['zoneName'] as String?,
      zoneNameAr: json['zoneNameAr'] as String?,
      doctorCount: json['doctorCount'] as int? ?? 0,
      patientCount: json['patientCount'] as int? ?? 0,
      caseCount: json['caseCount'] as int? ?? 0,
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}
