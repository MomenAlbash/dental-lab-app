import 'package:dental_lab_app/features/clinics/data/models/create_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/update_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClinicFormCubit extends Cubit<ClinicFormState> {
  ClinicFormCubit(this._clinicsRepo) : super(const ClinicFormInitial());

  final ClinicsRepo _clinicsRepo;

  Future<void> createClinic(
    CreateClinicRequestModel createClinicRequestBody,
  ) async {
    emit(const ClinicFormSubmitting());

    final result = await _clinicsRepo.createClinic(createClinicRequestBody);

    result.fold(
      (failure) => emit(ClinicFormError(failure.errorMessage)),
      (clinic) => emit(ClinicFormSuccess(clinic)),
    );
  }

  Future<void> updateClinic({
    required String id,
    required UpdateClinicRequestModel updateClinicRequestBody,
  }) async {
    emit(const ClinicFormSubmitting());

    final result = await _clinicsRepo.updateClinic(
      id: id,
      updateClinicRequestBody: updateClinicRequestBody,
    );

    result.fold(
      (failure) => emit(ClinicFormError(failure.errorMessage)),
      (clinic) => emit(ClinicFormSuccess(clinic)),
    );
  }
}
