import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';

sealed class ScannerRulesState {
  const ScannerRulesState();
}

class ScannerRulesInitial extends ScannerRulesState {
  const ScannerRulesInitial();
}

class ScannerRulesLoading extends ScannerRulesState {
  const ScannerRulesLoading();
}

class ScannerRulesLoaded extends ScannerRulesState {
  const ScannerRulesLoaded(this.rules);
  final List<ScannerAvailabilityRuleModel> rules;
}

class ScannerRulesError extends ScannerRulesState {
  const ScannerRulesError(this.message);
  final String message;
}

/// A create/update is in flight. Kept apart from [ScannerRulesLoading] so the
/// list stays on screen behind the dialog instead of flashing a skeleton.
class ScannerRuleSaving extends ScannerRulesState {
  const ScannerRuleSaving();
}

class ScannerRuleSaved extends ScannerRulesState {
  const ScannerRuleSaved();
}

class ScannerRuleSaveError extends ScannerRulesState {
  const ScannerRuleSaveError(this.message);
  final String message;
}

class ScannerRuleDeleted extends ScannerRulesState {
  const ScannerRuleDeleted();
}

class ScannerRuleDeleteError extends ScannerRulesState {
  const ScannerRuleDeleteError(this.message);
  final String message;
}
