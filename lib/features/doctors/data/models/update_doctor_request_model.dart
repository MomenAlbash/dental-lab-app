/// Update payload for a doctor (`application/json`). Mirrors
/// `UpdateDoctorRequest` — same as create plus [isActive].
class UpdateDoctorRequestModel {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final int? gender;
  final String? dateOfBirth;
  final String? cityId;
  final String? clinicId;
  final bool? isActive;

  UpdateDoctorRequestModel({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.address,
    this.gender,
    this.dateOfBirth,
    this.cityId,
    this.clinicId,
    this.isActive,
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
      'isActive': isActive,
    };
  }
}
