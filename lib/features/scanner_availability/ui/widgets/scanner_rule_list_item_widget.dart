import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:flutter/material.dart';

/// One weekly scanner window — the day and hours read first, the mechanics
/// (slot length, gap, capacity) as badges underneath.
class ScannerRuleListItemWidget extends StatelessWidget {
  const ScannerRuleListItemWidget({
    super.key,
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });

  final ScannerAvailabilityRuleModel rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final railColor = rule.isActive
        ? Theme.of(context).colorScheme.primary
        : glass.onGlassMuted;
    final slots = rule.slotsPerDay;

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
                            Icons.event_repeat_outlined,
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
                                rule.dayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                rule.timeRangeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font13MediumPrimary,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _Badge(
                                    label: '${rule.slotMinutes} د/موعد',
                                    color: glass.info,
                                  ),
                                  if (rule.gapMinutes > 0)
                                    _Badge(
                                      label: 'فاصل ${rule.gapMinutes} د',
                                      color: glass.onGlassMuted,
                                    ),
                                  if (rule.capacity > 1)
                                    _Badge(
                                      label: '${rule.capacity} بالتوازي',
                                      color: glass.warning,
                                    ),
                                  // The number the lab is actually deciding
                                  // on; hidden when the window is unusable.
                                  if (slots != null)
                                    _Badge(
                                      label: '$slots موعد',
                                      color: glass.success,
                                    ),
                                  if (!rule.isActive)
                                    _Badge(
                                      label: 'موقوف',
                                      color: glass.onGlassMuted,
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
