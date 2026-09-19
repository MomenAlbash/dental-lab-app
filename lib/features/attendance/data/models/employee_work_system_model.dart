import 'package:dental_lab_app/core/helper/api_time_helper.dart';

/// One spell of an employee being on a shift (`EmployeeWorkSystemDto`).
///
/// **A history, not a field.** Assigning a shift does not overwrite the last
/// one — it closes that spell and opens a new one, so "which shift was Ahmad
/// on last March" stays answerable, and payroll for a past period is judged
/// against the rules that actually applied then. The screens edit this as a
/// list with one highlighted active row, never as a dropdown that forgets.
class EmployeeWorkSystemModel {
  const EmployeeWorkSystemModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeImagePath,
    this.employeeCode,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.workShiftId,
    this.workShiftName,
    this.note,
  });

  final String id;
  final String employeeId;

  /// Only filled in by shift-scoped reads ("who is on this shift"). The
  /// employee's own history knows whose rows these are and leaves it null
  /// rather than fetching a name that screen never shows.
  final String? employeeName;

  final String? employeeImagePath;
  final String? employeeCode;

  final DateTime? startDate;

  /// Null on the open spell — the one still in effect.
  final DateTime? endDate;

  /// Server-computed. Not derived from [endDate] being null: a spell can be
  /// dated to start in the future, which is open-ended but not yet active.
  final bool isActive;

  /// Null means "no shift" — a real arrangement (a day labourer, someone on
  /// call), not a missing value.
  final String? workShiftId;
  final String? workShiftName;

  final String? note;

  String get shiftLabel =>
      workShiftName?.trim().isNotEmpty ?? false ? workShiftName! : 'بلا وردية';

  /// `2026-03-01 — حتى الآن`.
  String get periodLabel {
    final start = startDate == null ? '—' : ApiTime.formatDate(startDate!);
    final end = endDate == null ? 'حتى الآن' : ApiTime.formatDate(endDate!);
    return '$start — $end';
  }

  factory EmployeeWorkSystemModel.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkSystemModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      employeeImagePath: json['employeeImagePath'] as String?,
      employeeCode: json['employeeCode'] as String?,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? false,
      workShiftId: json['workShiftId'] as String?,
      workShiftName: json['workShiftName'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// `SaveEmployeeWorkSystemRequest` — opens a new spell for one employee.
class SaveEmployeeWorkSystemRequestModel {
  const SaveEmployeeWorkSystemRequestModel({
    required this.employeeId,
    this.workShiftId,
    this.note,
    this.startDate,
  });

  final String employeeId;

  /// Null takes the employee off every shift — an arrangement in its own
  /// right, and the reason this is nullable rather than required.
  final String? workShiftId;

  final String? note;

  /// Null dates the spell now. Back-dating is how an arrangement that has
  /// already been in effect for a week gets recorded truthfully.
  final DateTime? startDate;

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'workShiftId': workShiftId,
    'note': ?note,
    'startDate': ?startDate?.toIso8601String(),
  };
}

/// `AssignWorkShiftEmployeesRequest` — the shift-centric counterpart: opens a
/// spell on one shift for several employees at once.
///
/// An employee already on another shift is moved off it, exactly as the
/// single-employee form does — the two are the same act asked from opposite
/// ends.
class AssignWorkShiftEmployeesRequestModel {
  const AssignWorkShiftEmployeesRequestModel({
    required this.workShiftId,
    required this.employeeIds,
    this.startDate,
  });

  final String workShiftId;
  final List<String> employeeIds;
  final DateTime? startDate;

  Map<String, dynamic> toJson() => {
    'workShiftId': workShiftId,
    'employeeIds': employeeIds,
    'startDate': ?startDate?.toIso8601String(),
  };
}
