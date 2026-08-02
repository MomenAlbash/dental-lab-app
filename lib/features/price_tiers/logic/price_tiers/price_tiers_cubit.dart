import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tiers/price_tiers_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceTiersCubit extends Cubit<PriceTiersState> {
  PriceTiersCubit(this._repo) : super(const PriceTiersInitial());

  final PriceTiersRepo _repo;

  Future<void> getPriceTiers() async {
    emit(const PriceTiersLoading());

    final result = await _repo.getPriceTiers();

    result.fold(
      (failure) => emit(PriceTiersError(failure.errorMessage)),
      (tiers) => emit(PriceTiersLoaded(tiers)),
    );
  }

  Future<void> deletePriceTier(String id) async {
    final result = await _repo.deletePriceTier(id);

    await result.fold(
      (failure) async => emit(PriceTierDeleteError(failure.errorMessage)),
      (_) async {
        emit(const PriceTierDeleted());
        await getPriceTiers();
      },
    );
  }
}
