import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class UserListItemWidget extends StatelessWidget {
  const UserListItemWidget({
    super.key,
    required this.username,
    required this.roleName,
    required this.isDoctorType,
    required this.isActive,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
  });

  final String username;
  final String roleName;
  final bool isDoctorType;
  final bool isActive;
  final bool isAdmin;
  final VoidCallback onTap;
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
                  child: Icon(
                    isDoctorType ? Icons.medical_services_outlined : Icons.badge_outlined,
                    color: AppColorsManger.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: AppTextStyles.font16MediumText),
                      const SizedBox(height: 4),
                      Text(
                        roleName.isEmpty ? 'بدون دور' : roleName,
                        style: AppTextStyles.font12RegularHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(
                            label: isDoctorType ? 'طبيب' : 'موظف',
                            color: AppColorsManger.info,
                          ),
                          const SizedBox(width: 6),
                          _Badge(
                            label: isActive ? 'مفعّل' : 'موقوف',
                            color: isActive ? AppColorsManger.success : AppColorsManger.textHint,
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            const _Badge(label: 'مدير', color: AppColorsManger.warning),
                          ],
                        ],
                      ),
                    ],
                  ),
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
