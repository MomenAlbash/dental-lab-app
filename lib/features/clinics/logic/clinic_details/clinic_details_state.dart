import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';

sealed class ClinicDetailsState {
  const ClinicDetailsState();
}

class ClinicDetailsInitial extends ClinicDetailsState {
  const ClinicDetailsInitial();
}

class ClinicDetailsLoading extends ClinicDetailsState {
  const ClinicDetailsLoading();
}

class ClinicDetailsLoaded extends ClinicDetailsState {
  const ClinicDetailsLoaded(this.clinic);
  final ClinicModel clinic;
}

class ClinicDetailsError extends ClinicDetailsState {
  const ClinicDetailsError(this.message);
  final String message;
}
