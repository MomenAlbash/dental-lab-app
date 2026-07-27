import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

sealed class DoctorFormState {
  const DoctorFormState();
}

class DoctorFormInitial extends DoctorFormState {
  const DoctorFormInitial();
}

class DoctorFormSubmitting extends DoctorFormState {
  const DoctorFormSubmitting();
}

class DoctorFormSuccess extends DoctorFormState {
  const DoctorFormSuccess(this.doctor);
  final DoctorModel doctor;
}

class DoctorFormError extends DoctorFormState {
  const DoctorFormError(this.message);
  final String message;
}
