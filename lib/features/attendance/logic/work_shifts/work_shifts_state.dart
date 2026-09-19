import 'package:dental_lab_app/features/attendance/data/models/employee_work_system_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';

sealed class WorkShiftsState {
  const WorkShiftsState();
}

class WorkShiftsInitial extends WorkShiftsState {
  const WorkShiftsInitial();
}

class WorkShiftsLoading extends WorkShiftsState {
  const WorkShiftsLoading();
}

class WorkShiftsError extends WorkShiftsState {
  const WorkShiftsError(this.message);
  final String message;
}

class WorkShiftsLoaded extends WorkShiftsState {
  const WorkShiftsLoaded(this.shifts, {this.isBusy = false});

  final List<WorkShiftModel> shifts;
  final bool isBusy;

  WorkShiftsLoaded copyWith({bool? isBusy}) =>
      WorkShiftsLoaded(shifts, isBusy: isBusy ?? this.isBusy);
}

class WorkShiftsActionSuccess extends WorkShiftsState {
  const WorkShiftsActionSuccess(this.message);
  final String message;
}

class WorkShiftsActionError extends WorkShiftsState {
  const WorkShiftsActionError(this.message);
  final String message;
}

sealed class ShiftRosterState {
  const ShiftRosterState();
}

class ShiftRosterLoading extends ShiftRosterState {
  const ShiftRosterLoading();
}

class ShiftRosterError extends ShiftRosterState {
  const ShiftRosterError(this.message);
  final String message;
}

/// Who is on one shift right now.
class ShiftRosterLoaded extends ShiftRosterState {
  const ShiftRosterLoaded({
    required this.shift,
    required this.members,
    this.isBusy = false,
  });

  final WorkShiftModel shift;

  /// Open spells only — the server answers this shift-scoped read with the
  /// people currently on it, not everyone who ever was.
  final List<EmployeeWorkSystemModel> members;

  final bool isBusy;

  ShiftRosterLoaded copyWith({bool? isBusy}) => ShiftRosterLoaded(
    shift: shift,
    members: members,
    isBusy: isBusy ?? this.isBusy,
  );
}

class ShiftRosterActionSuccess extends ShiftRosterState {
  const ShiftRosterActionSuccess(this.message);
  final String message;
}

class ShiftRosterActionError extends ShiftRosterState {
  const ShiftRosterActionError(this.message);
  final String message;
}
