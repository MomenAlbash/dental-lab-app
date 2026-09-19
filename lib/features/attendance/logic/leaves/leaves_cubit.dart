import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/attendance/data/repos/attendance_repo.dart';
import 'package:dental_lab_app/features/attendance/logic/leaves/leaves_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The leave queue: requests to decide, and leaves to record on someone's
/// behalf.
///
/// Every write reloads rather than patching the row it touched. A decision
/// changes the attendance of every day the leave covers — and can change
/// whether a draft payslip still matches — so the list this screen shows is
/// downstream of more than the row itself.
class LeavesCubit extends Cubit<LeavesState> {
  LeavesCubit(this._repo) : super(const LeavesInitial());

  final AttendanceRepo _repo;

  LeaveStatus? _statusFilter;
  DateTime? _from;
  DateTime? _to;
  String? _employeeId;

  LeaveStatus? get statusFilter => _statusFilter;

  Future<void> load({
    LeaveStatus? status,
    bool clearStatus = false,
    DateTime? from,
    DateTime? to,
    String? employeeId,
    bool clearWindow = false,
  }) async {
    if (clearStatus) {
      _statusFilter = null;
    } else if (status != null) {
      _statusFilter = status;
    }
    if (clearWindow) {
      _from = null;
      _to = null;
    } else {
      _from = from ?? _from;
      _to = to ?? _to;
    }
    _employeeId = employeeId ?? _employeeId;

    emit(const LeavesLoading());

    final result = await _repo.getLeaves(
      employeeId: _employeeId,
      status: _statusFilter,
      from: _from,
      to: _to,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(LeavesError(failure.errorMessage)),
      (leaves) => emit(
        LeavesLoaded(
          leaves,
          statusFilter: _statusFilter,
          from: _from,
          to: _to,
        ),
      ),
    );
  }

  /// Selects — or, when already on, clears — the status filter.
  Future<void> toggleStatus(LeaveStatus status) async {
    if (_statusFilter == status) {
      await load(clearStatus: true);
      return;
    }
    await load(status: status);
  }

  /// Approve or refuse one request.
  Future<void> decide({required String id, required bool approve}) => _write(
    approve ? 'تمت الموافقة على الإجازة' : 'تم رفض الإجازة',
    () => _repo.decideLeave(id: id, approve: approve),
  );

  Future<void> createLeave(CreateLeaveRequestModel body) =>
      _write('تم تسجيل الإجازة', () => _repo.createLeave(body));

  Future<void> updateLeave({
    required String id,
    required SaveLeaveRequestModel body,
  }) => _write(
    'تم تعديل الإجازة',
    () => _repo.updateLeave(id: id, body: body),
  );

  /// Deleting a leave re-opens every day it excused, which is why it is a
  /// confirmed action on the screen rather than a swipe.
  Future<void> deleteLeave(String id) =>
      _write('تم حذف الإجازة', () => _repo.deleteLeave(id));

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final current = state;
    if (current is LeavesLoaded) emit(current.copyWith(isBusy: true));

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(LeavesActionError(failure.errorMessage));
        if (current is LeavesLoaded) emit(current);
      },
      (_) async {
        emit(LeavesActionSuccess(successMessage));
        await load();
      },
    );
  }
}
