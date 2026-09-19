import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/badge_variant.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_validation.dart';
import 'package:flutter/material.dart';

/// One stage in the workflow editor: its flags, its outgoing edges, and any
/// defect it is implicated in.
///
/// The edges are a checklist of the other stages rather than lines on a canvas
/// — on a phone, "which stages may follow this one" is a question a list
/// answers better than a drawing you have to pan.
class WorkflowStageCard extends StatelessWidget {
  const WorkflowStageCard({
    super.key,
    required this.stage,
    required this.issues,
    required this.onEdit,
    required this.onDelete,
    required this.onEditAssignees,
  });

  final CaseStageModel stage;
  final List<WorkflowIssue> issues;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Staffing alone, without opening the rules. Its own action because a
  /// roster changes far more often than the workflow does, and usually at the
  /// hand of somebody who has no business editing the rest of the stage.
  final VoidCallback onEditAssignees;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final hasError = issues.any((i) => i.isError);
    final accent = badgeVariantColor(context, stage.badgeVariant);

    // The brand accent, the same as every other list row in the app — red only
    // when this stage is implicated in a defect, muted when it is retired.
    //
    // The lab's own `badgeVariant` deliberately does *not* colour the rail: it
    // would make this the one screen where the rail means "the colour the lab
    // picked" instead of "a row of this kind", and the two editors would read
    // as different products. The chosen colour is still shown, as a swatch
    // beside the name.
    final railColor = hasError
        ? glass.error
        : (stage.isActive
              ? Theme.of(context).colorScheme.primary
              : glass.onGlassMuted);

    return Container(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(
              // A broken stage is outlined, not just listed at the bottom —
              // the defect belongs next to the thing that has it.
              color: hasError ? glass.error : glass.strokeColor,
              width: hasError ? 1.5 : 1,
            ),
            borderRadius: radius,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: railColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          stage: stage,
                          badgeColor: accent,
                          onEdit: onEdit,
                          onDelete: onDelete,
                          onEditAssignees: onEditAssignees,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _Flags(stage: stage),
                        for (final issue in issues) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _IssueRow(issue: issue),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.stage,
    required this.badgeColor,
    required this.onEdit,
    required this.onDelete,
    required this.onEditAssignees,
  });

  final CaseStageModel stage;

  /// The colour the lab picked for this stage's badge. Shown as a swatch here
  /// rather than on the rail, so the rail keeps the same meaning it has on
  /// every other row in the app.
  final Color badgeColor;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onEditAssignees;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final staffedCount = stage.departmentIds.length + stage.userIds.length;

    return Row(
      children: [
        // Only when the lab actually chose one — a swatch on every stage would
        // just be the fallback colour repeated down the list.
        if (stage.badgeVariant?.isNotEmpty ?? false) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            stage.displayName.isEmpty ? 'مرحلة بلا اسم' : stage.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font16MediumText.copyWith(
              color: stage.isActive ? glass.onGlass : glass.onGlassMuted,
            ),
          ),
        ),
        IconButton(
          // Badged with how many are on it, so an unstaffed stage — the one
          // that silently strands a case — is visible without opening it.
          tooltip: staffedCount == 0
              ? 'المسؤولون — لا أحد'
              : 'المسؤولون ($staffedCount)',
          onPressed: onEditAssignees,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            staffedCount == 0
                ? Icons.person_off_outlined
                : Icons.people_outline,
            size: 18,
            color: staffedCount == 0 ? glass.warning : glass.onGlassMuted,
          ),
        ),
        IconButton(
          tooltip: 'تعديل',
          onPressed: onEdit,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.edit_outlined, size: 18, color: glass.onGlassMuted),
        ),
        IconButton(
          tooltip: 'حذف',
          onPressed: onDelete,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.delete_outline, size: 18, color: glass.error),
        ),
      ],
    );
  }
}

class _Flags extends StatelessWidget {
  const _Flags({required this.stage});

  final CaseStageModel stage;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 6,
      children: [
        // `timing`, not the retired `placement`: the API stopped sending
        // `placement`, so it parsed as "before production" on every stage and
        // the badge contradicted the heading the stage was filed under.
        _Flag(label: stage.timing.arabicLabel, color: glass.info),
        // The intake gate decides whether the stage is cut onto the case at
        // all, so it belongs beside the placement rather than buried in the
        // form. `any` is the default and says nothing worth a chip.
        if (stage.appliesTo != RouteStageAppliesTo.any)
          _Flag(label: stage.appliesTo.label, color: accent),
        // `isStart`/`isFinal`/`joinMode` are not real fields any more (same
        // fate as `placement` above — no such columns on the live
        // `CaseStatusDto`, so they always parsed as false/waitAny and these
        // badges never actually showed anything true).
        if (stage.isExternal) _Flag(label: 'خارج المخبر', color: glass.warning),
        if (stage.requiresReason) _Flag(label: 'تتطلب سبباً', color: accent),
        if (!stage.isActive) _Flag(label: 'معطّلة', color: glass.error),
        // Why a stage may refuse to delete. Stated up front rather than as an
        // error after the attempt.
        if (stage.caseCount > 0)
          _Flag(label: '${stage.caseCount} حالة', color: glass.onGlassMuted),
        // Distinct from `caseCount`: this counts cases walking this exact
        // *version* wherever they stand in it, which is what an edit here
        // would fork away from rather than update in place.
        if (stage.casesOnThisVersion > 0)
          _Flag(
            label:
                'التعديل سينشئ نسخة جديدة (${stage.casesOnThisVersion} حالة)',
            color: glass.warning,
          ),
      ],
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      label,
      style: AppTextStyles.font12RegularHint.copyWith(color: color),
    ),
  );
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final WorkflowIssue issue;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = issue.isError ? glass.error : glass.warning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          issue.isError ? Icons.error_outline : Icons.warning_amber_outlined,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            issue.message,
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
