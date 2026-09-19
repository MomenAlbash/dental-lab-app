import 'package:dental_lab_app/features/payroll/data/models/payroll_enums.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';

sealed class PayrollState {
  const PayrollState();
}

class PayrollInitial extends PayrollState {
  const PayrollInitial();
}

class PayrollLoading extends PayrollState {
  const PayrollLoading();
}

class PayrollError extends PayrollState {
  const PayrollError(this.message);
  final String message;
}

class PayrollLoaded extends PayrollState {
  const PayrollLoaded({
    required this.statements,
    this.coverage = const [],
    this.statusFilter,
    this.isBusy = false,
  });

  final List<SalaryStatementModel> statements;

  /// Who has no statement yet for their own current period — read alongside
  /// the statements because "three payslips exist" and "two people are still
  /// unpaid" are different questions, and only the second one needs acting on.
  final List<PayrollCoverageEntryModel> coverage;

  final SalaryStatementStatus? statusFilter;
  final bool isBusy;

  /// Employees still missing a statement this period.
  List<PayrollCoverageEntryModel> get uncovered => [
    for (final entry in coverage)
      if (!entry.hasStatement) entry,
  ];

  PayrollLoaded copyWith({bool? isBusy}) => PayrollLoaded(
    statements: statements,
    coverage: coverage,
    statusFilter: statusFilter,
    isBusy: isBusy ?? this.isBusy,
  );
}

class PayrollActionSuccess extends PayrollState {
  const PayrollActionSuccess(this.message);
  final String message;
}

/// A write was refused. The server's own sentence: a statement already
/// approved, a period with no attendance, an employee with no salary system —
/// each has a different answer and the screen must not flatten them.
class PayrollActionError extends PayrollState {
  const PayrollActionError(this.message);
  final String message;
}
