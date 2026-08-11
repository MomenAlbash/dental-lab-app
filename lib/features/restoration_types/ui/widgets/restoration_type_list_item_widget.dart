import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// A restoration-type row — matches the doctor/employee/role card: an
/// accent rail, an icon avatar, then name/price/badges.
class RestorationTypeListItemWidget extends StatelessWidget {
  const RestorationTypeListItemWidget({
    super.key,
    required this.name,
    required this.defaultPrice,
    required this.isActive,
    required this.stagesCount,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final double defaultPrice;
  final bool isActive;
  final int stagesCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final railColor = isActive
        ? Theme.of(context).colorScheme.primary
        : glass.onGlassMuted;

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
                Container(width: 4, color: railColor),
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
                            Icons.category_outlined,
                            color: Colors.white,
                            size: 20,
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
                                '${defaultPrice.toStringAsFixed(0)} ل.س',
                                style: AppTextStyles.font13MediumPrimary,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _Badge(
                                    label: isActive ? 'مفعّل' : 'موقوف',
                                    color: isActive
                                        ? glass.success
                                        : glass.onGlassMuted,
                                  ),
                                  if (stagesCount > 0)
                                    _Badge(
                                      label: '$stagesCount مراحل',
                                      color: glass.info,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          tooltip: 'تعديل',
                          onPressed: onEdit,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.edit_outlined,
                            color: glass.onGlassMuted,
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.delete_outline, color: glass.error),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}
