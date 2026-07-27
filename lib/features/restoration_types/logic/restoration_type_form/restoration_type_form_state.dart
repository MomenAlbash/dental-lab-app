import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';

sealed class RestorationTypeFormState {
  const RestorationTypeFormState();
}

class RestorationTypeFormInitial extends RestorationTypeFormState {
  const RestorationTypeFormInitial();
}

class RestorationTypeFormSubmitting extends RestorationTypeFormState {
  const RestorationTypeFormSubmitting();
}

class RestorationTypeFormSuccess extends RestorationTypeFormState {
  const RestorationTypeFormSuccess(this.type);
  final RestorationTypeModel type;
}

class RestorationTypeFormError extends RestorationTypeFormState {
  const RestorationTypeFormError(this.message);
  final String message;
}
