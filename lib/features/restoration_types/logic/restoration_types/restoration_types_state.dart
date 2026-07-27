import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';

sealed class RestorationTypesState {
  const RestorationTypesState();
}

class RestorationTypesInitial extends RestorationTypesState {
  const RestorationTypesInitial();
}

class RestorationTypesLoading extends RestorationTypesState {
  const RestorationTypesLoading();
}

class RestorationTypesLoaded extends RestorationTypesState {
  const RestorationTypesLoaded(this.types);
  final List<RestorationTypeModel> types;
}

class RestorationTypesError extends RestorationTypesState {
  const RestorationTypesError(this.message);
  final String message;
}

class RestorationTypeDeleted extends RestorationTypesState {
  const RestorationTypeDeleted();
}

class RestorationTypeDeleteError extends RestorationTypesState {
  const RestorationTypeDeleteError(this.message);
  final String message;
}
