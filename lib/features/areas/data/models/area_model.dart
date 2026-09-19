/// `ClinicAreaDto` — a district ("حي"), scoped to a city, optionally already
/// claimed by a zone.
class AreaModel {
  final String id;
  final String cityId;
  final String? cityName;
  final String? countryName;
  final String? name;
  final String? nameAr;
  final bool isActive;

  /// Set once a zone has picked this area into its `areaIds` — read-only
  /// here; only the zone's own form changes it.
  final String? zoneId;
  final String? zoneName;

  const AreaModel({
    required this.id,
    required this.cityId,
    this.cityName,
    this.countryName,
    this.name,
    this.nameAr,
    this.isActive = true,
    this.zoneId,
    this.zoneName,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'] as String,
      cityId: json['cityId'] as String,
      cityName: json['cityName'] as String?,
      countryName: json['countryName'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      zoneId: json['zoneId'] as String?,
      zoneName: json['zoneName'] as String?,
    );
  }
}
