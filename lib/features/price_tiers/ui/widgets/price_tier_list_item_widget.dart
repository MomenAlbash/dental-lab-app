import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// A price-tier row — matches the doctor/employee/role card: an accent
/// rail, an icon avatar, name/description/badges, plus a dedicated "edit
/// prices" action since that is this card's primary job.
class PriceTierListItemWidget extends StatelessWidget {
  const PriceTierListItemWidget({
    super.key,
    required this.name,
    required this.description,
    required this.isActive,
    required this.pricedRestorationCount,
    required this.totalRestorationTypeCount,
    required this.onEdit,
    required this.onEditPrices,
    required this.onDelete,
    required this.onTap,
  });

  final String name;
  final String? description;
  final bool isActive;
  final int pricedRestorationCount;
  final int totalRestorationTypeCount;
  final VoidCallback onEdit;
  final VoidCallback onEditPrices;
  final VoidCallback onDelete;
  final VoidCallback onTap;

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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: railColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
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
                                    Icons.sell_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.font16MediumText
                                            .copyWith(color: glass.onGlass),
                                      ),
                                      if (description != null &&
                                          description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.font12RegularHint
                                              .copyWith(
                                                color: glass.onGlassMuted,
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _Badge(
                                            label: isActive
                                                ? 'مفعّلة'
                                                : 'موقوفة',
                                            color: isActive
                                                ? glass.success
                                                : glass.onGlassMuted,
                                          ),
                                          _Badge(
                                            label:
                                                '$pricedRestorationCount/$totalRestorationTypeCount مسعّرة',
                                            color: glass.info,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: glass.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: onEditPrices,
                              icon: const Icon(
                                Icons.price_change_outlined,
                                size: 18,
                              ),
                              label: const Text('تعديل الأسعار'),
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
