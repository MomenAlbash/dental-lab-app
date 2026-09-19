import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/payroll/data/models/payroll_enums.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:dental_lab_app/features/payroll/data/repos/payroll_repo.dart';
import 'package:dental_lab_app/features/payroll/logic/payroll/payroll_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Payroll statements, and running payroll to produce them.
///
/// The period is never chosen here: payroll runs for whatever standard window
/// each employee's own pay cycle resolves to around an **anchor date**, so a
/// weekly and a monthly employee generated in the same call get different
/// periods. The screen picks a date, not a range.
class PayrollCubit extends Cubit<PayrollState> {
  PayrollCubit(this._repo) : super(const PayrollInitial());

  final PayrollRepo _repo;

  SalaryStatementStatus? _statusFilter;
  DateTime _anchorDate = DateTime.now();

  DateTime get anchorDate => _anchorDate;
  SalaryStatementStatus? get statusFilter => _statusFilter;

  Future<void> load({
    DateTime? anchorDate,
    SalaryStatementStatus? status,
    bool clearStatus = false,
  }) async {
    _anchorDate = anchorDate ?? _anchorDate;
    if (clearStatus) {
      _statusFilter = null;
    } else if (status != null) {
      _statusFilter = status;
    }

    emit(const PayrollLoading());

    // Started together: the statements are the screen, the coverage is the
    // "who is still owed one" strip above them, and two round-trips in
    // sequence would make the second arrive visibly late.
    final statementsRequest = _repo.getStatements(status: _statusFilter);
    final coverageRequest = _repo.getCoverage(anchorDate: _anchorDate);

    final statements = await statementsRequest;
    final coverage = await coverageRequest;
    if (isClosed) return;

    statements.fold(
      (failure) => emit(PayrollError(failure.errorMessage)),
      (list) => emit(
        PayrollLoaded(
          statements: list,
          // A failed coverage read hides the strip rather than the screen:
          // the statements are still worth reading on their own.
          coverage: coverage.fold((_) => const [], (entries) => entries),
          statusFilter: _statusFilter,
        ),
      ),
    );
  }

  Future<void> toggleStatus(SalaryStatementStatus status) async {
    if (_statusFilter == status) {
      await load(clearStatus: true);
      return;
    }
    await load(status: status);
  }

  /// Runs payroll around [anchorDate] for everyone, or for [employeeIds].
  Future<void> generate({
    required DateTime anchorDate,
    List<String>? employeeIds,
  }) async {
    _anchorDate = anchorDate;
    await _write(
      'تم توليد كشوف الرواتب',
      () => _repo.generatePayroll(
        GeneratePayrollRequestModel(
          anchorDate: anchorDate,
          employeeIds: employeeIds,
        ),
      ),
    );
  }

  /// Signs a statement off. This **closes** the days it covers: a punch
  /// landing on one of them afterwards is refused rather than silently
  /// changing an approved payslip.
  Future<void> approve(String id) =>
      _write('تم اعتماد كشف الراتب', () => _repo.approveStatement(id));

  Future<void> markPaid(String id) =>
      _write('تم تعليم الكشف كمدفوع', () => _repo.markStatementPaid(id));

  /// Reopens an approved period, which is how a corrected punch or a
  /// back-dated leave finally gets accounted for.
  Future<void> revert(String id) => _write(
    'أُعيد الكشف إلى مسودة',
    () => _repo.revertStatement(id),
  );

  /// Drafts only — the server refuses anything already approved or paid.
  Future<void> delete(String id) =>
      _write('تم حذف المسودة', () => _repo.deleteStatement(id));

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final current = state;
    if (current is PayrollLoaded) emit(current.copyWith(isBusy: true));

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(PayrollActionError(failure.errorMessage));
        if (current is PayrollLoaded) emit(current);
      },
      (_) async {
        emit(PayrollActionSuccess(successMessage));
        await load();
      },
    );
  }
}
