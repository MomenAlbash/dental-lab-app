import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';

sealed class LaboratorySelectionState {
  const LaboratorySelectionState();
}

class LaboratorySelectionInitial extends LaboratorySelectionState {
  const LaboratorySelectionInitial();
}

class LaboratorySelectionLoading extends LaboratorySelectionState {
  const LaboratorySelectionLoading();
}

/// The account owns several laboratories — the user picks which one to
/// operate as.
class LaboratorySelectionLoaded extends LaboratorySelectionState {
  const LaboratorySelectionLoaded(this.laboratories, this.selectedId);
  final List<LaboratoryModel> laboratories;
  final String? selectedId;
}

class LaboratorySelectionConfirmed extends LaboratorySelectionState {
  const LaboratorySelectionConfirmed(this.laboratory);
  final LaboratoryModel laboratory;
}

/// Nothing to choose from — the session keeps the laboratory it already has.
class LaboratorySelectionSkipped extends LaboratorySelectionState {
  const LaboratorySelectionSkipped();
}

class LaboratorySelectionError extends LaboratorySelectionState {
  const LaboratorySelectionError(this.message);
  final String message;
}
