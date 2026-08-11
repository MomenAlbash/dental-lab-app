import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status_history_model.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

/// Full case details (`ClinicCaseDetailDto`).
class CaseDetailModel {
  final String id;
  final String? caseNumber;
  final String? referenceNumber;

  /// See [CaseListItemModel.priorityId] — priorities are a lookup entity, so
  /// the case carries the id plus the names denormalised onto it.
  final String? priorityId;
  final String? priorityName;
  final String? priorityNameAr;
  final String? patientName;
  final DoctorModel? doctor;
  final ClinicModel? clinic;
  final CaseStatus caseStatus;
  final String? dueDate;
  final String? createdAt;
  final String? receivedAt;
  final String? notes;
  final List<ToothMarkModel> teeth;
  final List<CaseRestorationModel> restorations;
  final List<CaseFileModel> files;
  final List<CaseStatusHistoryModel> history;

  CaseDetailModel({
    required this.id,
    this.caseNumber,
    this.referenceNumber,
    this.priorityId,
    this.priorityName,
    this.priorityNameAr,
    this.patientName,
    this.doctor,
    this.clinic,
    this.caseStatus = CaseStatus.created,
    this.dueDate,
    this.createdAt,
    this.receivedAt,
    this.notes,
    this.teeth = const [],
    this.restorations = const [],
    this.files = const [],
    this.history = const [],
  });

  String? get doctorName => doctor?.fullName;
  String? get clinicName => clinic?.name;
  String get caseStatusLabel => caseStatus.arabicLabel;

  /// Arabic first, English as the fallback; empty when the case has no
  /// priority at all, so callers can hide the badge rather than show a dash.
  String get priorityLabel => (priorityNameAr?.trim().isNotEmpty ?? false)
      ? priorityNameAr!.trim()
      : (priorityName?.trim() ?? '');

  static List<T> _list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return (value as List<dynamic>?)
            ?.map((e) => fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
  }

  factory CaseDetailModel.fromJson(Map<String, dynamic> json) {
    return CaseDetailModel(
      id: json['id'] as String,
      caseNumber: json['caseNumber'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      priorityId: json['priorityId'] as String?,
      priorityName: json['priorityName'] as String?,
      priorityNameAr: json['priorityNameAr'] as String?,
      patientName: json['patientName'] as String?,
      doctor: json['doctor'] == null
          ? null
          : DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>),
      clinic: json['clinic'] == null
          ? null
          : ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>),
      caseStatus: CaseStatus.fromApi(json['caseStatus'] as int?),
      dueDate: json['dueDate'] as String?,
      createdAt: json['createdAt'] as String?,
      receivedAt: json['receivedAt'] as String?,
      notes: json['notes'] as String?,
      teeth: _list(json['teeth'], ToothMarkModel.fromJson),
      restorations: _list(json['restorations'], CaseRestorationModel.fromJson),
      files: _list(json['files'], CaseFileModel.fromJson),
      history: _list(json['history'], CaseStatusHistoryModel.fromJson),
    );
  }
}
