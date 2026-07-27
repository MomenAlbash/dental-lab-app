import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class LaboratoryListItemWidget extends StatelessWidget {
  const LaboratoryListItemWidget({
    super.key,
    required this.name,
    required this.address,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isCurrent = false,
  });

  final String name;
  final String address;
  final bool isActive;

  /// Whether this is the laboratory the session is currently scoped to.
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColorsManger.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorsManger.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColorsManger.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.science_outlined, color: AppColorsManger.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.font16MediumText),
                      const SizedBox(height: 4),
                      Text(
                        address.isEmpty ? 'بدون عنوان' : address,
                        style: AppTextStyles.font12RegularHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(
                            label: isActive ? 'مفعّل' : 'موقوف',
                            color: isActive
                                ? AppColorsManger.success
                                : AppColorsManger.textHint,
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            const _Badge(
                              label: 'المخبر الحالي',
                              color: AppColorsManger.primary,
                            ),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}
