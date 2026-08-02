import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';

/// Filters applied to the patients list (`GET /Patients` query params). All
/// fields are optional — `null` means "don't filter by this".
class PatientFiltersModel {
  const PatientFiltersModel({
    this.doctorId,
    this.doctorName,
    this.clinicId,
    this.clinicName,
    this.gender,
  });

  static const empty = PatientFiltersModel();

  final String? doctorId;
  final String? doctorName;
  final String? clinicId;
  final String? clinicName;
  final PatientGender? gender;

  bool get isEmpty => doctorId == null && clinicId == null && gender == null;

  int get activeCount =>
      [doctorId, clinicId, gender].where((v) => v != null).length;

  PatientFiltersModel copyWith({
    String? doctorId,
    String? doctorName,
    bool clearDoctor = false,
    String? clinicId,
    String? clinicName,
    bool clearClinic = false,
    PatientGender? gender,
    bool clearGender = false,
  }) {
    return PatientFiltersModel(
      doctorId: clearDoctor ? null : (doctorId ?? this.doctorId),
      doctorName: clearDoctor ? null : (doctorName ?? this.doctorName),
      clinicId: clearClinic ? null : (clinicId ?? this.clinicId),
      clinicName: clearClinic ? null : (clinicName ?? this.clinicName),
      gender: clearGender ? null : (gender ?? this.gender),
    );
  }
}
