import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

/// Filters applied to the doctors list (`GET /Doctors` query params). All
/// fields are optional — `null` means "don't filter by this".
class DoctorFiltersModel {
  const DoctorFiltersModel({
    this.clinicId,
    this.clinicName,
    this.cityId,
    this.cityName,
    this.gender,
  });

  static const empty = DoctorFiltersModel();

  final String? clinicId;
  final String? clinicName;
  final String? cityId;
  final String? cityName;
  final DoctorGender? gender;

  bool get isEmpty => clinicId == null && cityId == null && gender == null;

  int get activeCount =>
      [clinicId, cityId, gender].where((v) => v != null).length;

  DoctorFiltersModel copyWith({
    String? clinicId,
    String? clinicName,
    bool clearClinic = false,
    String? cityId,
    String? cityName,
    bool clearCity = false,
    DoctorGender? gender,
    bool clearGender = false,
  }) {
    return DoctorFiltersModel(
      clinicId: clearClinic ? null : (clinicId ?? this.clinicId),
      clinicName: clearClinic ? null : (clinicName ?? this.clinicName),
      cityId: clearCity ? null : (cityId ?? this.cityId),
      cityName: clearCity ? null : (cityName ?? this.cityName),
      gender: clearGender ? null : (gender ?? this.gender),
    );
  }
}
