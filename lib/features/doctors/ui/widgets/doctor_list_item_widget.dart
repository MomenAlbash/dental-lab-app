import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class DoctorListItemWidget extends StatelessWidget {
  const DoctorListItemWidget({
    super.key,
    required this.fullName,
    required this.phoneNumber,
    required this.clinicName,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  final String fullName;
  final String phoneNumber;
  final String clinicName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

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
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColorsManger.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? '—' : fullName,
                        style: AppTextStyles.font16MediumText,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clinicName.isEmpty ? 'بدون عيادة' : clinicName,
                        style: AppTextStyles.font12RegularHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          phoneNumber,
                          style: AppTextStyles.font13MediumPrimary,
                        ),
                      ],
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
