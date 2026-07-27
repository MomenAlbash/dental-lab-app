import 'package:dental_lab_app/features/doctors/data/models/create_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_form/doctor_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoctorFormCubit extends Cubit<DoctorFormState> {
  DoctorFormCubit(this._doctorsRepo) : super(const DoctorFormInitial());

  final DoctorsRepo _doctorsRepo;

  Future<void> createDoctor(
    CreateDoctorRequestModel createDoctorRequestBody,
  ) async {
    emit(const DoctorFormSubmitting());

    final result = await _doctorsRepo.createDoctor(createDoctorRequestBody);

    result.fold(
      (failure) => emit(DoctorFormError(failure.errorMessage)),
      (doctor) => emit(DoctorFormSuccess(doctor)),
    );
  }

  Future<void> updateDoctor({
    required String id,
    required UpdateDoctorRequestModel updateDoctorRequestBody,
  }) async {
    emit(const DoctorFormSubmitting());

    final result = await _doctorsRepo.updateDoctor(
      id: id,
      updateDoctorRequestBody: updateDoctorRequestBody,
    );

    result.fold(
      (failure) => emit(DoctorFormError(failure.errorMessage)),
      (doctor) => emit(DoctorFormSuccess(doctor)),
    );
  }
}
