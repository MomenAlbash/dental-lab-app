import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

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
  });

  final String name;
  final String? description;
  final bool isActive;
  final int pricedRestorationCount;
  final int totalRestorationTypeCount;
  final VoidCallback onEdit;
  final VoidCallback onEditPrices;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsManger.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorsManger.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColorsManger.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sell_outlined,
                  color: AppColorsManger.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.font16MediumText),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font12RegularHint,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Badge(
                          label: isActive ? 'مفعّلة' : 'موقوفة',
                          color: isActive
                              ? AppColorsManger.success
                              : AppColorsManger.textHint,
                        ),
                        const SizedBox(width: 6),
                        _Badge(
                          label: '$pricedRestorationCount/$totalRestorationTypeCount مسعّرة',
                          color: AppColorsManger.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColorsManger.textSecondary,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColorsManger.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onEditPrices,
            icon: const Icon(Icons.price_change_outlined, size: 18),
            label: const Text('تعديل الأسعار'),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}
