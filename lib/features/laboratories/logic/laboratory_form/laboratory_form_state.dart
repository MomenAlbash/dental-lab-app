import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';

sealed class LaboratoryFormState {
  const LaboratoryFormState();
}

class LaboratoryFormInitial extends LaboratoryFormState {
  const LaboratoryFormInitial();
}

class LaboratoryFormSubmitting extends LaboratoryFormState {
  const LaboratoryFormSubmitting();
}

class LaboratoryFormSuccess extends LaboratoryFormState {
  const LaboratoryFormSuccess(this.laboratory);
  final LaboratoryModel laboratory;
}

class LaboratoryFormError extends LaboratoryFormState {
  const LaboratoryFormError(this.message);
  final String message;
}
