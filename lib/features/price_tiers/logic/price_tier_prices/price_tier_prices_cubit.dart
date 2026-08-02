import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_prices_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_prices/price_tier_prices_state.dart';
import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads every restoration type alongside this tier's current prices (0 for
/// types not priced yet) and lets the user edit/save them as a batch.
class PriceTierPricesCubit extends Cubit<PriceTierPricesState> {
  PriceTierPricesCubit(this._priceTiersRepo, this._restorationTypesRepo)
    : super(const PriceTierPricesInitial());

  final PriceTiersRepo _priceTiersRepo;
  final RestorationTypesRepo _restorationTypesRepo;

  String? _tierId;

  Future<void> load(String tierId) async {
    _tierId = tierId;
    emit(const PriceTierPricesLoading());

    final tierResult = await _priceTiersRepo.getPriceTierById(tierId);
    final typesResult = await _restorationTypesRepo.getRestorationTypes();

    tierResult.fold(
      (failure) => emit(PriceTierPricesError(failure.errorMessage)),
      (tier) => typesResult.fold(
        (failure) => emit(PriceTierPricesError(failure.errorMessage)),
        (types) {
          final pricesByTypeId = {
            for (final p in tier.restorationPrices)
              p.restorationTypeId: p.price,
          };

          final items = [
            for (final type in types)
              PriceTierPriceItem(
                restorationTypeId: type.id,
                restorationTypeName: type.displayName,
                price: pricesByTypeId[type.id] ?? 0,
              ),
          ];

          emit(PriceTierPricesLoaded(items));
        },
      ),
    );
  }

  void setPrice(int index, double price) {
    final state = this.state;
    if (state is! PriceTierPricesLoaded) return;

    final items = [
      for (var i = 0; i < state.items.length; i++)
        i == index ? state.items[i].copyWith(price: price) : state.items[i],
    ];
    emit(PriceTierPricesLoaded(items, isBusy: state.isBusy));
  }

  Future<void> save() async {
    final tierId = _tierId;
    final state = this.state;
    if (tierId == null || state is! PriceTierPricesLoaded) return;

    emit(PriceTierPricesLoaded(state.items, isBusy: true));

    final result = await _priceTiersRepo.setPrices(
      id: tierId,
      setPricesRequestBody: SetPriceTierPricesRequestModel(
        prices: [
          for (final item in state.items)
            if (item.price > 0)
              PriceTierRestorationPriceRequestModel(
                restorationTypeId: item.restorationTypeId,
                price: item.price,
              ),
        ],
      ),
    );

    result.fold(
      (failure) {
        emit(PriceTierPricesActionError(failure.errorMessage));
        emit(PriceTierPricesLoaded(state.items));
      },
      (_) {
        emit(const PriceTierPricesActionSuccess('تم حفظ الأسعار'));
        emit(PriceTierPricesLoaded(state.items));
      },
    );
  }
}
