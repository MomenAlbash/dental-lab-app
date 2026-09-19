import 'package:dental_lab_app/features/suppliers/data/models/save_supplier_request_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';
import 'package:dental_lab_app/features/suppliers/data/repos/suppliers_repo.dart';
import 'package:dental_lab_app/features/suppliers/logic/suppliers/suppliers_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SuppliersCubit extends Cubit<SuppliersState> {
  SuppliersCubit(this._suppliersRepo) : super(const SuppliersInitial());

  final SuppliersRepo _suppliersRepo;

  Future<void> getSuppliers({bool includeInactive = false}) async {
    emit(const SuppliersLoading());

    final result = await _suppliersRepo.getSuppliers(
      includeInactive: includeInactive,
    );

    result.fold(
      (failure) => emit(SuppliersError(failure.errorMessage)),
      (suppliers) => emit(SuppliersLoaded(suppliers)),
    );
  }

  List<SupplierModel> get _currentList => switch (state) {
    SuppliersLoaded(:final suppliers) => suppliers,
    _ => const [],
  };

  Future<void> addSupplier(SaveSupplierRequestModel requestBody) async {
    final suppliers = _currentList;
    emit(SuppliersLoaded(suppliers, isBusy: true));

    final result = await _suppliersRepo.createSupplier(requestBody);

    result.fold((failure) {
      emit(SuppliersActionError(failure.errorMessage));
      emit(SuppliersLoaded(suppliers));
    }, (created) => emit(SuppliersLoaded([...suppliers, created])));
  }

  Future<void> editSupplier({
    required String id,
    required SaveSupplierRequestModel requestBody,
  }) async {
    final suppliers = _currentList;
    emit(SuppliersLoaded(suppliers, isBusy: true));

    final result = await _suppliersRepo.updateSupplier(
      id: id,
      requestBody: requestBody,
    );

    result.fold(
      (failure) {
        emit(SuppliersActionError(failure.errorMessage));
        emit(SuppliersLoaded(suppliers));
      },
      (updated) => emit(
        SuppliersLoaded([
          for (final supplier in suppliers)
            if (supplier.id == id) updated else supplier,
        ]),
      ),
    );
  }

  Future<void> removeSupplier(String id) async {
    final suppliers = _currentList;
    emit(SuppliersLoaded(suppliers, isBusy: true));

    final result = await _suppliersRepo.deleteSupplier(id);

    result.fold(
      (failure) {
        emit(SuppliersActionError(failure.errorMessage));
        emit(SuppliersLoaded(suppliers));
      },
      (_) => emit(SuppliersLoaded(suppliers.where((s) => s.id != id).toList())),
    );
  }
}
