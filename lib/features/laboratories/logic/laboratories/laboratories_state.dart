import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';

sealed class LaboratoriesState {
  const LaboratoriesState();
}

class LaboratoriesInitial extends LaboratoriesState {
  const LaboratoriesInitial();
}

class LaboratoriesLoading extends LaboratoriesState {
  const LaboratoriesLoading();
}

class LaboratoriesLoaded extends LaboratoriesState {
  const LaboratoriesLoaded(this.laboratories);
  final List<LaboratoryModel> laboratories;
}

class LaboratoriesError extends LaboratoriesState {
  const LaboratoriesError(this.message);
  final String message;
}

class LaboratoryDeleted extends LaboratoriesState {
  const LaboratoryDeleted();
}

class LaboratoryDeleteError extends LaboratoriesState {
  const LaboratoryDeleteError(this.message);
  final String message;
}
