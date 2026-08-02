import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatientFormCubit extends Cubit<PatientFormState> {
  PatientFormCubit(this._patientsRepo) : super(const PatientFormInitial());

  final PatientsRepo _patientsRepo;

  Future<void> createPatient(
    CreatePatientRequestModel createPatientRequestBody,
  ) async {
    emit(const PatientFormSubmitting());

    final result = await _patientsRepo.createPatient(createPatientRequestBody);

    result.fold(
      (failure) => emit(PatientFormError(failure.errorMessage)),
      (patient) => emit(PatientFormSuccess(patient)),
    );
  }
}
