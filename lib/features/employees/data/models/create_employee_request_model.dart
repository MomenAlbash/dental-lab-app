/// Create payload for an employee. The API expects `multipart/form-data` with
/// PascalCase field names, so [toFormMap] yields the non-null scalar fields
/// keyed by their API names. Only [firstName]/[lastName] are required.
class CreateEmployeeRequestModel {
  final String firstName;
  final String lastName;
  final String? nationalNumber;
  final String? code;
  final int? gender;
  final String? dateOfBirth;
  final String? cityId;
  final String? phoneNumber;
  final String? address;
  final String? bankName;
  final String? bankAccountNumber;

  CreateEmployeeRequestModel({
    required this.firstName,
    required this.lastName,
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

  Map<String, dynamic> toFormMap() {
    final map = <String, dynamic>{
      'FirstName': firstName,
      'LastName': lastName,
      'NationalNumber': nationalNumber,
      'Code': code,
      'Gender': gender?.toString(),
      'DateOfBirth': dateOfBirth,
      'CityId': cityId,
      'PhoneNumber': phoneNumber,
      'Address': address,
      'BankName': bankName,
      'BankAccountNumber': bankAccountNumber,
    };
    map.removeWhere((_, value) => value == null);
    return map;
  }
}
