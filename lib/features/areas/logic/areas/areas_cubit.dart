import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/areas/data/models/save_area_request_models.dart';
import 'package:dental_lab_app/features/areas/data/repos/areas_repo.dart';
import 'package:dental_lab_app/features/areas/logic/areas/areas_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AreasCubit extends Cubit<AreasState> {
  AreasCubit(this._areasRepo) : super(const AreasInitial());

  final AreasRepo _areasRepo;

  Future<void> getAreas({String? cityId}) async {
    emit(const AreasLoading());

    final result = await _areasRepo.getAreas(cityId: cityId);

    result.fold(
      (failure) => emit(AreasError(failure.errorMessage)),
      (areas) => emit(AreasLoaded(areas)),
    );
  }

  List<AreaModel> get _currentList => switch (state) {
    AreasLoaded(:final areas) => areas,
    _ => const [],
  };

  Future<void> addArea(CreateAreaRequestModel requestBody) async {
    final areas = _currentList;
    emit(AreasLoaded(areas, isBusy: true));

    final result = await _areasRepo.createArea(requestBody);

    result.fold((failure) {
      emit(AreasActionError(failure.errorMessage));
      emit(AreasLoaded(areas));
    }, (created) => emit(AreasLoaded([...areas, created])));
  }

  Future<void> editArea({
    required String id,
    required UpdateAreaRequestModel requestBody,
  }) async {
    final areas = _currentList;
    emit(AreasLoaded(areas, isBusy: true));

    final result = await _areasRepo.updateArea(
      id: id,
      requestBody: requestBody,
    );

    result.fold(
      (failure) {
        emit(AreasActionError(failure.errorMessage));
        emit(AreasLoaded(areas));
      },
      (updated) => emit(
        AreasLoaded([
          for (final a in areas)
            if (a.id == id) updated else a,
        ]),
      ),
    );
  }

  Future<void> removeArea(String id) async {
    final areas = _currentList;
    emit(AreasLoaded(areas, isBusy: true));

    final result = await _areasRepo.deleteArea(id);

    result.fold((failure) {
      emit(AreasActionError(failure.errorMessage));
      emit(AreasLoaded(areas));
    }, (_) => emit(AreasLoaded(areas.where((a) => a.id != id).toList())));
  }
}
