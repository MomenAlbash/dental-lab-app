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
      // Omitted rather than sent as null: `gender` maps to a non-nullable
      // enum on the API, which answers 400 ("The JSON value could not be
      // converted to ... Gender") for an explicit null. Leaving the key out
      // lets the server apply its own default.
      if (gender != null) 'gender': gender,
      'dateOfBirth': dateOfBirth,
      'phoneNumber': phoneNumber,
      'notes': notes,
    };
  }
}
