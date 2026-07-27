import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';

sealed class StageFormState {
  const StageFormState();
}

class StageFormInitial extends StageFormState {
  const StageFormInitial();
}

class StageFormSubmitting extends StageFormState {
  const StageFormSubmitting();
}

class StageFormSuccess extends StageFormState {
  const StageFormSuccess(this.stage);
  final CaseWorkflowStageModel stage;
}

class StageFormError extends StageFormState {
  const StageFormError(this.message);
  final String message;
}
