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
}
