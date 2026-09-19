import 'dart:developer';

import 'package:dental_lab_app/features/accounting/data/models/create_invoice_request_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/invoice_form/invoice_form_state.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvoiceFormCubit extends Cubit<InvoiceFormState> {
  InvoiceFormCubit(this._accountingRepo, this._doctorsRepo)
    : super(const InvoiceFormInitial());

  final AccountingRepo _accountingRepo;
  final DoctorsRepo _doctorsRepo;

  Future<void> loadCatalog() async {
    emit(const InvoiceFormCatalogLoading());

    final doctorsResult = await _doctorsRepo.getDoctors();
    final currenciesResult = await _accountingRepo.getCurrencies();

    doctorsResult.fold(
      (failure) => emit(InvoiceFormCatalogError(failure.errorMessage)),
      (doctors) => currenciesResult.fold(
        (failure) => emit(InvoiceFormCatalogError(failure.errorMessage)),
        (currencies) => emit(
          InvoiceFormCatalogLoaded(doctors: doctors, currencies: currencies),
        ),
      ),
    );
  }

  Future<void> submit(CreateInvoiceRequestModel requestBody) async {
    emit(const InvoiceFormSubmitting());

    final result = await _accountingRepo.createInvoice(requestBody);
    result.fold((failure) {
      log('Failed to create invoice: ${failure.errorMessage}');
      emit(InvoiceFormError(failure.errorMessage));
    }, (invoice) => emit(InvoiceFormSuccess(invoice)));
  }
}
