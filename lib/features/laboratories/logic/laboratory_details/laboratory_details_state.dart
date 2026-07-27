import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';

sealed class LaboratoryDetailsState {
  const LaboratoryDetailsState();
}

class LaboratoryDetailsInitial extends LaboratoryDetailsState {
  const LaboratoryDetailsInitial();
}

class LaboratoryDetailsLoading extends LaboratoryDetailsState {
  const LaboratoryDetailsLoading();
}

class LaboratoryDetailsLoaded extends LaboratoryDetailsState {
  const LaboratoryDetailsLoaded(this.laboratory);
  final LaboratoryModel laboratory;
}

class LaboratoryDetailsError extends LaboratoryDetailsState {
  const LaboratoryDetailsError(this.message);
  final String message;
}
