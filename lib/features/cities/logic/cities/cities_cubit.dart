import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/cities/data/repos/cities_repo.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CitiesCubit extends Cubit<CitiesState> {
  CitiesCubit(this._citiesRepo) : super(const CitiesInitial());

  final CitiesRepo _citiesRepo;

  Future<void> getCities() async {
    emit(const CitiesLoading());

    final result = await _citiesRepo.getCities();

    result.fold(
      (failure) => emit(CitiesError(failure.errorMessage)),
      (cities) => emit(CitiesLoaded(cities)),
    );
  }

  List<CityModel> get _currentList => switch (state) {
    CitiesLoaded(:final cities) => cities,
    _ => const [],
  };

  Future<void> addCity({required String name, String? countryId}) async {
    final cities = _currentList;
    emit(CitiesLoaded(cities, isBusy: true));

    final result = await _citiesRepo.createCity(
      name: name,
      countryId: countryId,
    );

    result.fold((failure) {
      emit(CitiesActionError(failure.errorMessage));
      emit(CitiesLoaded(cities));
    }, (created) => emit(CitiesLoaded([...cities, created])));
  }

  Future<void> editCity({
    required String id,
    required String name,
    String? countryId,
  }) async {
    final cities = _currentList;
    emit(CitiesLoaded(cities, isBusy: true));

    final result = await _citiesRepo.updateCity(
      id: id,
      name: name,
      countryId: countryId,
    );

    result.fold(
      (failure) {
        emit(CitiesActionError(failure.errorMessage));
        emit(CitiesLoaded(cities));
      },
      (updated) => emit(
        CitiesLoaded([
          for (final c in cities)
            if (c.id == id) updated else c,
        ]),
      ),
    );
  }

  Future<void> removeCity(String id) async {
    final cities = _currentList;
    emit(CitiesLoaded(cities, isBusy: true));

    final result = await _citiesRepo.deleteCity(id);

    result.fold((failure) {
      emit(CitiesActionError(failure.errorMessage));
      emit(CitiesLoaded(cities));
    }, (_) => emit(CitiesLoaded(cities.where((c) => c.id != id).toList())));
  }
}
