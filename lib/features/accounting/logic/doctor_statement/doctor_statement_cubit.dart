import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/doctor_statement/doctor_statement_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorStatementCubit extends Cubit<DoctorStatementState> {
  DoctorStatementCubit(this._accountingRepo)
    : super(const DoctorStatementInitial());

  final AccountingRepo _accountingRepo;

  String? _doctorId;

  Future<void> getStatement(String doctorId) async {
    _doctorId = doctorId;
    emit(const DoctorStatementLoading());

    final result = await _accountingRepo.getDoctorStatement(doctorId: doctorId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(DoctorStatementError(failure.errorMessage)),
      (statement) => emit(DoctorStatementLoaded(statement)),
    );
  }

  /// Closes every outstanding invoice this doctor has **in one currency**.
  ///
  /// Per currency, because nothing in this app blends money across currencies:
  /// a doctor can owe in two and settle one of them today. The server answers
  /// with the statement as it now stands, so the screen takes that rather than
  /// asking again.
  Future<void> settle({
    required String currencyId,
    PaymentMethod? method,
    String? notes,
  }) async {
    final doctorId = _doctorId;
    final current = state;
    if (doctorId == null || current is! DoctorStatementLoaded) return;

    emit(DoctorStatementLoaded(current.statement, isBusy: true));

    final result = await _accountingRepo.settleDoctorBalance(
      doctorId: doctorId,
      currencyId: currencyId,
      method: method,
      notes: notes,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(DoctorStatementActionError(failure.errorMessage));
        emit(DoctorStatementLoaded(current.statement));
      },
      (statement) {
        emit(const DoctorStatementActionSuccess('تمت تسوية الحساب'));
        emit(DoctorStatementLoaded(statement));
      },
    );
  }
}
