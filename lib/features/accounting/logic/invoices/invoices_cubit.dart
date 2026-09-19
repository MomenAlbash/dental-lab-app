import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/invoices/invoices_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvoicesCubit extends Cubit<InvoicesState> {
  InvoicesCubit(this._accountingRepo) : super(const InvoicesInitial());

  final AccountingRepo _accountingRepo;

  Future<void> getInvoices({
    String? doctorId,
    InvoiceStatus? status,
    String? search,
  }) async {
    emit(const InvoicesLoading());

    final result = await _accountingRepo.getInvoices(
      doctorId: doctorId,
      status: status,
      search: search,
    );

    result.fold(
      (failure) => emit(InvoicesError(failure.errorMessage)),
      (invoices) => emit(InvoicesLoaded(invoices)),
    );
  }
}
