import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_type_form/restoration_type_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RestorationTypeFormCubit extends Cubit<RestorationTypeFormState> {
  RestorationTypeFormCubit(this._repo)
    : super(const RestorationTypeFormInitial());

  final RestorationTypesRepo _repo;

  Future<void> createRestorationType(
    CreateRestorationTypeRequestModel createRequestBody,
  ) async {
    emit(const RestorationTypeFormSubmitting());

    final result = await _repo.createRestorationType(createRequestBody);

    result.fold(
      (failure) => emit(RestorationTypeFormError(failure.errorMessage)),
      (type) => emit(RestorationTypeFormSuccess(type)),
    );
  }

  Future<void> updateRestorationType({
    required String id,
    required UpdateRestorationTypeRequestModel updateRequestBody,
  }) async {
    emit(const RestorationTypeFormSubmitting());

    final result = await _repo.updateRestorationType(
      id: id,
      updateRequestBody: updateRequestBody,
    );

    result.fold(
      (failure) => emit(RestorationTypeFormError(failure.errorMessage)),
      (type) => emit(RestorationTypeFormSuccess(type)),
    );
  }
}
