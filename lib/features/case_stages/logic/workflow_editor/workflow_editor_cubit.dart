import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/route_problem_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:dental_lab_app/features/case_stages/data/repos/case_stages_repo.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_editor_state.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_validation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the case-workflow editor.
///
/// A stage is created, edited and deleted on its own endpoint and takes
/// effect immediately — there is no second, draft-and-commit save model any
/// more. The API carries no edge table (`PUT /case-statuses/transitions`
/// answers 404): the flow is `order` alone, and what the server thinks of
/// the result comes back from `GET /case-statuses/validate` after every load.
class WorkflowEditorCubit extends Cubit<WorkflowEditorState> {
  WorkflowEditorCubit(this._repo) : super(const WorkflowEditorLoading());

  final CaseStagesRepo _repo;

  Future<void> load() async {
    emit(const WorkflowEditorLoading());

    final result = await _repo.getCaseStages();
    if (isClosed) return;

    await result.fold(
      (failure) async => emit(WorkflowEditorError(failure.errorMessage)),
      (stages) async {
        // Secondary data: a failed validation check should not block the
        // editor from opening, so a failure here just leaves the workflow
        // unannotated rather than replacing the whole screen with an error.
        final problems = await _repo.validateWorkflow();
        if (isClosed) return;

        emit(
          WorkflowEditorLoaded(
            stages: stages,
            issues: problems.fold((_) => const [], _toIssues),
          ),
        );
      },
    );
  }

  static List<WorkflowIssue> _toIssues(List<RouteProblemModel> problems) => [
    for (final problem in problems)
      WorkflowIssue(
        // Everything this endpoint reports is a real defect — a case that
        // would silently stop — not a style suggestion, so every row is an
        // error rather than a warning.
        severity: WorkflowIssueSeverity.error,
        message: problem.displayMessage,
        stageId: problem.stageId,
      ),
  ];

  Future<void> saveStage({
    String? id,
    required SaveCaseStageRequestModel body,
  }) async {
    final current = state;
    if (current is WorkflowEditorLoaded) emit(current.copyWith(isBusy: true));

    final result = id == null
        ? await _repo.createStage(body)
        : await _repo.updateStage(id: id, body: body);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(WorkflowEditorMessage(failure.errorMessage, isError: true));
        if (current is WorkflowEditorLoaded) {
          emit(current.copyWith(isBusy: false));
        }
      },
      (_) async {
        emit(
          WorkflowEditorMessage(
            id == null ? 'تمت إضافة المرحلة' : 'تم تعديل المرحلة',
          ),
        );
        await load();
      },
    );
  }

  /// Deletes a stage.
  ///
  /// Refused locally while cases are sitting on it — the server refuses too,
  /// and deactivating is the answer the user actually wants there: the stage
  /// leaves the picker and stays on the cases already filed under it, so last
  /// quarter's reports still read.
  Future<void> deleteStage(CaseStageModel stage) async {
    // Captured before any emit: once the message below is emitted, `state`
    // is the message itself, not the loaded screen — grabbing `current`
    // after it (as this used to) meant the `is WorkflowEditorLoaded` check
    // that follows always failed, so the recovery emit never ran and the
    // page was left stuck on the message state forever.
    final current = state;

    if (stage.caseCount > 0) {
      emit(
        WorkflowEditorMessage(
          'لا يمكن حذف "${stage.displayName}" ويوجد ${stage.caseCount} حالة '
          'عليها — عطّلها بدلاً من ذلك',
          isError: true,
        ),
      );
      if (current is WorkflowEditorLoaded) emit(current);
      return;
    }

    if (current is WorkflowEditorLoaded) emit(current.copyWith(isBusy: true));

    final result = await _repo.deleteStage(stage.id);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(WorkflowEditorMessage(failure.errorMessage, isError: true));
        if (current is WorkflowEditorLoaded) {
          emit(current.copyWith(isBusy: false));
        }
      },
      (_) async {
        emit(const WorkflowEditorMessage('تم حذف المرحلة'));
        await load();
      },
    );
  }

  /// Rewrites who staffs one stage.
  ///
  /// Its own endpoint rather than part of [saveStage]: a roster changes far
  /// more often than the workflow does, and usually at the hand of somebody
  /// who has no business touching the rules — pushing it through the full
  /// body would make every staffing edit a chance to clobber them.
  ///
  /// Each list replaces its set; a null side is left alone.
  Future<void> setAssignments({
    required String id,
    List<String>? departmentIds,
    List<String>? userIds,
  }) async {
    final current = state;
    if (current is WorkflowEditorLoaded) emit(current.copyWith(isBusy: true));

    final result = await _repo.setAssignments(
      id: id,
      departmentIds: departmentIds,
      userIds: userIds,
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(WorkflowEditorMessage(failure.errorMessage, isError: true));
        if (current is WorkflowEditorLoaded) {
          emit(current.copyWith(isBusy: false));
        }
      },
      (_) async {
        emit(const WorkflowEditorMessage('تم حفظ المسؤولين عن المرحلة'));
        await load();
      },
    );
  }

  Future<void> seedDefaults() async {
    final current = state;
    if (current is WorkflowEditorLoaded) emit(current.copyWith(isBusy: true));

    final result = await _repo.seedDefaults();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(WorkflowEditorMessage(failure.errorMessage, isError: true));
        if (current is WorkflowEditorLoaded) {
          emit(current.copyWith(isBusy: false));
        }
      },
      (_) async {
        emit(const WorkflowEditorMessage('تمت إضافة مسار عمل مبدئي'));
        await load();
      },
    );
  }
}
