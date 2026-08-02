/// Create payload for a patient (`ClinicCreatePatientRequest`). `doctorId`
/// and `firstName` are the only required fields.
class CreatePatientRequestModel {
  final String doctorId;
  final String? clinicId;
  final String firstName;
  final String? lastName;
  final int? gender;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? notes;

  CreatePatientRequestModel({
    required this.doctorId,
    this.clinicId,
    required this.firstName,
    this.lastName,
    this.gender,
    this.dateOfBirth,
    this.phoneNumber,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'clinicId': clinicId,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'phoneNumber': phoneNumber,
      'notes': notes,
    };
  }
}
