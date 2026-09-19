import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_flow_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';

sealed class CaseProgressState {
  const CaseProgressState();
}

class CaseProgressInitial extends CaseProgressState {
  const CaseProgressInitial();
}

class CaseProgressLoading extends CaseProgressState {
  const CaseProgressLoading();
}

class CaseProgressError extends CaseProgressState {
  const CaseProgressError(this.message);
  final String message;
}

/// One restoration as the flow describes it, paired with the case-detail row
/// it belongs to.
///
/// The pairing exists because the two answer different questions: the flow
/// carries the frozen route and where the piece stands on it, the detail row
/// carries what the piece *is* (tooth numbers, shade, price) and the server's
/// own `isFinished`. Neither is derivable from the other.
class RestorationProgress {
  const RestorationProgress({required this.flow, this.restoration});

  final CaseFlowRestorationModel flow;

  /// Null only if the case detail and the flow disagree about which pieces
  /// exist — a refetch race. The row still draws from [flow] alone.
  final CaseRestorationModel? restoration;

  String get id => flow.restorationId;

  /// The type name from the flow, falling back to the detail row's label.
  String get title {
    final name = flow.displayName;
    if (name.isNotEmpty) return name;
    return restoration?.restorationName ?? '';
  }

  String? get number =>
      flow.restorationNumber ?? restoration?.restorationNumber;

  String? get currentStageId => flow.currentStage?.stageId;

  /// Server-computed, never derived from position: a piece holding a parallel
  /// step sits on more than one stage at once, which any "is it on the last
  /// one" check on the client gets wrong. Falls back to the flow only when the
  /// detail row is missing.
  bool get isFinished =>
      restoration?.isFinished ??
      (flow.stages.isNotEmpty &&
          flow.stages.every(
            (stage) => stage.status.isDone || stage.status.isSkipped,
          ));
}

/// The board, exactly as the server assembled it.
///
/// Nothing here is computed from a catalogue: `GET /Cases/{id}/flow` already
/// answers where every node sits, and the case's plan is frozen at creation —
/// so a lab editing a route must not redraw a case already travelling it.
class CaseProgressLoaded extends CaseProgressState {
  const CaseProgressLoaded({
    required this.caseDetail,
    required this.flow,
    required this.restorations,
  });

  final CaseDetailModel caseDetail;
  final CaseFlowModel flow;
  final List<RestorationProgress> restorations;

  /// The case's own stages that run alongside the pieces.
  List<CaseFlowStageModel> get beforeStages => flow.beforeStages;

  /// The barrier half: pending until every piece is finished.
  List<CaseFlowStageModel> get afterStages => flow.afterStages;

  List<CaseFlowPhaseModel> get phases => flow.phases;

  bool get isOnFirstHalf =>
      beforeStages.any((stage) => stage.status.isCurrent);

  bool get isOnSecondHalf => afterStages.any((stage) => stage.status.isCurrent);

  /// True once every restoration has finished its route — what the
  /// after-production half waits on.
  bool get restorationsFinished =>
      restorations.isNotEmpty &&
      restorations.every((restoration) => restoration.isFinished);

  /// Whether the pieces are still waiting on the case's own work.
  ///
  /// Standing on the **last** parallel stage releases them: the case cannot
  /// leave that stage except by entering production, and production is what
  /// the restorations are — blocking there too was a deadlock.
  bool get blocksRestorations {
    final index = beforeStages.indexWhere((stage) => stage.status.isCurrent);
    return index >= 0 && index < beforeStages.length - 1;
  }

  /// The after-production stages, while any piece is still running: the case
  /// must not cross the barrier ahead of its own work. Empty once the pieces
  /// are done, or when there are none to wait for.
  Set<String> get barredStageIds => restorations.isEmpty || restorationsFinished
      ? const {}
      : {for (final stage in afterStages) stage.stageId};
}
