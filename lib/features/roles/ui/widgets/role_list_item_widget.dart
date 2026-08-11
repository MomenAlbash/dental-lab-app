import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// A role row — matches the doctor/employee card: an accent rail, an icon
/// avatar, then name/description/permission-count.
class RoleListItemWidget extends StatelessWidget {
  const RoleListItemWidget({
    super.key,
    required this.name,
    required this.description,
    required this.permissionsCount,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final String description;
  final int permissionsCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: glass.brandGradient,
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                description.isEmpty ? 'بدون وصف' : description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _CountChip(
                                count: permissionsCount,
                                accent: accent,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'تعديل',
                              onPressed: onEdit,
                              icon: Icon(
                                Icons.edit_outlined,
                                color: glass.onGlassMuted,
                              ),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: onDelete,
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

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count, required this.accent});

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            '$count صلاحية',
            style: AppTextStyles.font13MediumPrimary.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}
