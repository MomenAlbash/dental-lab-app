sealed class PriorityAllowanceState {
  const PriorityAllowanceState();
}

class PriorityAllowanceIdle extends PriorityAllowanceState {
  const PriorityAllowanceIdle();
}

/// A bulk apply in flight.
///
/// The allowance endpoint takes one doctor at a time, so handing an allowance
/// to a whole city is N requests. Progress is reported rather than hidden
/// behind a spinner: the user needs to know it is halfway, not stuck.
class PriorityAllowanceApplying extends PriorityAllowanceState {
  const PriorityAllowanceApplying({required this.done, required this.total});

  final int done;
  final int total;

  double get fraction => total == 0 ? 0 : done / total;
}

/// The apply finished. [failed] is empty on a clean run.
///
/// A partial result is a real outcome here, not an error: some doctors got
/// their allowance and some did not, and saying only "failed" would hide the
/// ones that succeeded.
class PriorityAllowanceDone extends PriorityAllowanceState {
  const PriorityAllowanceDone({
    required this.succeeded,
    required this.failed,
    required this.firstError,
  });

  final int succeeded;

  /// Names of the doctors whose allowance could not be set.
  final List<String> failed;

  /// The reason the first failure gave, so the toast can say more than a
  /// count.
  final String? firstError;

  bool get isClean => failed.isEmpty;
}
