import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';

sealed class ClinicFormState {
  const ClinicFormState();
}

class ClinicFormInitial extends ClinicFormState {
  const ClinicFormInitial();
}

class ClinicFormSubmitting extends ClinicFormState {
  const ClinicFormSubmitting();
}

class ClinicFormSuccess extends ClinicFormState {
  const ClinicFormSuccess(this.clinic);
  final ClinicModel clinic;
}

class ClinicFormError extends ClinicFormState {
  const ClinicFormError(this.message);
  final String message;
}
