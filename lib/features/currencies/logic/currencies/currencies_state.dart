import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

sealed class CurrenciesState {
  const CurrenciesState();
}

class CurrenciesInitial extends CurrenciesState {
  const CurrenciesInitial();
}

class CurrenciesLoading extends CurrenciesState {
  const CurrenciesLoading();
}

class CurrenciesLoaded extends CurrenciesState {
  const CurrenciesLoaded(this.currencies, {this.isBusy = false});
  final List<CurrencyModel> currencies;

  /// True while a create/update/delete is in flight.
  final bool isBusy;
}

class CurrenciesError extends CurrenciesState {
  const CurrenciesError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class CurrenciesActionError extends CurrenciesState {
  const CurrenciesActionError(this.message);
  final String message;
}
