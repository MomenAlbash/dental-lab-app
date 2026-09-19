/// `ClinicCreateClinicRequest`. Only [name] is required — a zone is assigned
/// afterward, through [UpdateClinicRequestModel]; the create endpoint carries
/// no such field.
class CreateClinicRequestModel {
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? cityId;
  final double? latitude;
  final double? longitude;

  CreateClinicRequestModel({
    required this.name,
    this.phoneNumber,
    this.email,
    this.address,
    this.cityId,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'cityId': cityId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
