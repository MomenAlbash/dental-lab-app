/// `ClinicUpdateClinicRequest`. Every field is optional — only what changed
/// needs sending.
class UpdateClinicRequestModel {
  /// Send as [zoneId] to take the clinic off its zone. A plain `null` means
  /// "field omitted, leave the current assignment alone" and cannot express
  /// "clear it" — this is the same convention `UpdateDoctorRequest.priceTierId`
  /// uses for the same reason.
  static const clearZoneId = '00000000-0000-0000-0000-000000000000';

  final String? name;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? cityId;
  final String? laboratoryId;
  final double? latitude;
  final double? longitude;

  /// Repoints the clinic's zone, as a dated spell — see [ClinicModel.zoneId].
  /// Null (omitted) leaves the current assignment alone; [clearZoneId]
  /// clears it.
  final String? zoneId;
  final bool? isActive;

  UpdateClinicRequestModel({
    this.name,
    this.phoneNumber,
    this.email,
    this.address,
    this.cityId,
    this.laboratoryId,
    this.latitude,
    this.longitude,
    this.zoneId,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'cityId': cityId,
      'laboratoryId': laboratoryId,
      'latitude': latitude,
      'longitude': longitude,
      'zoneId': zoneId,
      'isActive': isActive,
    };
  }
}
