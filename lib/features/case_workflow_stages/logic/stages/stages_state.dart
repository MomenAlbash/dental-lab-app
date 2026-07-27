import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';

sealed class StagesState {
  const StagesState();
}

class StagesInitial extends StagesState {
  const StagesInitial();
}

class StagesLoading extends StagesState {
  const StagesLoading();
}

class StagesLoaded extends StagesState {
  const StagesLoaded(this.stages);
  final List<CaseWorkflowStageModel> stages;
}

class StagesError extends StagesState {
  const StagesError(this.message);
  final String message;
}

class StageDeleted extends StagesState {
  const StageDeleted();
}

class StageDeleteError extends StagesState {
  const StageDeleteError(this.message);
  final String message;
}
