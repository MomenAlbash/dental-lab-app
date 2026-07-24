import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class CaseWorkflowStageListItemWidget extends StatelessWidget {
  const CaseWorkflowStageListItemWidget({
    super.key,
    required this.name,
    required this.order,
    required this.isActive,
    required this.isFinal,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final int order;
  final bool isActive;
  final bool isFinal;
  final VoidCallback onEdit;
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColorsManger.primarySurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$order',
              style: AppTextStyles.font16MediumText.copyWith(color: AppColorsManger.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.font16MediumText),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Badge(
                      label: isActive ? 'مفعّلة' : 'موقوفة',
                      color: isActive ? AppColorsManger.success : AppColorsManger.textHint,
                    ),
                    if (isFinal) ...[
                      const SizedBox(width: 6),
                      const _Badge(label: 'مرحلة نهائية', color: AppColorsManger.info),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColorsManger.textSecondary),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColorsManger.error),
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
