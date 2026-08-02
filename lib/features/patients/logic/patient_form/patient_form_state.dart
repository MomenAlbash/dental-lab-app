import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';

sealed class PatientFormState {
  const PatientFormState();
}

class PatientFormInitial extends PatientFormState {
  const PatientFormInitial();
}

class PatientFormSubmitting extends PatientFormState {
  const PatientFormSubmitting();
}

class PatientFormSuccess extends PatientFormState {
  const PatientFormSuccess(this.patient);
  final PatientModel patient;
}

class PatientFormError extends PatientFormState {
  const PatientFormError(this.message);
  final String message;
}
