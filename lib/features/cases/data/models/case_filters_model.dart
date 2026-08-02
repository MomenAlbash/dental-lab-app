import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';

/// Filters applied to the cases list (`GET /Cases` query params). All fields
/// are optional — `null` means "don't filter by this".
class CaseFiltersModel {
  const CaseFiltersModel({
    this.doctorId,
    this.doctorName,
    this.clinicId,
    this.clinicName,
    this.priority,
    this.dueDateFrom,
    this.dueDateTo,
  });

  static const empty = CaseFiltersModel();

  final String? doctorId;
  final String? doctorName;
  final String? clinicId;
  final String? clinicName;
  final CasePriority? priority;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;

  bool get isEmpty =>
      doctorId == null &&
      clinicId == null &&
      priority == null &&
      dueDateFrom == null &&
      dueDateTo == null;

  int get activeCount => [
    doctorId,
    clinicId,
    priority,
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
    CasePriority? priority,
    bool clearPriority = false,
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
      priority: clearPriority ? null : (priority ?? this.priority),
      dueDateFrom: clearDueDateFrom ? null : (dueDateFrom ?? this.dueDateFrom),
      dueDateTo: clearDueDateTo ? null : (dueDateTo ?? this.dueDateTo),
    );
  }
}
