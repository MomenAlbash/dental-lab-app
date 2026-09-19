import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';

sealed class PurchaseFormState {
  const PurchaseFormState();
}

class PurchaseFormInitial extends PurchaseFormState {
  const PurchaseFormInitial();
}

class PurchaseFormCatalogLoading extends PurchaseFormState {
  const PurchaseFormCatalogLoading();
}

/// The suppliers, inventory items and currencies the form can offer —
/// loaded once, independent of submission.
class PurchaseFormCatalogLoaded extends PurchaseFormState {
  const PurchaseFormCatalogLoaded({
    required this.suppliers,
    required this.inventoryItems,
    required this.currencies,
  });

  final List<SupplierModel> suppliers;
  final List<InventoryItemModel> inventoryItems;
  final List<CurrencyModel> currencies;
}

class PurchaseFormCatalogError extends PurchaseFormState {
  const PurchaseFormCatalogError(this.message);
  final String message;
}

class PurchaseFormSubmitting extends PurchaseFormState {
  const PurchaseFormSubmitting();
}

class PurchaseFormSuccess extends PurchaseFormState {
  const PurchaseFormSuccess(this.purchase);
  final PurchaseModel purchase;
}

class PurchaseFormError extends PurchaseFormState {
  const PurchaseFormError(this.message);
  final String message;
}
