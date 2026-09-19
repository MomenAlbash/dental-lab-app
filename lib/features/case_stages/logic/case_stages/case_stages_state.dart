import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';

sealed class CaseStagesState {
  const CaseStagesState();
}

class CaseStagesInitial extends CaseStagesState {
  const CaseStagesInitial();
}

class CaseStagesLoading extends CaseStagesState {
  const CaseStagesLoading();
}

class CaseStagesLoaded extends CaseStagesState {
  const CaseStagesLoaded(this.stages);

  final List<CaseStageModel> stages;
}

class CaseStagesError extends CaseStagesState {
  const CaseStagesError(this.message);
  final String message;
}
