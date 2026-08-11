import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RestorationTypesCubit extends Cubit<RestorationTypesState> {
  RestorationTypesCubit(this._repo) : super(const RestorationTypesInitial());

  final RestorationTypesRepo _repo;

  Future<void> getRestorationTypes() async {
    emit(const RestorationTypesLoading());

    final result = await _repo.getRestorationTypes();

    result.fold(
      (failure) => emit(RestorationTypesError(failure.errorMessage)),
      (types) => emit(RestorationTypesLoaded(types)),
    );
  }

  Future<void> deleteRestorationType(String id) async {
    final result = await _repo.deleteRestorationType(id);

    await result.fold(
      (failure) async => emit(RestorationTypeDeleteError(failure.errorMessage)),
      (_) async {
        emit(const RestorationTypeDeleted());
        await getRestorationTypes();
      },
    );
  }
}
