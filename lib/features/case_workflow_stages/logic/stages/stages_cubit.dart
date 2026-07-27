import 'package:dental_lab_app/features/case_workflow_stages/data/repos/case_workflow_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/stages/stages_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StagesCubit extends Cubit<StagesState> {
  StagesCubit(this._stagesRepo) : super(const StagesInitial());

  final CaseWorkflowStagesRepo _stagesRepo;

  Future<void> getStages() async {
    emit(const StagesLoading());

    final result = await _stagesRepo.getStages();

    result.fold(
      (failure) => emit(StagesError(failure.errorMessage)),
      (stages) {
        stages.sort((a, b) => a.order.compareTo(b.order));
        emit(StagesLoaded(stages));
      },
    );
  }

  Future<void> deleteStage(String id) async {
    final result = await _stagesRepo.deleteStage(id);

    await result.fold(
      (failure) async => emit(StageDeleteError(failure.errorMessage)),
      (_) async {
        emit(const StageDeleted());
        await getStages();
      },
    );
  }
}
