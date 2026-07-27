/// Update payload for an employee (`application/json`). The image is managed
/// through the dedicated image endpoint, so it is not part of this body.
class UpdateEmployeeRequestModel {
  final String? firstName;
  final String? lastName;
  final String? nationalNumber;
  final String? code;
  final int? gender;
  final String? dateOfBirth;
  final String? cityId;
  final String? phoneNumber;
  final String? address;
  final String? bankName;
  final String? bankAccountNumber;

  UpdateEmployeeRequestModel({
    this.firstName,
    this.lastName,
    this.nationalNumber,
    this.code,
    this.gender,
    this.dateOfBirth,
    this.cityId,
    this.phoneNumber,
    this.address,
    this.bankName,
    this.bankAccountNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'nationalNumber': nationalNumber,
      'code': code,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'cityId': cityId,
      'phoneNumber': phoneNumber,
      'address': address,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
    };
  }
}
