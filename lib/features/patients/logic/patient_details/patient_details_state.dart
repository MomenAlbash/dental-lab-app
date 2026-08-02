import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';

sealed class PatientDetailsState {
  const PatientDetailsState();
}

class PatientDetailsInitial extends PatientDetailsState {
  const PatientDetailsInitial();
}

class PatientDetailsLoading extends PatientDetailsState {
  const PatientDetailsLoading();
}

class PatientDetailsLoaded extends PatientDetailsState {
  const PatientDetailsLoaded(this.patient);
  final PatientModel patient;
}

class PatientDetailsError extends PatientDetailsState {
  const PatientDetailsError(this.message);
  final String message;
}
