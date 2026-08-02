import 'package:dental_lab_app/features/countries/data/models/country_model.dart';

sealed class CountriesState {
  const CountriesState();
}

class CountriesInitial extends CountriesState {
  const CountriesInitial();
}

class CountriesLoading extends CountriesState {
  const CountriesLoading();
}

class CountriesLoaded extends CountriesState {
  const CountriesLoaded(this.countries, {this.isBusy = false});

  final List<CountryModel> countries;

  /// True while a create/update/delete is in flight.
  final bool isBusy;
}

class CountriesError extends CountriesState {
  const CountriesError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class CountriesActionError extends CountriesState {
  const CountriesActionError(this.message);
  final String message;
}
