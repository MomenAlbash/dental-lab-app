import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';

/// Gender as encoded by the API (`0` = male, `1` = female).
enum DoctorGender {
  male,
  female;

  int get apiValue => index;

  String get arabicLabel => switch (this) {
    DoctorGender.male => 'ذكر',
    DoctorGender.female => 'أنثى',
  };

  static DoctorGender? fromApi(int? value) => switch (value) {
    0 => DoctorGender.male,
    1 => DoctorGender.female,
    _ => null,
  };
}

/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "firstName": "أحمد",
  "lastName": "الخطيب",
  "email": "ahmad@example.com",
  "phoneNumber": "0991234567",
  "address": "المزة، دمشق",
  "imagePath": null,
  "gender": 0,
  "dateOfBirth": "1985-04-12",
  "isActive": true,
  "cityId": "...",
  "city": { "id": "...", "name": "دمشق" },
  "clinicId": "...",
  "clinic": { "id": "...", "name": "عيادة النور" }
}
 */

class DoctorModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? imagePath;
  final DoctorGender? gender;
  final String? dateOfBirth;
  final bool isActive;
  final String? cityId;
  final CityModel? city;
  final String? clinicId;
  final ClinicModel? clinic;
  final List<DoctorAttachmentFileModel> files;

  DoctorModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.address,
    this.imagePath,
    this.gender,
    this.dateOfBirth,
    this.isActive = true,
    this.cityId,
    this.city,
    this.clinicId,
    this.clinic,
    this.files = const [],
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  String? get cityName => city?.name;

  String? get clinicName => clinic?.name;

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      imagePath: json['imagePath'] as String?,
      gender: DoctorGender.fromApi(json['gender'] as int?),
      dateOfBirth: json['dateOfBirth'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      cityId: json['cityId'] as String?,
      city: json['city'] == null
          ? null
          : CityModel.fromJson(json['city'] as Map<String, dynamic>),
      clinicId: json['clinicId'] as String?,
      clinic: json['clinic'] == null
          ? null
          : ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>),
      files: (json['files'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DoctorAttachmentFileModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
