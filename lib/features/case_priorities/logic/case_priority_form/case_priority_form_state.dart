import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';

sealed class CasePriorityFormState {
  const CasePriorityFormState();
}

class CasePriorityFormInitial extends CasePriorityFormState {
  const CasePriorityFormInitial();
}

class CasePriorityFormSubmitting extends CasePriorityFormState {
  const CasePriorityFormSubmitting();
}

class CasePriorityFormSuccess extends CasePriorityFormState {
  const CasePriorityFormSuccess(this.priority);
  final CasePriorityModel priority;
}

class CasePriorityFormError extends CasePriorityFormState {
  const CasePriorityFormError(this.message);
  final String message;
}
