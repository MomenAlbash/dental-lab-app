import 'package:dental_lab_app/features/case_stages/data/models/route_problem_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';

/// A restoration type's whole route: its stages and the server's live verdict
/// on whether it runs (`RouteDefinitionDto`).
///
/// **Stages only.** There was a `transitions` list beside them, mirroring an
/// edge table — `PUT /routing/routes/transitions` answered 404, and the DTO
/// itself dropped the field: the flow is the stages' own `order`, grouped by
/// number into rows that run side by side.
class RouteDefinitionModel {
  const RouteDefinitionModel({
    required this.restorationTypeId,
    this.restorationTypeName,
    this.restorationTypeNameAr,
    this.stages = const [],
    this.problems = const [],
    this.isValid = true,
  });

  final String restorationTypeId;
  final String? restorationTypeName;
  final String? restorationTypeNameAr;

  final List<CaseWorkflowStageModel> stages;

  /// Result of running the publish checks over this route right now — always
  /// present, computed on every load rather than only on a save button.
  final List<RouteProblemModel> problems;

  /// The server's own answer. Trusted over any local check.
  final bool isValid;

  String get displayName {
    final ar = restorationTypeNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return restorationTypeName?.trim() ?? '';
  }

  List<RouteProblemModel> problemsFor(String stageId) => [
    for (final problem in problems)
      if (problem.stageId == stageId) problem,
  ];

  /// The stages a case taken in via [intake] runs unconditionally, in route
  /// order.
  ///
  /// Filtered here rather than asked for: `/routing/preview`, which used to
  /// answer "what would this run", was deleted with the graph engine. The
  /// route now comes back whole — both intake heads, optional stages
  /// included — and narrowing it is the caller's job.
  List<CaseWorkflowStageModel> mandatoryFor(ImpressionMethod? intake) =>
      _inRouteOrder(intake, optional: false);

  /// The stages [intake] *may* add — the ones the case form still has to ask
  /// about. Kept apart from [mandatoryFor] so a route is never drawn as if
  /// the case had already opted into them.
  List<CaseWorkflowStageModel> optionalFor(ImpressionMethod? intake) =>
      _inRouteOrder(intake, optional: true);

  List<CaseWorkflowStageModel> _inRouteOrder(
    ImpressionMethod? intake, {
    required bool optional,
  }) {
    final matching = [
      for (final stage in stages)
        if (stage.isActive &&
            stage.isOptional == optional &&
            stage.appliesToIntake(intake))
          stage,
    ];
    matching.sort((a, b) => a.order.compareTo(b.order));
    return matching;
  }

  factory RouteDefinitionModel.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(parse)
            .toList() ??
        <T>[];

    return RouteDefinitionModel(
      restorationTypeId: json['restorationTypeId'] as String? ?? '',
      restorationTypeName: json['restorationTypeName'] as String?,
      restorationTypeNameAr: json['restorationTypeNameAr'] as String?,
      stages: list('stages', CaseWorkflowStageModel.fromJson),
      problems: list('problems', RouteProblemModel.fromJson),
      isValid: json['isValid'] as bool? ?? true,
    );
  }
}
