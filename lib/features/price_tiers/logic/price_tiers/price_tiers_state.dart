import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';

sealed class PriceTiersState {
  const PriceTiersState();
}

class PriceTiersInitial extends PriceTiersState {
  const PriceTiersInitial();
}

class PriceTiersLoading extends PriceTiersState {
  const PriceTiersLoading();
}

class PriceTiersLoaded extends PriceTiersState {
  const PriceTiersLoaded(this.tiers);
  final List<PriceTierModel> tiers;
}

class PriceTiersError extends PriceTiersState {
  const PriceTiersError(this.message);
  final String message;
}

class PriceTierDeleted extends PriceTiersState {
  const PriceTierDeleted();
}

class PriceTierDeleteError extends PriceTiersState {
  const PriceTierDeleteError(this.message);
  final String message;
}
