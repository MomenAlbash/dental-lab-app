import 'package:dental_lab_app/features/accounting/data/models/doctor_statement_model.dart';

sealed class DoctorStatementState {
  const DoctorStatementState();
}

class DoctorStatementInitial extends DoctorStatementState {
  const DoctorStatementInitial();
}

class DoctorStatementLoading extends DoctorStatementState {
  const DoctorStatementLoading();
}

class DoctorStatementLoaded extends DoctorStatementState {
  const DoctorStatementLoaded(this.statement, {this.isBusy = false});

  final DoctorStatementModel statement;

  /// A settle is in flight. The statement stays on screen — the numbers are
  /// what the user is deciding against, and blanking them mid-decision is
  /// worse than a disabled button.
  final bool isBusy;
}

class DoctorStatementError extends DoctorStatementState {
  const DoctorStatementError(this.message);
  final String message;
}

/// A bulk settle went through — the statement it answers with is already the
/// refreshed one, so there is nothing left to refetch.
class DoctorStatementActionSuccess extends DoctorStatementState {
  const DoctorStatementActionSuccess(this.message);
  final String message;
}

class DoctorStatementActionError extends DoctorStatementState {
  const DoctorStatementActionError(this.message);
  final String message;
}
