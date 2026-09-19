import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/pending_payments/pending_payments_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PendingPaymentsCubit extends Cubit<PendingPaymentsState> {
  PendingPaymentsCubit(this._accountingRepo)
    : super(const PendingPaymentsInitial());

  final AccountingRepo _accountingRepo;

  Future<void> getPendingPayments() async {
    emit(const PendingPaymentsLoading());

    final result = await _accountingRepo.getPendingPayments();

    result.fold(
      (failure) => emit(PendingPaymentsError(failure.errorMessage)),
      (payments) => emit(PendingPaymentsLoaded(payments)),
    );
  }

  /// Removes the payment from the pending list optimistically once
  /// approved/rejected — the confirm step already happened in the sheet
  /// that collected the note. Rolled back (with a toast) if the server
  /// call fails.
  Future<void> verify({
    required String id,
    required bool approve,
    String? notes,
  }) async {
    final state = this.state;
    if (state is! PendingPaymentsLoaded) return;

    final previous = state.payments;
    emit(
      PendingPaymentsLoaded([
        for (final p in previous)
          if (p.id != id) p,
      ], isBusy: true),
    );

    final result = await _accountingRepo.verifyPayment(
      id: id,
      approve: approve,
      notes: notes,
    );

    result.fold(
      (failure) {
        emit(PendingPaymentsLoaded(previous));
        emit(PendingPaymentsActionError(failure.errorMessage));
      },
      (_) => emit(
        PendingPaymentsLoaded(previous.where((p) => p.id != id).toList()),
      ),
    );
  }
}
