import 'package:dental_lab_app/features/price_tiers/data/models/create_price_tier_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/update_price_tier_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_form/price_tier_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceTierFormCubit extends Cubit<PriceTierFormState> {
  PriceTierFormCubit(this._repo) : super(const PriceTierFormInitial());

  final PriceTiersRepo _repo;

  Future<void> createPriceTier(
    CreatePriceTierRequestModel createRequestBody,
  ) async {
    emit(const PriceTierFormSubmitting());

    final result = await _repo.createPriceTier(createRequestBody);

    result.fold(
      (failure) => emit(PriceTierFormError(failure.errorMessage)),
      (tier) => emit(PriceTierFormSuccess(tier)),
    );
  }

  Future<void> updatePriceTier({
    required String id,
    required UpdatePriceTierRequestModel updateRequestBody,
  }) async {
    emit(const PriceTierFormSubmitting());

    final result = await _repo.updatePriceTier(
      id: id,
      updateRequestBody: updateRequestBody,
    );

    result.fold(
      (failure) => emit(PriceTierFormError(failure.errorMessage)),
      (tier) => emit(PriceTierFormSuccess(tier)),
    );
  }
}
