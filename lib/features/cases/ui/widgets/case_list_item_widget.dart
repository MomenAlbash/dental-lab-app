import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
import 'package:flutter/material.dart';

class CaseListItemWidget extends StatelessWidget {
  const CaseListItemWidget({
    super.key,
    required this.caseNumber,
    required this.patientName,
    required this.doctorName,
    required this.stageName,
    required this.priority,
    required this.onTap,
    required this.onDelete,
  });

  final String caseNumber;
  final String patientName;
  final String doctorName;
  final String stageName;
  final CasePriority priority;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color get _priorityColor => switch (priority) {
    CasePriority.low => AppColorsManger.textHint,
    CasePriority.normal => AppColorsManger.info,
    CasePriority.high => AppColorsManger.warning,
    CasePriority.urgent => AppColorsManger.error,
  };

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
                    Icons.folder_outlined,
                    color: AppColorsManger.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              patientName.isEmpty ? '—' : patientName,
                              style: AppTextStyles.font16MediumText,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            label: priority.arabicLabel,
                            color: _priorityColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caseNumber.isEmpty ? 'بدون رقم' : 'رقم: $caseNumber',
                        style: AppTextStyles.font12RegularHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (stageName.isNotEmpty)
                            _Badge(
                              label: stageName,
                              color: AppColorsManger.success,
                            ),
                          if (doctorName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'د. $doctorName',
                                style: AppTextStyles.font12RegularHint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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
