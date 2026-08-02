import 'package:dental_lab_app/features/countries/data/models/country_model.dart';
import 'package:dental_lab_app/features/countries/data/repos/countries_repo.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CountriesCubit extends Cubit<CountriesState> {
  CountriesCubit(this._countriesRepo) : super(const CountriesInitial());

  final CountriesRepo _countriesRepo;

  Future<void> getCountries() async {
    emit(const CountriesLoading());

    final result = await _countriesRepo.getCountries();

    result.fold(
      (failure) => emit(CountriesError(failure.errorMessage)),
      (countries) => emit(CountriesLoaded(countries)),
    );
  }

  List<CountryModel> get _currentList =>
      switch (state) { CountriesLoaded(:final countries) => countries, _ => const [] };

  Future<void> addCountry(String name) async {
    final countries = _currentList;
    emit(CountriesLoaded(countries, isBusy: true));

    final result = await _countriesRepo.createCountry(name);

    result.fold((failure) {
      emit(CountriesActionError(failure.errorMessage));
      emit(CountriesLoaded(countries));
    }, (created) => emit(CountriesLoaded([...countries, created])));
  }

  Future<void> editCountry({required String id, required String name}) async {
    final countries = _currentList;
    emit(CountriesLoaded(countries, isBusy: true));

    final result = await _countriesRepo.updateCountry(id: id, name: name);

    result.fold((failure) {
      emit(CountriesActionError(failure.errorMessage));
      emit(CountriesLoaded(countries));
    }, (updated) => emit(CountriesLoaded([
          for (final c in countries) if (c.id == id) updated else c,
        ])));
  }

  Future<void> removeCountry(String id) async {
    final countries = _currentList;
    emit(CountriesLoaded(countries, isBusy: true));

    final result = await _countriesRepo.deleteCountry(id);

    result.fold((failure) {
      emit(CountriesActionError(failure.errorMessage));
      emit(CountriesLoaded(countries));
    }, (_) => emit(CountriesLoaded(countries.where((c) => c.id != id).toList())));
  }
}
