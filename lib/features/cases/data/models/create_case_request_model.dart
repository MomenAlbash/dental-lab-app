import 'package:dental_lab_app/features/cases/data/models/case_restoration_request_model.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';

/// Create payload for a case (`ClinicCreateCaseRequest`). All fields are
/// technically optional on the API, but a case needs at least a doctor, a
/// patient name and one restoration to be meaningful.
class CreateCaseRequestModel {
  final String? doctorId;
  final String? clinicId;
  final String? patientId;
  final String? patientName;
  final String? referenceNumber;
  final int? priority;
  final String? notes;
  final String? dueDate;
  final List<ToothMarkModel> teeth;
  final List<CaseRestorationRequestModel> restorations;

  CreateCaseRequestModel({
    this.doctorId,
    this.clinicId,
    this.patientId,
    this.patientName,
    this.referenceNumber,
    this.priority,
    this.notes,
    this.dueDate,
    this.teeth = const [],
    this.restorations = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'clinicId': clinicId,
      'patientId': patientId,
      'patientName': patientName,
      'referenceNumber': referenceNumber,
      'priority': priority,
      'notes': notes,
      'dueDate': dueDate,
      'teeth': teeth.map((t) => t.toJson()).toList(),
      'restorations': restorations.map((r) => r.toJson()).toList(),
    };
  }
}
