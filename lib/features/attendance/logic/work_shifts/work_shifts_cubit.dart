import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/attendance/data/models/employee_work_system_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:dental_lab_app/features/attendance/data/repos/attendance_repo.dart';
import 'package:dental_lab_app/features/attendance/logic/work_shifts/work_shifts_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The laboratory's shift catalogue.
class WorkShiftsCubit extends Cubit<WorkShiftsState> {
  WorkShiftsCubit(this._repo) : super(const WorkShiftsInitial());

  final AttendanceRepo _repo;

  Future<void> load() async {
    emit(const WorkShiftsLoading());

    final result = await _repo.getWorkShifts();
    if (isClosed) return;

    result.fold(
      (failure) => emit(WorkShiftsError(failure.errorMessage)),
      (shifts) => emit(WorkShiftsLoaded(shifts)),
    );
  }

  /// What editing [id]'s rules would disturb.
  ///
  /// Read before the editor opens its save, not after: the days already on the
  /// books were judged against the old rules, and somebody has to be told how
  /// many before they change them.
  Future<WorkShiftAttendanceImpactModel?> peekAttendanceImpact(
    String id,
  ) async {
    final result = await _repo.getWorkShiftAttendanceImpact(id);
    return result.fold((_) => null, (impact) => impact);
  }

  Future<void> create(SaveWorkShiftRequestModel body) =>
      _write('تمت إضافة الوردية', () => _repo.createWorkShift(body));

  Future<void> update({
    required String id,
    required SaveWorkShiftRequestModel body,
  }) => _write(
    'تم تعديل الوردية',
    () => _repo.updateWorkShift(id: id, body: body),
  );

  Future<void> delete(String id) =>
      _write('تم حذف الوردية', () => _repo.deleteWorkShift(id));

  /// Recomputes everyone on a shift over the window their attendance spans.
  ///
  /// The follow-up to editing a shift's rules: the server does not retroject
  /// the change, so without this the old days keep the old verdicts.
  Future<void> recalculateAfterEdit(
    WorkShiftAttendanceImpactModel impact,
  ) async {
    final from = impact.from;
    final to = impact.to;
    if (impact.isEmpty || from == null || to == null) return;

    final current = state;
    if (current is WorkShiftsLoaded) emit(current.copyWith(isBusy: true));

    // One employee failing must not abandon the rest: each is its own range,
    // and a partial recalculation is still better than none.
    for (final employeeId in impact.employeeIds) {
      await _repo.recalculateRange(
        employeeId: employeeId,
        from: from,
        to: to,
      );
      if (isClosed) return;
    }

    emit(
      DailyAttendanceRecalculated(
        'أُعيد حساب حضور ${impact.employeeIds.length} موظف',
      ),
    );
    await load();
  }

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final current = state;
    if (current is WorkShiftsLoaded) emit(current.copyWith(isBusy: true));

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(WorkShiftsActionError(failure.errorMessage));
        if (current is WorkShiftsLoaded) emit(current);
      },
      (_) async {
        emit(WorkShiftsActionSuccess(successMessage));
        await load();
      },
    );
  }
}

/// Emitted after a shift edit's follow-up recalculation, so the screen can say
/// how much attendance was re-judged rather than leaving it silent.
class DailyAttendanceRecalculated extends WorkShiftsActionSuccess {
  const DailyAttendanceRecalculated(super.message);
}

/// One shift's roster — who is on it, and adding people to it.
class ShiftRosterCubit extends Cubit<ShiftRosterState> {
  ShiftRosterCubit(this._repo) : super(const ShiftRosterLoading());

  final AttendanceRepo _repo;

  WorkShiftModel? _shift;

  Future<void> load(WorkShiftModel shift) async {
    _shift = shift;
    emit(const ShiftRosterLoading());

    final result = await _repo.getWorkShiftRoster(shift.id);
    if (isClosed) return;

    result.fold(
      (failure) => emit(ShiftRosterError(failure.errorMessage)),
      (members) => emit(ShiftRosterLoaded(shift: shift, members: members)),
    );
  }

  /// Opens a spell on this shift for several employees at once.
  ///
  /// An employee already on another shift is moved off it — the server closes
  /// their old spell and opens this one, so nobody ends up on two.
  Future<void> assign({
    required List<String> employeeIds,
    DateTime? startDate,
  }) async {
    final shift = _shift;
    final current = state;
    if (shift == null || employeeIds.isEmpty) return;
    if (current is ShiftRosterLoaded) emit(current.copyWith(isBusy: true));

    final result = await _repo.assignWorkShift(
      AssignWorkShiftEmployeesRequestModel(
        workShiftId: shift.id,
        employeeIds: employeeIds,
        startDate: startDate,
      ),
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ShiftRosterActionError(failure.errorMessage));
        if (current is ShiftRosterLoaded) emit(current);
      },
      (_) async {
        emit(const ShiftRosterActionSuccess('تم تعيين الموظفين على الوردية'));
        await load(shift);
      },
    );
  }

  /// Takes one employee off every shift, by opening a spell with no shift —
  /// which is a real arrangement, not a deletion of their history.
  Future<void> removeFromShift(String employeeId) async {
    final shift = _shift;
    final current = state;
    if (shift == null) return;
    if (current is ShiftRosterLoaded) emit(current.copyWith(isBusy: true));

    final result = await _repo.saveEmployeeWorkSystem(
      SaveEmployeeWorkSystemRequestModel(employeeId: employeeId),
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ShiftRosterActionError(failure.errorMessage));
        if (current is ShiftRosterLoaded) emit(current);
      },
      (_) async {
        emit(const ShiftRosterActionSuccess('تم إخراج الموظف من الوردية'));
        await load(shift);
      },
    );
  }
}
