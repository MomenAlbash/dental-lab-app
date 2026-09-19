import 'package:dental_lab_app/features/attendance/data/models/daily_attendance_model.dart';

sealed class DailyAttendanceState {
  const DailyAttendanceState();
}

class DailyAttendanceInitial extends DailyAttendanceState {
  const DailyAttendanceInitial();
}

class DailyAttendanceLoading extends DailyAttendanceState {
  const DailyAttendanceLoading();
}

class DailyAttendanceError extends DailyAttendanceState {
  const DailyAttendanceError(this.message);
  final String message;
}

/// One day across the whole laboratory.
class DailyAttendanceLoaded extends DailyAttendanceState {
  const DailyAttendanceLoaded({
    required this.date,
    required this.rows,
    this.isBusy = false,
  });

  final DateTime date;
  final List<DailyAttendanceModel> rows;
  final bool isBusy;

  /// Counted from the rows on purpose: this endpoint answers for the whole
  /// laboratory on one date, so the page *is* the population — unlike the case
  /// list, where counting the page would describe only what was fetched.
  int countWhere(bool Function(DailyAttendanceModel row) test) =>
      rows.where(test).length;

  /// Days already inside a draft payslip. Editing one leaves that statement
  /// disagreeing with its own attendance until payroll is regenerated, so the
  /// screen says so rather than letting it pass silently.
  bool get touchesDraftSalary => rows.any((row) => row.affectsDraftSalary);

  DailyAttendanceLoaded copyWith({bool? isBusy}) => DailyAttendanceLoaded(
    date: date,
    rows: rows,
    isBusy: isBusy ?? this.isBusy,
  );
}

class DailyAttendanceActionSuccess extends DailyAttendanceState {
  const DailyAttendanceActionSuccess(this.message);
  final String message;
}

class DailyAttendanceActionError extends DailyAttendanceState {
  const DailyAttendanceActionError(this.message);
  final String message;
}
