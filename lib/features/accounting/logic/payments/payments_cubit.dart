import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/payments/payments_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentsCubit extends Cubit<PaymentsState> {
  PaymentsCubit(this._accountingRepo) : super(const PaymentsInitial());

  final AccountingRepo _accountingRepo;

  String? _doctorId;

  Future<void> getPayments({String? doctorId}) async {
    _doctorId = doctorId ?? _doctorId;
    emit(const PaymentsLoading());

    final result = await _accountingRepo.getPayments(doctorId: _doctorId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(PaymentsError(failure.errorMessage)),
      (payments) => emit(PaymentsLoaded(payments)),
    );
  }

  /// Removes a payment permanently.
  ///
  /// Reloads rather than dropping the row locally: deleting a payment reopens
  /// the invoice it was against, and the rest of the list's totals move with
  /// it — a client that just removed the row would show a list that no longer
  /// adds up.
  Future<void> deletePayment(String id) async {
    final result = await _accountingRepo.deletePayment(id);
    if (isClosed) return;

    await result.fold(
      (failure) async => emit(PaymentDeleteError(failure.errorMessage)),
      (_) async {
        emit(const PaymentDeleted());
        await getPayments();
      },
    );
  }
}
