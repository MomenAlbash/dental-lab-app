import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patient_details/patient_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatientDetailsCubit extends Cubit<PatientDetailsState> {
  PatientDetailsCubit(this._patientsRepo)
    : super(const PatientDetailsInitial());

  final PatientsRepo _patientsRepo;

  Future<void> getPatient(String id) async {
    emit(const PatientDetailsLoading());

    final result = await _patientsRepo.getPatientById(id);

    result.fold(
      (failure) => emit(PatientDetailsError(failure.errorMessage)),
      (patient) => emit(PatientDetailsLoaded(patient)),
    );
  }
}
