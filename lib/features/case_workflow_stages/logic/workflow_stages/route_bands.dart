import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';

/// Groups a restoration route's stages into the rows a graph draws.
///
/// Purely by `order`: the API carries no edge table for a route any more
/// (`RouteDefinitionDto` dropped its `transitions` list the same way the case
/// workflow's did — see the entity's own remarks), so stages sharing an
/// `order` are the whole answer to "what runs together".
abstract final class RouteBands {
  /// Rows in flow order.
  ///
  /// Deactivated stages are dropped: they stay on the restorations already
  /// filed under them but are no longer part of the drawing. [intake] prunes
  /// the head the server would prune.
  static List<List<CaseWorkflowStageModel>> build(
    List<CaseWorkflowStageModel> stages, {
    ImpressionMethod? intake,
  }) {
    final visible = [
      for (final stage in stages)
        if (stage.isActive)
          if (intake == null || stage.appliesToIntake(intake)) stage,
    ];
    if (visible.isEmpty) return const [];

    final byOrder = <int, List<CaseWorkflowStageModel>>{};
    for (final stage in visible) {
      byOrder.putIfAbsent(stage.order, () => []).add(stage);
    }

    final orders = byOrder.keys.toList()..sort();
    return [
      for (final order in orders)
        byOrder[order]!..sort((a, b) => a.displayName.compareTo(b.displayName)),
    ];
  }
}
