import 'package:dental_lab_app/features/case_workflow_stages/data/models/route_definition_model.dart';

sealed class RouteEditorState {
  const RouteEditorState();
}

class RouteEditorInitial extends RouteEditorState {
  const RouteEditorInitial();
}

class RouteEditorLoading extends RouteEditorState {
  const RouteEditorLoading();
}

/// The route as the server sees it — its stages and its own live verdict on
/// whether it runs.
///
/// There is no draft here any more: a route has no edge set to wire (`PUT
/// /routing/routes/transitions` answered 404, and the DTO itself carries no
/// `transitions` field), so this is a plain read, refreshed after every stage
/// edit rather than committed on its own.
class RouteEditorLoaded extends RouteEditorState {
  const RouteEditorLoaded({required this.route});

  final RouteDefinitionModel route;
}

class RouteEditorError extends RouteEditorState {
  const RouteEditorError(this.message);

  final String message;
}
