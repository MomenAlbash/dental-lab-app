import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';

/// The stages a restoration of the chosen type will run, as far as the form
/// can know while the restoration is still being entered.
///
/// Rebuilt on `GET /routing/routes/{restorationTypeId}` after the server's
/// route-preview endpoint was deleted. There is no "preview under these
/// answers" call any more, so the route comes back whole and the filtering —
/// by intake, and by mandatory-versus-optional — happens here.
class RoutePreviewState {
  const RoutePreviewState({
    this.mandatory = const [],
    this.optional = const [],
    this.problems = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  /// The stages this intake runs unconditionally, in route order.
  final List<CaseWorkflowStageModel> mandatory;

  /// The stages this intake *may* add — the questions the wizard's optional
  /// step is about to ask. Listed separately rather than mixed in, because a
  /// route drawn as if the case had already opted in would promise work
  /// nobody has agreed to.
  final List<CaseWorkflowStageModel> optional;

  /// The server's own complaints about how the route is drawn. Worth showing
  /// while a case is being filed onto it: these are where a case silently
  /// stops.
  final List<String> problems;

  final bool isLoading;

  /// True once an answer arrived, so an empty route reads as "this type has
  /// no stages drawn" rather than "not fetched yet".
  final bool hasLoaded;

  final String? errorMessage;

  bool get isEmpty => hasLoaded && mandatory.isEmpty && optional.isEmpty;

  /// Route order, with stages sharing an `order` grouped into one step —
  /// that number *is* the flow, and two stages holding it run in parallel.
  List<List<CaseWorkflowStageModel>> get steps {
    final byOrder = <int, List<CaseWorkflowStageModel>>{};
    for (final stage in mandatory) {
      (byOrder[stage.order] ??= []).add(stage);
    }
    final orders = byOrder.keys.toList()..sort();
    return [for (final order in orders) byOrder[order]!];
  }

  RoutePreviewState copyWith({
    List<CaseWorkflowStageModel>? mandatory,
    List<CaseWorkflowStageModel>? optional,
    List<String>? problems,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoutePreviewState(
      mandatory: mandatory ?? this.mandatory,
      optional: optional ?? this.optional,
      problems: problems ?? this.problems,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
