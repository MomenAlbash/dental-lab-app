import 'package:dental_lab_app/features/case_workflow_stages/data/models/create_case_workflow_stage_request_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/update_case_workflow_stage_request_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/repos/case_workflow_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/stage_form/stage_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StageFormCubit extends Cubit<StageFormState> {
  StageFormCubit(this._stagesRepo) : super(const StageFormInitial());

  final CaseWorkflowStagesRepo _stagesRepo;

  Future<void> createStage(
    CreateCaseWorkflowStageRequestModel createStageRequestBody,
  ) async {
    emit(const StageFormSubmitting());

    final result = await _stagesRepo.createStage(createStageRequestBody);

    result.fold(
      (failure) => emit(StageFormError(failure.errorMessage)),
      (stage) => emit(StageFormSuccess(stage)),
    );
  }

  Future<void> updateStage({
    required String id,
    required UpdateCaseWorkflowStageRequestModel updateStageRequestBody,
  }) async {
    emit(const StageFormSubmitting());

    final result = await _stagesRepo.updateStage(
      id: id,
      updateStageRequestBody: updateStageRequestBody,
    );

    result.fold(
      (failure) => emit(StageFormError(failure.errorMessage)),
      (stage) => emit(StageFormSuccess(stage)),
    );
  }
}
