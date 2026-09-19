import 'package:dental_lab_app/features/case_workflow_stages/data/repos/workflow_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/route_editor/route_editor_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads one restoration type's route, for the server's own verdict on it.
///
/// There used to be a second job here — drafting and committing the route's
/// edge set — but the API carries no such thing: `RouteDefinitionDto` dropped
/// its `transitions` list, and `PUT /routing/routes/transitions` answered
/// 404. The flow is the stages' own `order` (see `RouteBands`), which the
/// route-editor page reads straight from `WorkflowStagesCubit`; what is left
/// to fetch here is only [RouteDefinitionModel.problems].
class RouteEditorCubit extends Cubit<RouteEditorState> {
  RouteEditorCubit(this._repo) : super(const RouteEditorInitial());

  final WorkflowStagesRepo _repo;

  Future<void> load(String restorationTypeId) async {
    emit(const RouteEditorLoading());

    final result = await _repo.getRouteDefinition(restorationTypeId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(RouteEditorError(failure.errorMessage)),
      (route) => emit(RouteEditorLoaded(route: route)),
    );
  }
}
