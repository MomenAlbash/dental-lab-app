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

/// Emitted the moment a delete succeeds, before the reload that follows — so
/// the page can say so while the fresh list is still on its way.
class PatientDeleted extends PatientsState {
  const PatientDeleted();
}

/// A failed delete, kept separate from [PatientsError]: the list itself is
/// still fine and must stay on screen.
class PatientDeleteError extends PatientsState {
  const PatientDeleteError(this.message);
  final String message;
}
