import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';

sealed class InventoryState {
  const InventoryState();
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  const InventoryLoaded(this.items, {this.isBusy = false});
  final List<InventoryItemModel> items;

  /// True while a create/update/delete is in flight.
  final bool isBusy;
}

class InventoryError extends InventoryState {
  const InventoryError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class InventoryActionError extends InventoryState {
  const InventoryActionError(this.message);
  final String message;
}
