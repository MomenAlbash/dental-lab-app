import 'dart:developer';

import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/inventory/data/repos/inventory_repo.dart';
import 'package:dental_lab_app/features/purchases/data/models/create_purchase_request_model.dart';
import 'package:dental_lab_app/features/purchases/data/repos/purchases_repo.dart';
import 'package:dental_lab_app/features/purchases/logic/purchase_form/purchase_form_state.dart';
import 'package:dental_lab_app/features/suppliers/data/repos/suppliers_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchaseFormCubit extends Cubit<PurchaseFormState> {
  PurchaseFormCubit(
    this._purchasesRepo,
    this._suppliersRepo,
    this._inventoryRepo,
    this._accountingRepo,
  ) : super(const PurchaseFormInitial());

  final PurchasesRepo _purchasesRepo;
  final SuppliersRepo _suppliersRepo;
  final InventoryRepo _inventoryRepo;
  final AccountingRepo _accountingRepo;

  Future<void> loadCatalog() async {
    emit(const PurchaseFormCatalogLoading());

    final suppliersResult = await _suppliersRepo.getSuppliers();
    final itemsResult = await _inventoryRepo.getInventoryItems();
    final currenciesResult = await _accountingRepo.getCurrencies();

    suppliersResult.fold(
      (failure) => emit(PurchaseFormCatalogError(failure.errorMessage)),
      (suppliers) => itemsResult.fold(
        (failure) => emit(PurchaseFormCatalogError(failure.errorMessage)),
        (items) => currenciesResult.fold(
          (failure) => emit(PurchaseFormCatalogError(failure.errorMessage)),
          (currencies) => emit(
            PurchaseFormCatalogLoaded(
              suppliers: suppliers,
              inventoryItems: items,
              currencies: currencies,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submit(CreatePurchaseRequestModel requestBody) async {
    emit(const PurchaseFormSubmitting());

    final result = await _purchasesRepo.createPurchase(requestBody);
    result.fold((failure) {
      log('Failed to record purchase: ${failure.errorMessage}');
      emit(PurchaseFormError(failure.errorMessage));
    }, (purchase) => emit(PurchaseFormSuccess(purchase)));
  }
}
