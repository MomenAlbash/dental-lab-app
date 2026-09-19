import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/manual_payment/manual_payment_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManualPaymentCubit extends Cubit<ManualPaymentState> {
  ManualPaymentCubit(this._accountingRepo)
    : super(const ManualPaymentInitial());

  final AccountingRepo _accountingRepo;

  Future<void> loadInvoicesForDoctor(String doctorId) async {
    emit(const ManualPaymentInvoicesLoading());

    final result = await _accountingRepo.getInvoices(doctorId: doctorId);

    result.fold(
      (failure) => emit(ManualPaymentInvoicesError(failure.errorMessage)),
      (invoices) => emit(ManualPaymentInvoicesLoaded(invoices)),
    );
  }

  Future<void> submit({
    required String invoiceId,
    required String doctorId,
    required double amount,
    PaymentMethod? method,
    String? notes,
    String? receiptFilePath,
  }) async {
    emit(const ManualPaymentSubmitting());

    final result = await _accountingRepo.createManualPayment(
      invoiceId: invoiceId,
      doctorId: doctorId,
      amount: amount,
      method: method,
      notes: notes,
      receiptFilePath: receiptFilePath,
    );

    result.fold(
      (failure) => emit(ManualPaymentError(failure.errorMessage)),
      (payment) => emit(ManualPaymentSuccess(payment)),
    );
  }
}
