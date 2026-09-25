import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';

sealed class StageRatesState {
  const StageRatesState();
}

class StageRatesLoading extends StageRatesState {
  const StageRatesLoading();
}

class StageRatesError extends StageRatesState {
  const StageRatesError(this.message);
  final String message;
}

/// The price list, plus whatever has been edited and not saved yet.
class StageRatesLoaded extends StageRatesState {
  const StageRatesLoaded({
    required this.types,
    this.drafts = const {},
    this.isSaving = false,
  });

  final List<StagePayRestorationTypeModel> types;

  /// Unsaved edits, keyed by root stage id.
  final Map<String, StagePayRateDraft> drafts;

  final bool isSaving;

  bool get hasChanges => drafts.isNotEmpty;

  /// The stage's price as the screen should show it — the draft if edited.
  StagePayRateDraft priceOf(StagePayRateModel stage) =>
      drafts[stage.rootStageId] ??
      StagePayRateDraft(amount: stage.amount, basis: stage.basis);
}

/// One-shot outcomes of a save, shown as a toast and never built.
class StageRatesSaved extends StageRatesState {
  const StageRatesSaved();
}

class StageRatesSaveError extends StageRatesState {
  const StageRatesSaveError(this.message);
  final String message;
}
