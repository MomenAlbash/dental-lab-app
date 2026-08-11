import 'package:dental_lab_app/features/cases/data/models/case_status.dart';

/// Filters applied to the cases list (`GET /Cases` query params). All fields
/// are optional — `null` means "don't filter by this".
class CaseFiltersModel {
  const CaseFiltersModel({
    this.doctorId,
    this.doctorName,
    this.clinicId,
    this.clinicName,
    this.patientId,
    this.patientName,
    this.priorityId,
    this.priorityName,
    this.caseStatus,
    this.dueDateFrom,
    this.dueDateTo,
  });

  static const empty = CaseFiltersModel();

  final String? doctorId;
  final String? doctorName;
  final String? clinicId;
  final String? clinicName;

  /// Narrows to one patient's cases. The name rides along so the sheet can
  /// show the selection without waiting on the patients list.
  final String? patientId;
  final String? patientName;

  /// Id of the lab-defined priority to narrow by, with its label kept
  /// alongside so the sheet can show the selection without reloading the
  /// priorities list.
  final String? priorityId;
  final String? priorityName;

  /// Filters by the case's overall lifecycle status. Independent of the list's
  /// summary strip, which narrows whatever the server already returned.
  final CaseStatus? caseStatus;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;

  bool get isEmpty =>
      doctorId == null &&
      clinicId == null &&
      patientId == null &&
      priorityId == null &&
      caseStatus == null &&
      dueDateFrom == null &&
      dueDateTo == null;

  int get activeCount => [
    doctorId,
    clinicId,
    patientId,
    priorityId,
    caseStatus,
    dueDateFrom,
    dueDateTo,
  ].where((v) => v != null).length;

  CaseFiltersModel copyWith({
    String? doctorId,
    String? doctorName,
    bool clearDoctor = false,
    String? clinicId,
    String? clinicName,
    bool clearClinic = false,
    String? patientId,
    String? patientName,
    bool clearPatient = false,
    String? priorityId,
    String? priorityName,
    bool clearPriority = false,
    CaseStatus? caseStatus,
    bool clearCaseStatus = false,
    DateTime? dueDateFrom,
    bool clearDueDateFrom = false,
    DateTime? dueDateTo,
    bool clearDueDateTo = false,
  }) {
    return CaseFiltersModel(
      doctorId: clearDoctor ? null : (doctorId ?? this.doctorId),
      doctorName: clearDoctor ? null : (doctorName ?? this.doctorName),
      clinicId: clearClinic ? null : (clinicId ?? this.clinicId),
      clinicName: clearClinic ? null : (clinicName ?? this.clinicName),
      patientId: clearPatient ? null : (patientId ?? this.patientId),
      patientName: clearPatient ? null : (patientName ?? this.patientName),
      priorityId: clearPriority ? null : (priorityId ?? this.priorityId),
      priorityName: clearPriority ? null : (priorityName ?? this.priorityName),
      caseStatus: clearCaseStatus ? null : (caseStatus ?? this.caseStatus),
      dueDateFrom: clearDueDateFrom ? null : (dueDateFrom ?? this.dueDateFrom),
      dueDateTo: clearDueDateTo ? null : (dueDateTo ?? this.dueDateTo),
    );
  }
}
