import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';

sealed class PatientsState {
  const PatientsState();
}

class PatientsInitial extends PatientsState {
  const PatientsInitial();
}

class PatientsLoading extends PatientsState {
  const PatientsLoading();
}

class PatientsLoaded extends PatientsState {
  const PatientsLoaded(this.patients);
  final List<PatientModel> patients;
}

class PatientsError extends PatientsState {
  const PatientsError(this.message);
  final String message;
}
