import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

/// A row in the cases list (`ClinicCaseListItemDto`).
class CaseListItemModel {
  final String id;
  final String? caseNumber;
  final String? referenceNumber;
  final CasePriority priority;
  final String? patientName;
  final DoctorModel? doctor;
  final ClinicModel? clinic;
  final CaseStatus caseStatus;
  final int restorationsCount;
  final int doctorNumber;
  final String? dueDate;
  final String? createdAt;

  CaseListItemModel({
    required this.id,
    this.caseNumber,
    this.referenceNumber,
    this.priority = CasePriority.normal,
    this.patientName,
    this.doctor,
    this.clinic,
    this.caseStatus = CaseStatus.created,
    this.restorationsCount = 0,
    this.doctorNumber = 0,
    this.dueDate,
    this.createdAt,
  });

  String? get doctorName => doctor?.fullName;
  String? get clinicName => clinic?.name;
  String get caseStatusLabel => caseStatus.arabicLabel;

  factory CaseListItemModel.fromJson(Map<String, dynamic> json) {
    return CaseListItemModel(
      id: json['id'] as String,
      caseNumber: json['caseNumber'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      priority: CasePriority.fromApi(json['priority'] as int?),
      patientName: json['patientName'] as String?,
      doctor: json['doctor'] == null
          ? null
          : DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>),
      clinic: json['clinic'] == null
          ? null
          : ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>),
      caseStatus: CaseStatus.fromApi(json['caseStatus'] as int?),
      restorationsCount: json['restorationsCount'] as int? ?? 0,
      doctorNumber: json['doctorNumber'] as int? ?? 0,
      dueDate: json['dueDate'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
