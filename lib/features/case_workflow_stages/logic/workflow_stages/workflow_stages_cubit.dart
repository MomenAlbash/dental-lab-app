import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/repos/workflow_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/workflow_stages/workflow_stages_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the stage catalogue of one restoration type's route.
///
/// Unlike the case-workflow editor, there is no draft here: each stage has its
/// own endpoint and takes effect on save. The edges of a *restoration* route
/// are edited separately (`PUT /routing/routes/transitions`) and are not this
/// cubit's business.
class WorkflowStagesCubit extends Cubit<WorkflowStagesState> {
  WorkflowStagesCubit(this._repo) : super(const WorkflowStagesInitial());

  final WorkflowStagesRepo _repo;

  String? _restorationTypeId;

  String? get restorationTypeId => _restorationTypeId;

  /// Kept so a failed write can put the list back rather than replacing a
  /// working screen with an error.
  List<CaseWorkflowStageModel> _lastLoaded = const [];

  Future<void> load({String? restorationTypeId}) async {
    _restorationTypeId = restorationTypeId ?? _restorationTypeId;
    emit(const WorkflowStagesLoading());

    final result = await _repo.getStages(restorationTypeId: _restorationTypeId);
    if (isClosed) return;

    result.fold((failure) => emit(WorkflowStagesError(failure.errorMessage)), (
      stages,
    ) {
      _lastLoaded = _sorted(stages);
      emit(WorkflowStagesLoaded(_lastLoaded));
    });
  }

  Future<void> createStage(CreateWorkflowStageRequestModel body) =>
      _run('تمت إضافة المرحلة', () => _repo.createStage(body));

  Future<void> updateStage({
    required String id,
    required UpdateWorkflowStageRequestModel body,
  }) => _run('تم تعديل المرحلة', () => _repo.updateStage(id: id, body: body));

  /// Deactivates rather than deletes.
  ///
  /// A retired stage leaves the route and stays on the restorations already
  /// running it, so their history still reads. Offered as the safe alternative
  /// wherever a delete would be refused.
  Future<void> deactivateStage(CaseWorkflowStageModel stage) => _run(
    'تم تعطيل المرحلة',
    () => _repo.updateStage(
      id: stage.id,
      body: const UpdateWorkflowStageRequestModel(isActive: false),
    ),
  );

  Future<void> deleteStage(String id) =>
      _run('تم حذف المرحلة', () => _repo.deleteStage(id));

  Future<void> _run<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() action,
  ) async {
    final current = state;
    if (current is WorkflowStagesLoaded) emit(current.copyWith(isBusy: true));

    final result = await action();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(WorkflowStagesMessage(failure.errorMessage, isError: true));
        emit(WorkflowStagesLoaded(_lastLoaded));
      },
      (_) async {
        emit(WorkflowStagesMessage(successMessage));
        await load();
      },
    );
  }

  /// By the lab's own `order`, then by name. `order` is a canvas position and
  /// a tie-break — it is not the flow, which the edge set owns.
  static List<CaseWorkflowStageModel> _sorted(
    List<CaseWorkflowStageModel> stages,
  ) {
    final sorted = [...stages];
    sorted.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.displayName.compareTo(b.displayName);
    });
    return sorted;
  }
}
