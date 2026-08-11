import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/badge_variant.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:flutter/material.dart';

/// A case-priority row — matches the restoration-type card: an accent rail
/// (in the priority's own badge colour), an icon avatar, then name, quota
/// and badges.
class CasePriorityListItemWidget extends StatelessWidget {
  const CasePriorityListItemWidget({
    super.key,
    required this.priority,
    required this.onEdit,
    required this.onDelete,
  });

  final CasePriorityModel priority;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// What the doctor gets for free each month, in words.
  String get _quotaLabel {
    if (priority.isUnlimited) return 'بدون حد شهري';
    if (priority.freePerMonth <= 0) return 'بدون حالات مجانية';
    return '${priority.freePerMonth} حالات مجانية شهرياً';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    // A deactivated priority reads as muted regardless of its badge colour —
    // the colour says "how urgent", the rail also has to say "still in use".
    final railColor = priority.isActive
        ? badgeVariantColor(context, priority.badgeVariant)
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
                            Icons.flag_outlined,
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
                                priority.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _quotaLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _Badge(
                                    label: priority.isActive
                                        ? 'مفعّلة'
                                        : 'موقوفة',
                                    color: priority.isActive
                                        ? glass.success
                                        : glass.onGlassMuted,
                                  ),
                                  if (priority.isDefault)
                                    _Badge(
                                      label: 'الافتراضية',
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  if (priority.surcharge > 0)
                                    _Badge(
                                      label:
                                          'رسم ${priority.surcharge.toStringAsFixed(0)}',
                                      color: glass.warning,
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
                          // A priority already attached to cases cannot be
                          // removed — the button says so instead of letting
                          // the user find out from a server error.
                          tooltip: priority.isInUse
                              ? 'مستخدمة في حالات — لا يمكن حذفها'
                              : 'حذف',
                          onPressed: priority.isInUse ? null : onDelete,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.delete_outline,
                            color: priority.isInUse
                                ? glass.onGlassMuted
                                : glass.error,
                          ),
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
