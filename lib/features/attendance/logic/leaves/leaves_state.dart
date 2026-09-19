import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';

sealed class LeavesState {
  const LeavesState();
}

class LeavesInitial extends LeavesState {
  const LeavesInitial();
}

class LeavesLoading extends LeavesState {
  const LeavesLoading();
}

class LeavesError extends LeavesState {
  const LeavesError(this.message);
  final String message;
}

class LeavesLoaded extends LeavesState {
  const LeavesLoaded(
    this.leaves, {
    this.statusFilter,
    this.from,
    this.to,
    this.isBusy = false,
  });

  final List<LeaveModel> leaves;

  /// Null means every status — the filter chip row's "الكل".
  final LeaveStatus? statusFilter;

  final DateTime? from;
  final DateTime? to;

  /// A decision is in flight. The list stays put and only the actions
  /// disable: approving one request should not blank the queue behind it.
  final bool isBusy;

  /// Requests still waiting on somebody — what the screen leads with, and the
  /// count the badge shows even when it is zero.
  int get pendingCount => leaves.where((leave) => leave.isPending).length;

  LeavesLoaded copyWith({bool? isBusy}) => LeavesLoaded(
    leaves,
    statusFilter: statusFilter,
    from: from,
    to: to,
    isBusy: isBusy ?? this.isBusy,
  );
}

class LeavesActionSuccess extends LeavesState {
  const LeavesActionSuccess(this.message);
  final String message;
}

/// A write was refused. Carries the server's own sentence — overlapping
/// leaves, a closed payroll period and a missing permission are all its rules
/// to state, and "failed" would hide which one was hit.
class LeavesActionError extends LeavesState {
  const LeavesActionError(this.message);
  final String message;
}
