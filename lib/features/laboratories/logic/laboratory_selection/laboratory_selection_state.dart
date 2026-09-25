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

/// The account reaches several laboratories — the user picks which to work
/// on: one, or several viewed together.
class LaboratorySelectionLoaded extends LaboratorySelectionState {
  const LaboratorySelectionLoaded(this.laboratories, this.selectedIds);
  final List<LaboratoryModel> laboratories;

  /// In the laboratories' own order, so the first picked is predictable.
  final Set<String> selectedIds;

  bool get allSelected => selectedIds.length == laboratories.length;

  /// Nothing selected is not a scope — every GET would be refused.
  bool get canConfirm => selectedIds.isNotEmpty;
}

class LaboratorySelectionConfirmed extends LaboratorySelectionState {
  const LaboratorySelectionConfirmed(this.laboratories);
  final List<LaboratoryModel> laboratories;
}

/// Nothing to choose from — the session keeps the laboratory it already has.
class LaboratorySelectionSkipped extends LaboratorySelectionState {
  const LaboratorySelectionSkipped();
}

class LaboratorySelectionError extends LaboratorySelectionState {
  const LaboratorySelectionError(this.message);
  final String message;
}
