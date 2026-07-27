import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';

sealed class ClinicsState {
  const ClinicsState();
}

class ClinicsInitial extends ClinicsState {
  const ClinicsInitial();
}

class ClinicsLoading extends ClinicsState {
  const ClinicsLoading();
}

class ClinicsLoaded extends ClinicsState {
  const ClinicsLoaded(this.clinics);
  final List<ClinicModel> clinics;
}

class ClinicsError extends ClinicsState {
  const ClinicsError(this.message);
  final String message;
}

class ClinicDeleted extends ClinicsState {
  const ClinicDeleted();
}

class ClinicDeleteError extends ClinicsState {
  const ClinicDeleteError(this.message);
  final String message;
}
