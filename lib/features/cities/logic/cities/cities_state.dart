import 'package:dental_lab_app/features/cities/data/models/city_model.dart';

sealed class CitiesState {
  const CitiesState();
}

class CitiesInitial extends CitiesState {
  const CitiesInitial();
}

class CitiesLoading extends CitiesState {
  const CitiesLoading();
}

class CitiesLoaded extends CitiesState {
  const CitiesLoaded(this.cities, {this.isBusy = false});
  final List<CityModel> cities;

  /// True while a create/update/delete is in flight.
  final bool isBusy;
}

class CitiesError extends CitiesState {
  const CitiesError(this.message);
  final String message;
}

/// Transient failure of an action — surfaced as a toast.
class CitiesActionError extends CitiesState {
  const CitiesActionError(this.message);
  final String message;
}
