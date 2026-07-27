import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';

sealed class DoctorsState {
  const DoctorsState();
}

class DoctorsInitial extends DoctorsState {
  const DoctorsInitial();
}

class DoctorsLoading extends DoctorsState {
  const DoctorsLoading();
}

class DoctorsLoaded extends DoctorsState {
  const DoctorsLoaded(this.doctors);
  final List<DoctorModel> doctors;
}

class DoctorsError extends DoctorsState {
  const DoctorsError(this.message);
  final String message;
}

class DoctorDeleted extends DoctorsState {
  const DoctorDeleted();
}

class DoctorDeleteError extends DoctorsState {
  const DoctorDeleteError(this.message);
  final String message;
}
