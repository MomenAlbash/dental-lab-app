import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';

/// What a scanned restoration is asking of the person holding it.
sealed class ScanTaskState {
  const ScanTaskState();
}

class ScanTaskLoading extends ScanTaskState {
  const ScanTaskLoading();
}

class ScanTaskError extends ScanTaskState {
  const ScanTaskError(this.message);
  final String message;
}

/// The piece, its stage, and the move on offer.
///
/// Deliberately one state for every outcome rather than a state per case: the
/// screen always shows the same card, and what changes is which of these
/// fields is filled. A "not yours" answer is not an error state — it is this
/// state with [refusal] set.
class ScanTaskReady extends ScanTaskState {
  const ScanTaskReady({
    required this.caseDetail,
    required this.restoration,
    this.currentStage,
    this.currentStageName,
    this.nextStages = const [],
    this.isSubmitting = false,
    this.refusal,
    this.isDone = false,
  });

  final CaseDetailModel caseDetail;
  final CaseRestorationModel restoration;

  /// The stage the piece sits on, when the response carried it expanded.
  final CaseWorkflowStageModel? currentStage;

  /// The stage's name however it could be resolved — from the expanded
  /// object, or looked up in the type's route by id. Null when neither
  /// worked, which is the case the screen has to survive rather than hide:
  /// the move can still be attempted, and the server's refusal names the
  /// stage itself.
  final String? currentStageName;

  /// The step this piece moves onto next. More than one entry means a
  /// parallel step — the piece enters all of them at once, so they are
  /// announced together rather than offered as a choice.
  final List<CaseWorkflowStageModel> nextStages;

  final bool isSubmitting;

  /// The server's own words when it refused the move. Set on a `403`, which
  /// is how the API says "this stage is not yours" — the only answer there is
  /// about work assignment, since nothing tells the client beforehand.
  final String? refusal;

  /// The move went through. The piece has left this person's hands.
  final bool isDone;

  /// Whether there is anything to hand this person to do.
  bool get hasNextStep => nextStages.isNotEmpty;

  /// The piece has finished its route — nothing follows the stage it is on.
  bool get isAtEndOfRoute => !hasNextStep && !isDone;

  String get nextStageLabel => nextStages
      .map((stage) => stage.displayName)
      .where((n) => n.isNotEmpty)
      .join(' + ');

  ScanTaskReady copyWith({
    CaseDetailModel? caseDetail,
    CaseRestorationModel? restoration,
    CaseWorkflowStageModel? currentStage,
    String? currentStageName,
    List<CaseWorkflowStageModel>? nextStages,
    bool? isSubmitting,
    String? refusal,
    bool clearRefusal = false,
    bool? isDone,
  }) {
    return ScanTaskReady(
      caseDetail: caseDetail ?? this.caseDetail,
      restoration: restoration ?? this.restoration,
      currentStage: currentStage ?? this.currentStage,
      currentStageName: currentStageName ?? this.currentStageName,
      nextStages: nextStages ?? this.nextStages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      refusal: clearRefusal ? null : (refusal ?? this.refusal),
      isDone: isDone ?? this.isDone,
    );
  }
}
