/// One row of `GET /Doctors/lookup` (`ClinicDoctorLookupDto`).
///
/// Deliberately thin. The full doctor list carries balances, zones, case
/// counts and a scope — everything a directory screen needs and a picker in a
/// case form does not. Paging the whole record down to fill a dropdown is how
/// a form that should open instantly starts costing a second.
///
/// [clinicName] is the disambiguator, not decoration: two doctors sharing a
/// name is ordinary, and a picker that cannot tell them apart is a picker that
/// files cases against the wrong one.
class DoctorLookupModel {
  const DoctorLookupModel({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.clinicName,
  });

  final String id;
  final String? fullName;
  final String? phoneNumber;
  final String? clinicName;

  String get displayName {
    final name = fullName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  /// The name with whatever tells it apart from a namesake — the clinic if
  /// there is one, the phone otherwise.
  String get subtitle {
    final clinic = clinicName?.trim();
    if (clinic != null && clinic.isNotEmpty) return clinic;
    return phoneNumber?.trim() ?? '';
  }

  factory DoctorLookupModel.fromJson(Map<String, dynamic> json) {
    return DoctorLookupModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      clinicName: json['clinicName'] as String?,
    );
  }
}
