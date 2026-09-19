import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_validation.dart';

sealed class WorkflowEditorState {
  const WorkflowEditorState();
}

class WorkflowEditorLoading extends WorkflowEditorState {
  const WorkflowEditorLoading();
}

class WorkflowEditorError extends WorkflowEditorState {
  const WorkflowEditorError(this.message);

  final String message;
}

/// The workflow being edited.
///
/// Stages are saved one at a time, each on its own endpoint — there is no
/// edge set to draft here any more: the API carries no transition table
/// (`PUT /case-statuses/transitions` answers 404), so the flow is [stages]'
/// own `order`, and a stage's edit takes effect the moment it is saved.
class WorkflowEditorLoaded extends WorkflowEditorState {
  const WorkflowEditorLoaded({
    required this.stages,
    required this.issues,
    this.isBusy = false,
  });

  final List<CaseStageModel> stages;

  /// The server's own verdict on the drawn flow (`GET
  /// /case-statuses/validate`), re-fetched on every [WorkflowEditorCubit.load].
  final List<WorkflowIssue> issues;

  final bool isBusy;

  List<WorkflowIssue> get errors => issues.where((i) => i.isError).toList();

  bool get hasErrors => errors.isNotEmpty;

  /// Issues attached to one stage, so its row can be marked.
  List<WorkflowIssue> issuesFor(String stageId) =>
      issues.where((i) => i.stageId == stageId).toList();

  WorkflowEditorLoaded copyWith({
    List<CaseStageModel>? stages,
    List<WorkflowIssue>? issues,
    bool? isBusy,
  }) => WorkflowEditorLoaded(
    stages: stages ?? this.stages,
    issues: issues ?? this.issues,
    isBusy: isBusy ?? this.isBusy,
  );
}

/// A one-shot message. The editor emits it, the screen toasts it, and the
/// loaded state comes straight back.
class WorkflowEditorMessage extends WorkflowEditorState {
  const WorkflowEditorMessage(this.message, {this.isError = false});

  final String message;
  final bool isError;
}
