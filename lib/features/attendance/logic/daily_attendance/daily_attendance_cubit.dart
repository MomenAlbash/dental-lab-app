import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/attendance/data/models/punch_model.dart';
import 'package:dental_lab_app/features/attendance/data/repos/attendance_repo.dart';
import 'package:dental_lab_app/features/attendance/logic/daily_attendance/daily_attendance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One day's attendance for the whole laboratory, and the edits that change it.
///
/// **Every edit is followed by a reload, never a local patch.** A punch does
/// not just add a row: it re-derives the day's status, its lateness, its gaps
/// and its overtime, all of which the server computes. Patching the model here
/// would put a number on screen that nothing else in the system agrees with.
class DailyAttendanceCubit extends Cubit<DailyAttendanceState> {
  DailyAttendanceCubit(this._repo) : super(const DailyAttendanceInitial());

  final AttendanceRepo _repo;

  DateTime _date = _today;

  DateTime get date => _date;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> load({DateTime? date}) async {
    _date = date ?? _date;

    emit(const DailyAttendanceLoading());

    final result = await _repo.getAttendanceForDay(_date);
    if (isClosed) return;

    result.fold(
      (failure) => emit(DailyAttendanceError(failure.errorMessage)),
      (rows) => emit(DailyAttendanceLoaded(date: _date, rows: rows)),
    );
  }

  /// Moves the day being shown. Its own entry point so the calendar's arrows
  /// cannot drift from what the list is actually showing.
  Future<void> goToDay(DateTime date) =>
      load(date: DateTime(date.year, date.month, date.day));

  Future<void> previousDay() =>
      goToDay(_date.subtract(const Duration(days: 1)));

  Future<void> nextDay() => goToDay(_date.add(const Duration(days: 1)));

  /// Adds a stamp the terminal missed, at a wall-clock time on the open day.
  Future<void> addManualPunch({
    required String employeeId,
    required DateTime timestamp,
  }) => _write(
    'تمت إضافة البصمة',
    () => _repo.addManualPunch(
      AddManualPunchRequestModel(
        employeeId: employeeId,
        timestamp: timestamp,
      ),
    ),
  );

  Future<void> updatePunch({
    required String id,
    required DateTime timestamp,
  }) => _write(
    'تم تعديل البصمة',
    () => _repo.updatePunch(id: id, timestamp: timestamp),
  );

  Future<void> deletePunch(String id) =>
      _write('تم حذف البصمة', () => _repo.deletePunch(id));

  /// Recomputes one employee's day from its punches, shift and leaves.
  ///
  /// Offered as its own action because the read model is a cache of an answer:
  /// a shift edited yesterday, or a leave approved this morning, leaves days
  /// standing that were judged under the old facts.
  Future<void> recalculate(String employeeId) => _write(
    'تمت إعادة حساب اليوم',
    () => _repo.recalculateDay(employeeId: employeeId, date: _date),
  );

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final current = state;
    if (current is DailyAttendanceLoaded) emit(current.copyWith(isBusy: true));

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(DailyAttendanceActionError(failure.errorMessage));
        if (current is DailyAttendanceLoaded) emit(current);
      },
      (_) async {
        emit(DailyAttendanceActionSuccess(successMessage));
        await load();
      },
    );
  }
}
