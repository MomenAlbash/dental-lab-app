import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/ui/widgets/department_members_sheet.dart';
import 'package:flutter/material.dart';

/// One department: who it sits under, what it is carrying, and — the part that
/// matters — which restoration stages it owns.
///
/// The stages are named on the card rather than counted, because "٣ مراحل"
/// does not answer the question the screen exists for: whether the right work
/// reaches the right people.
class DepartmentCard extends StatelessWidget {
  const DepartmentCard({
    super.key,
    required this.department,
    required this.onEdit,
    required this.onLinkStages,
    required this.onDelete,
    this.isBusy = false,
  });

  final DepartmentModel department;
  final VoidCallback onEdit;
  final VoidCallback onLinkStages;
  final VoidCallback onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final railColor = department.isActive ? accent : glass.onGlassMuted;

    final radius = BorderRadius.circular(AppRadius.glass);

    return Container(
      // The collection deliberately adds no gap of its own — every card in the
      // app carries its own bottom margin, and the grid sets `mainAxisSpacing`
      // to zero on that understanding. Without this the rows touch.
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      // Shadow outside the clip, fill inside it: the same three-layer shape
      // every other card in the app uses. Painting the shadow on the clipped
      // box would swallow it and the cards would read as flat panels.
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          // Without this the stretched row is asked to be infinitely tall
          // inside a scrolling list, and the coloured rail — which has a width
          // but no height of its own — is what blows up.
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                department.displayName.isEmpty
                                    ? 'بلا اسم'
                                    : department.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                            ),
                            if (!department.isActive)
                              Text(
                                'معطّل',
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
                              ),
                          ],
                        ),
                        if (department.parentName?.trim().isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 2),
                          Text(
                            'ضمن ${department.parentName}',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            _Stat(
                              icon: Icons.groups_2_outlined,
                              text: '${department.employees.length} موظف',
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _Stat(
                              icon: Icons.inventory_2_outlined,
                              text:
                                  '${department.activeWorkloadCount} قيد العمل',
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),
                        if (department.isUnwired)
                          Text(
                            'لا مراحل مرتبطة — لن يصل هذا القسم أي عمل',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.warning,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final stage in department.stages)
                                _StageChip(stage: stage),
                            ],
                          ),

                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: isBusy ? null : onLinkStages,
                              icon: const Icon(Icons.link, size: 18),
                              label: const Text('ربط المراحل'),
                            ),
                            // Who a stage pointed at this department would
                            // actually reach — the other half of "ربط
                            // المراحل", and the one that explains an empty
                            // queue.
                            TextButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () => showDepartmentMembersSheet(
                                      context,
                                      departmentId: department.id,
                                      departmentName: department.displayName,
                                    ),
                              icon: const Icon(Icons.group_outlined, size: 18),
                              label: const Text('الموظفون'),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'تعديل',
                              onPressed: isBusy ? null : onEdit,
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: isBusy ? null : onDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                color: glass.error,
                              ),
                            ),
                          ],
                        ),
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

class _StageChip extends StatelessWidget {
  const _StageChip({required this.stage});

  final DepartmentStageModel stage;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = stage.isCheckpoint
        ? glass.warning
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.40)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // The restoration type is part of the identity, not decoration:
            // "التشطيب" alone is ambiguous the moment a lab runs two routes.
            '${stage.displayName} · ${stage.restorationTypeLabel}',
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
          if (stage.activeCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '(${stage.activeCount})',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: glass.onGlassMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.font12RegularHint.copyWith(
            color: glass.onGlassMuted,
          ),
        ),
      ],
    );
  }
}
