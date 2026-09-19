import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';

sealed class SuppliersState {
  const SuppliersState();
}

class SuppliersInitial extends SuppliersState {
  const SuppliersInitial();
}

class SuppliersLoading extends SuppliersState {
  const SuppliersLoading();
}

class SuppliersLoaded extends SuppliersState {
  const SuppliersLoaded(this.suppliers, {this.isBusy = false});
  final List<SupplierModel> suppliers;

  /// True while a create/update/delete is in flight.
  final bool isBusy;
}

class SuppliersError extends SuppliersState {
  const SuppliersError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class SuppliersActionError extends SuppliersState {
  const SuppliersActionError(this.message);
  final String message;
}
