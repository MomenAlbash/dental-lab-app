import 'package:dental_lab_app/features/cases/data/models/case_restoration_request_model.dart';

/// Create payload for a case (`ClinicCreateCaseRequest`). [patientId] is the
/// only field required by the API (a real `Patient` record) — a case also
/// needs a doctor and one restoration to be meaningful.
///
/// Teeth are no longer accepted at the case level — each entry in
/// [restorations] carries its own `teeth` list (see
/// [CaseRestorationRequestModel]).
class CreateCaseRequestModel {
  final String? doctorId;
  final String? clinicId;
  final String? patientId;
  final String? referenceNumber;
  final String? priorityId;
  final String? notes;
  final String? dueDate;
  final String? receivedAt;
  final List<CaseRestorationRequestModel> restorations;

  CreateCaseRequestModel({
    this.doctorId,
    this.clinicId,
    this.patientId,
    this.referenceNumber,
    this.priorityId,
    this.notes,
    this.dueDate,
    this.receivedAt,
    this.restorations = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'clinicId': clinicId,
      'patientId': patientId,
      'referenceNumber': referenceNumber,
      'priorityId': priorityId,
      'notes': notes,
      'dueDate': dueDate,
      'receivedAt': receivedAt,
      'restorations': restorations.map((r) => r.toJson()).toList(),
    };
  }
}
