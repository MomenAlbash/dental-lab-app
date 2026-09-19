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

  /// The price list this doctor is billed at. Null clears it, which is why
  /// every caller must send the doctor's *current* value rather than omitting
  /// it — see [toJson].
  final String? priceTierId;

  /// Free text on the pricing arrangement, capped at 500 by the API.
  final String? pricingNote;

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
    this.priceTierId,
    this.pricingNote,
    this.isActive,
  }) : assert(
         pricingNote == null || pricingNote.length <= 500,
         'pricingNote is capped at 500 by the API',
       );

  /// **Every key is sent, nulls included** — this endpoint replaces the
  /// doctor rather than patching them. A caller that means to change one
  /// field has to resend the rest, or it will blank them.
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
      'priceTierId': priceTierId,
      'pricingNote': pricingNote,
      'isActive': isActive,
    };
  }
}
