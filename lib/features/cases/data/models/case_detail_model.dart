import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

/// Full case details (`ClinicCaseDetailDto`).
class CaseDetailModel {
  final String id;
  final String? caseNumber;
  final String? referenceNumber;
  final CasePriority priority;
  final String? patientName;
  final DoctorModel? doctor;
  final ClinicModel? clinic;
  final CaseWorkflowStageModel? currentStage;
  final String? dueDate;
  final String? createdAt;
  final String? notes;
  final List<ToothMarkModel> teeth;
  final List<CaseRestorationModel> restorations;
  final List<CaseFileModel> files;

  CaseDetailModel({
    required this.id,
    this.caseNumber,
    this.referenceNumber,
    this.priority = CasePriority.normal,
    this.patientName,
    this.doctor,
    this.clinic,
    this.currentStage,
    this.dueDate,
    this.createdAt,
    this.notes,
    this.teeth = const [],
    this.restorations = const [],
    this.files = const [],
  });

  String? get doctorName => doctor?.fullName;
  String? get clinicName => clinic?.name;
  String? get currentStageName => currentStage?.name;

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
      priority: CasePriority.fromApi(json['priority'] as int?),
      patientName: json['patientName'] as String?,
      doctor: json['doctor'] == null
          ? null
          : DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>),
      clinic: json['clinic'] == null
          ? null
          : ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>),
      currentStage: json['currentStage'] == null
          ? null
          : CaseWorkflowStageModel.fromJson(
              json['currentStage'] as Map<String, dynamic>,
            ),
      dueDate: json['dueDate'] as String?,
      createdAt: json['createdAt'] as String?,
      notes: json['notes'] as String?,
      teeth: _list(json['teeth'], ToothMarkModel.fromJson),
      restorations: _list(json['restorations'], CaseRestorationModel.fromJson),
      files: _list(json['files'], CaseFileModel.fromJson),
    );
  }
}
