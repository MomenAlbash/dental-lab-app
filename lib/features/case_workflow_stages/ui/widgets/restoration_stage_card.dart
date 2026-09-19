import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter/material.dart';

/// One stage of a restoration type's route.
///
/// Same shape as the case-workflow card — accent rail, title row, flag chips —
/// so the two editors read as one feature. What differs is what it has to
/// say: the intake gate that decides whether the stage is cut onto a case at
/// all. Expected duration is not shown here any more — it lives on the
/// restoration type itself now, not on one of its stages.
class RestorationStageCard extends StatelessWidget {
  const RestorationStageCard({
    super.key,
    required this.stage,
    required this.onEdit,
    required this.onDeactivate,
    required this.onChangeImage,
    required this.onDelete,
  });

  final CaseWorkflowStageModel stage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onDelete;

  /// The bench backdrop — a work reference, not the type's catalogue shot.
  final VoidCallback onChangeImage;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;

    // The brand accent, exactly like the case-workflow card and every other
    // list row in the app. It carried the checkpoint flag for a while, which
    // made colour mean something different on this one screen — "checkpoint"
    // is a fact about the stage and belongs in the chips below with the rest
    // of them, not in the rail.
    final railColor = stage.isActive ? accent : glass.onGlassMuted;

    return Container(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
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
                          onEdit: onEdit,
                          onDeactivate: onDeactivate,
                          onChangeImage: onChangeImage,
                          onDelete: onDelete,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _Flags(stage: stage),
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
    required this.onEdit,
    required this.onDeactivate,
    required this.onChangeImage,
    required this.onDelete,
  });

  final CaseWorkflowStageModel stage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onDelete;

  /// The bench backdrop — a work reference, not the type's catalogue shot.
  final VoidCallback onChangeImage;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Row(
      children: [
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
          tooltip: 'صورة المرحلة',
          onPressed: onChangeImage,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.image_outlined,
            size: 18,
            color: glass.onGlassMuted,
          ),
        ),
        IconButton(
          tooltip: 'تعديل',
          onPressed: onEdit,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.edit_outlined, size: 18, color: glass.onGlassMuted),
        ),
        // Deactivating is the safe alternative to deleting, so it is offered
        // beside it rather than hidden inside the edit form.
        if (stage.isActive)
          IconButton(
            tooltip: 'تعطيل',
            onPressed: onDeactivate,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.visibility_off_outlined,
              size: 18,
              color: glass.onGlassMuted,
            ),
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

  final CaseWorkflowStageModel stage;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 6,
      children: [
        // The intake gate, shown only when it actually narrows the stage —
        // "every case" on every card would be noise.
        if (stage.appliesTo != RouteStageAppliesTo.any)
          _Flag(
            label: stage.appliesTo.label,
            color: glass.info,
            icon: stage.appliesTo == RouteStageAppliesTo.digitalOnly
                ? Icons.document_scanner_outlined
                : Icons.back_hand_outlined,
          ),
        if (stage.isCheckpoint) _Flag(label: 'نقطة فحص', color: glass.warning),
        if (stage.isExternal) _Flag(label: 'خارج المخبر', color: glass.warning),
        // Why a stage may refuse to delete. Stated up front rather than as an
        // error after the attempt.
        if (stage.restorationCount > 0)
          _Flag(
            label: '${stage.restorationCount} تعويض',
            color: glass.onGlassMuted,
          ),
        // Distinct from `restorationCount`: this counts restorations walking
        // this exact *version* wherever they stand in it, which is what an
        // edit here would fork away from rather than update in place.
        if (stage.restorationsOnThisVersion > 0)
          _Flag(
            label:
                'التعديل سينشئ نسخة جديدة (${stage.restorationsOnThisVersion})',
            color: glass.warning,
          ),
        if (!stage.isActive) _Flag(label: 'معطّلة', color: glass.error),
      ],
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: AppTextStyles.font12RegularHint.copyWith(color: color),
        ),
      ],
    ),
  );
}
