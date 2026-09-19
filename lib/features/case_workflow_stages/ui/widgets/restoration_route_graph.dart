import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/graph_fork.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter/material.dart';

/// A restoration route drawn as a graph: one row per `order`, with painted
/// lines from each row into the next.
///
/// Two stages sharing an `order` sit side by side because they *run* side by
/// side. The numbered list this replaced implied a queue, which is the one
/// thing the route is not.
class RestorationRouteGraph extends StatelessWidget {
  const RestorationRouteGraph({
    super.key,
    required this.bands,
    this.onStageTap,
  });

  final List<List<CaseWorkflowStageModel>> bands;
  final ValueChanged<CaseWorkflowStageModel>? onStageTap;

  /// Opens "what follows this stage". Null when the user may not rewire the
  /// route, in which case no node offers the affordance at all.
  /// Fixed so the columns line up with the lines drawn between them.
  static const double nodeWidth = 132;

  static const double _gap = 32;

  /// Beyond this a row pans sideways rather than squeezing its names away.
  static const int _maxFitting = 2;

  @override
  Widget build(BuildContext context) {
    if (bands.isEmpty) return const SizedBox.shrink();

    final widest = bands.fold<int>(0, (a, b) => b.length > a ? b.length : a);

    final graph = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < bands.length; i++) ...[
          _Band(stages: bands[i], onStageTap: onStageTap),
          if (i < bands.length - 1)
            GraphFork(
              fromCount: bands[i].length,
              toCount: bands[i + 1].length,
              nodeWidth: nodeWidth,
              gutter: AppSpacing.xs,
              height: _gap,
              color: context.glass.strokeColor,
            ),
        ],
      ],
    );

    if (widest <= _maxFitting) return Center(child: graph);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: graph,
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.stages, required this.onStageTap});

  final List<CaseWorkflowStageModel> stages;
  final ValueChanged<CaseWorkflowStageModel>? onStageTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final stage in stages)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: _StageNode(
                stage: stage,
                onTap: onStageTap == null ? null : () => onStageTap!(stage),
              ),
            ),
        ],
      ),
    );
  }
}

/// One stage. Compact, but never at the cost of the two gates — which intake
/// it is cut for and which option it needs — since a stage silently pruned off
/// half the cases is exactly what this screen exists to make visible.
class _StageNode extends StatelessWidget {
  const _StageNode({required this.stage, required this.onTap});

  final CaseWorkflowStageModel stage;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.lg);
    final intake = intakeBadgeOf(stage.appliesTo);

    return Semantics(
      button: onTap != null,
      label: stage.displayName,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: RestorationRouteGraph.nodeWidth,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: glass.surfaceColor,
              border: Border.all(color: glass.strokeColor),
              borderRadius: radius,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (intake != null) ...[
                  _Pill(
                    icon: intake.icon,
                    text: intake.label,
                    color: intake.color(context),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  stage.displayName.isEmpty ? 'بلا اسم' : stage.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font13MediumPrimary.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (stage.isCheckpoint)
                      _Pill(text: 'تدقيق', color: glass.warning),
                    if (stage.isExternal)
                      _Pill(text: 'خارجي', color: glass.onGlassMuted),
                  ],
                ),
                // Who picks this stage up. Linked from the departments
                // screen, shown here because the route is where the gap is
                // noticed: a stage nobody owns is one nothing gets assigned
                // from.
                if (stage.departments.isNotEmpty || stage.users.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      ...stage.departments.map((d) => d.label),
                      ...stage.users.map((u) => u.label),
                    ].join('، '),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
                // The wiring lives on the node it belongs to. Tapping the node
                // opens the stage's own details, which is a different question
                // from "what comes after it" — one button each.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How an intake gate is shown on a node. `any` gets nothing — marking the
/// unconditional case would make every node shout and drown out the two that
/// actually fork.
class IntakeBadge {
  const IntakeBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color Function(BuildContext) color;
}

IntakeBadge? intakeBadgeOf(RouteStageAppliesTo appliesTo) =>
    switch (appliesTo) {
      RouteStageAppliesTo.any => null,
      RouteStageAppliesTo.traditionalOnly => IntakeBadge(
        label: 'طبعة',
        icon: Icons.back_hand_outlined,
        color: (context) => context.glass.warning,
      ),
      RouteStageAppliesTo.digitalOnly => IntakeBadge(
        label: 'سكانر',
        icon: Icons.document_scanner_outlined,
        color: (context) => Theme.of(context).colorScheme.primary,
      ),
    };

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
