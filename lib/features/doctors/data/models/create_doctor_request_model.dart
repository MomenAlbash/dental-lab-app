/// Create payload for a doctor (`application/json`). Mirrors
/// `CreateDoctorRequest`: only `firstName` and `lastName` are required.
class CreateDoctorRequestModel {
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final int? gender;
  final String? dateOfBirth;
  final String? cityId;
  final String? clinicId;

  CreateDoctorRequestModel({
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
    this.address,
    this.gender,
    this.dateOfBirth,
    this.cityId,
    this.clinicId,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'cityId': cityId,
      'clinicId': clinicId,
    };
  }
}
