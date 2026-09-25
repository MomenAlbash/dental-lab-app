import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';

/*
{
  "id": "...",
  "firstName": "خالد",
  "lastName": "العلي",
  "gender": 0,
  "dateOfBirth": "1990-01-01",
  "phoneNumber": "0991234567",
  "notes": "...",
  "doctorId": "...",
  "doctor": { ... },
  "clinicId": "...",
  "clinic": { ... },
  "caseCount": 3
}
 */

/// A patient (`PatientDto`).
class PatientModel {
  final String id;

  /// Whether the server would accept a delete for this patient.
  ///
  /// Defaults to true so a response from before the field existed still reads
  /// as deletable — the server refuses it anyway, and the message comes back
  /// with that refusal.
  final bool canDelete;

  /// Why the delete is refused, shown on the disabled control rather than
  /// hiding it: an action that vanishes teaches nobody the rule.
  final String? deleteMessage;

  final String? firstName;
  final String? lastName;
  final PatientGender? gender;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? notes;
  final String? doctorId;
  final DoctorModel? doctor;
  final String? clinicId;
  final ClinicModel? clinic;
  final int caseCount;

  PatientModel({
    required this.id,
    this.canDelete = true,
    this.deleteMessage,
    this.firstName,
    this.lastName,
    this.gender,
    this.dateOfBirth,
    this.phoneNumber,
    this.notes,
    this.doctorId,
    this.doctor,
    this.clinicId,
    this.clinic,
    this.caseCount = 0,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  String? get doctorName => doctor?.fullName;
  String? get clinicName => clinic?.name;

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String,
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      gender: PatientGender.fromApi(json['gender'] as int?),
      dateOfBirth: json['dateOfBirth'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      notes: json['notes'] as String?,
      doctorId: json['doctorId'] as String?,
      doctor: json['doctor'] == null
          ? null
          : DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>),
      clinicId: json['clinicId'] as String?,
      clinic: json['clinic'] == null
          ? null
          : ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>),
      caseCount: json['caseCount'] as int? ?? 0,
    );
  }
}
