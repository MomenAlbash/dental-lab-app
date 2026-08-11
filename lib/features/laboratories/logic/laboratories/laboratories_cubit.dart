import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LaboratoriesCubit extends Cubit<LaboratoriesState> {
  LaboratoriesCubit(this._laboratoriesRepo)
    : super(const LaboratoriesInitial());

  final LaboratoriesRepo _laboratoriesRepo;

  String? get activeLaboratoryId => _laboratoriesRepo.activeLaboratoryId;

  Future<void> getLaboratories() async {
    emit(const LaboratoriesLoading());

    final result = await _laboratoriesRepo.getLaboratories();

    result.fold(
      (failure) => emit(LaboratoriesError(failure.errorMessage)),
      (laboratories) => emit(LaboratoriesLoaded(laboratories)),
    );
  }

  Future<void> deleteLaboratory(String id) async {
    final result = await _laboratoriesRepo.deleteLaboratory(id);

    await result.fold(
      (failure) async => emit(LaboratoryDeleteError(failure.errorMessage)),
      (_) async {
        emit(const LaboratoryDeleted());
        await getLaboratories();
      },
    );
  }
}
