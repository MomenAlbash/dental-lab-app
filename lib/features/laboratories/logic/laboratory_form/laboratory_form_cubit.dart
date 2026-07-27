import 'package:dental_lab_app/features/laboratories/data/models/create_laboratory_request_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/update_laboratory_request_model.dart';
import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_form/laboratory_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LaboratoryFormCubit extends Cubit<LaboratoryFormState> {
  LaboratoryFormCubit(this._laboratoriesRepo)
    : super(const LaboratoryFormInitial());

  final LaboratoriesRepo _laboratoriesRepo;

  Future<void> createLaboratory(
    CreateLaboratoryRequestModel createLaboratoryRequestBody,
  ) async {
    emit(const LaboratoryFormSubmitting());

    final result = await _laboratoriesRepo.createLaboratory(
      createLaboratoryRequestBody,
    );

    result.fold(
      (failure) => emit(LaboratoryFormError(failure.errorMessage)),
      (laboratory) => emit(LaboratoryFormSuccess(laboratory)),
    );
  }

  Future<void> updateLaboratory({
    required String id,
    required UpdateLaboratoryRequestModel updateLaboratoryRequestBody,
  }) async {
    emit(const LaboratoryFormSubmitting());

    final result = await _laboratoriesRepo.updateLaboratory(
      id: id,
      updateLaboratoryRequestBody: updateLaboratoryRequestBody,
    );

    result.fold(
      (failure) => emit(LaboratoryFormError(failure.errorMessage)),
      (laboratory) => emit(LaboratoryFormSuccess(laboratory)),
    );
  }
}
