import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/save_inventory_item_request_model.dart';
import 'package:dental_lab_app/features/inventory/data/repos/inventory_repo.dart';
import 'package:dental_lab_app/features/inventory/logic/inventory/inventory_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit(this._inventoryRepo) : super(const InventoryInitial());

  final InventoryRepo _inventoryRepo;

  Future<void> getInventoryItems({bool includeInactive = false}) async {
    emit(const InventoryLoading());

    final result = await _inventoryRepo.getInventoryItems(
      includeInactive: includeInactive,
    );

    result.fold(
      (failure) => emit(InventoryError(failure.errorMessage)),
      (items) => emit(InventoryLoaded(items)),
    );
  }

  List<InventoryItemModel> get _currentList => switch (state) {
    InventoryLoaded(:final items) => items,
    _ => const [],
  };

  Future<void> addItem(SaveInventoryItemRequestModel requestBody) async {
    final items = _currentList;
    emit(InventoryLoaded(items, isBusy: true));

    final result = await _inventoryRepo.createInventoryItem(requestBody);

    result.fold((failure) {
      emit(InventoryActionError(failure.errorMessage));
      emit(InventoryLoaded(items));
    }, (created) => emit(InventoryLoaded([...items, created])));
  }

  Future<void> editItem({
    required String id,
    required SaveInventoryItemRequestModel requestBody,
  }) async {
    final items = _currentList;
    emit(InventoryLoaded(items, isBusy: true));

    final result = await _inventoryRepo.updateInventoryItem(
      id: id,
      requestBody: requestBody,
    );

    result.fold(
      (failure) {
        emit(InventoryActionError(failure.errorMessage));
        emit(InventoryLoaded(items));
      },
      (updated) => emit(
        InventoryLoaded([
          for (final item in items)
            if (item.id == id) updated else item,
        ]),
      ),
    );
  }

  Future<void> removeItem(String id) async {
    final items = _currentList;
    emit(InventoryLoaded(items, isBusy: true));

    final result = await _inventoryRepo.deleteInventoryItem(id);

    result.fold((failure) {
      emit(InventoryActionError(failure.errorMessage));
      emit(InventoryLoaded(items));
    }, (_) => emit(InventoryLoaded(items.where((i) => i.id != id).toList())));
  }
}
