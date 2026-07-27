import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_details/laboratory_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Backs both the laboratory details screen and "مختبري" — the only
/// difference is which endpoint the laboratory is loaded from.
class LaboratoryDetailsCubit extends Cubit<LaboratoryDetailsState> {
  LaboratoryDetailsCubit(this._laboratoriesRepo)
    : super(const LaboratoryDetailsInitial());

  final LaboratoriesRepo _laboratoriesRepo;

  Future<void> getLaboratoryById(String id) async {
    emit(const LaboratoryDetailsLoading());

    final result = await _laboratoriesRepo.getLaboratoryById(id);

    result.fold(
      (failure) => emit(LaboratoryDetailsError(failure.errorMessage)),
      (laboratory) => emit(LaboratoryDetailsLoaded(laboratory)),
    );
  }

  Future<void> getOwnLaboratory() async {
    emit(const LaboratoryDetailsLoading());

    final result = await _laboratoriesRepo.getOwnLaboratory();

    result.fold(
      (failure) => emit(LaboratoryDetailsError(failure.errorMessage)),
      (laboratory) => emit(LaboratoryDetailsLoaded(laboratory)),
    );
  }
}
