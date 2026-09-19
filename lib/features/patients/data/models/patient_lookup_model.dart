import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';

/// `GET /Patients/{id}/lookup` (`ClinicPatientLookupDto`) — just enough of a
/// patient to confirm the right one was picked.
///
/// Not the full record: a case form needs to show who this is, not their
/// history, and pulling the history to render one line is what makes a form
/// feel slow. [doctorName] is here because the referring doctor is the field
/// most likely to reveal a mis-pick — two patients with the same name usually
/// belong to different doctors.
class PatientLookupModel {
  const PatientLookupModel({
    required this.id,
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.doctorName,
  });

  final String id;
  final String? fullName;
  final PatientGender? gender;
  final DateTime? dateOfBirth;
  final String? doctorName;

  String get displayName {
    final name = fullName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  /// Whole years as of today, or null when no birth date was recorded.
  ///
  /// Computed rather than read: the server sends the date, and an age stored
  /// alongside it would be wrong by up to a year the moment it was saved.
  int? get age {
    final born = dateOfBirth;
    if (born == null) return null;

    final now = DateTime.now();
    var years = now.year - born.year;
    // Not yet had this year's birthday.
    if (now.month < born.month ||
        (now.month == born.month && now.day < born.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }

  factory PatientLookupModel.fromJson(Map<String, dynamic> json) {
    return PatientLookupModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String?,
      gender: PatientGender.fromApi(json['gender'] as int?),
      dateOfBirth: ApiTime.parseDate(json['dateOfBirth'] as String?),
      doctorName: json['doctorName'] as String?,
    );
  }
}
