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
  const CitiesLoaded(this.cities);
  final List<CityModel> cities;
}

class CitiesError extends CitiesState {
  const CitiesError(this.message);
  final String message;
}
