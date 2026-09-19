import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';

sealed class WorkflowStagesState {
  const WorkflowStagesState();
}

class WorkflowStagesInitial extends WorkflowStagesState {
  const WorkflowStagesInitial();
}

class WorkflowStagesLoading extends WorkflowStagesState {
  const WorkflowStagesLoading();
}

class WorkflowStagesLoaded extends WorkflowStagesState {
  const WorkflowStagesLoaded(this.stages, {this.isBusy = false});

  final List<CaseWorkflowStageModel> stages;

  /// A write is in flight. Actions disable rather than the list vanishing —
  /// two edits racing on one route is how a plan ends up in a state neither
  /// the user nor the server expected.
  final bool isBusy;

  WorkflowStagesLoaded copyWith({
    List<CaseWorkflowStageModel>? stages,
    bool? isBusy,
  }) => WorkflowStagesLoaded(
    stages ?? this.stages,
    isBusy: isBusy ?? this.isBusy,
  );
}

class WorkflowStagesError extends WorkflowStagesState {
  const WorkflowStagesError(this.message);

  final String message;
}

/// A one-shot message: the cubit emits it, the screen toasts it, and the
/// loaded state comes straight back.
class WorkflowStagesMessage extends WorkflowStagesState {
  const WorkflowStagesMessage(this.message, {this.isError = false});

  final String message;
  final bool isError;
}
