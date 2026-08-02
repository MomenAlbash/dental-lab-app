import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';

sealed class PriceTierFormState {
  const PriceTierFormState();
}

class PriceTierFormInitial extends PriceTierFormState {
  const PriceTierFormInitial();
}

class PriceTierFormSubmitting extends PriceTierFormState {
  const PriceTierFormSubmitting();
}

class PriceTierFormSuccess extends PriceTierFormState {
  const PriceTierFormSuccess(this.tier);
  final PriceTierModel tier;
}

class PriceTierFormError extends PriceTierFormState {
  const PriceTierFormError(this.message);
  final String message;
}
