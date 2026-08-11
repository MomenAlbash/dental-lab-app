import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// A user row — matches the doctor/employee/role card: an accent rail, an
/// icon avatar, then username/role and status badges.
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
                        child: Row(
                          children: [
                            _Avatar(isDoctorType: isDoctorType),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    username,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font16MediumText
                                        .copyWith(color: glass.onGlass),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    roleName.isEmpty ? 'بدون دور' : roleName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: glass.onGlassMuted),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _Badge(
                                        label: isDoctorType ? 'طبيب' : 'موظف',
                                        color: glass.info,
                                      ),
                                      _Badge(
                                        label: isActive ? 'مفعّل' : 'موقوف',
                                        color: isActive
                                            ? glass.success
                                            : glass.onGlassMuted,
                                      ),
                                      if (isAdmin)
                                        _Badge(
                                          label: 'مدير',
                                          color: glass.warning,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isDoctorType});

  final bool isDoctorType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: context.glass.brandGradient,
      ),
      child: Icon(
        isDoctorType ? Icons.medical_services_outlined : Icons.badge_outlined,
        color: Colors.white,
        size: 20,
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
