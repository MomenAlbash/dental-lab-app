import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// A case row — matches the doctor/employee/role card: an accent rail
/// coloured by priority, an icon avatar, then patient/case-number/badges.
class CaseListItemWidget extends StatelessWidget {
  const CaseListItemWidget({
    super.key,
    required this.caseNumber,
    required this.patientName,
    required this.doctorName,
    required this.stageName,
    required this.priorityLabel,
    required this.priorityColor,
    required this.onTap,
    required this.onDelete,
  });

  final String caseNumber;
  final String patientName;
  final String doctorName;
  final String stageName;

  /// The case's priority as text — empty when it has none, in which case no
  /// badge is drawn. Priorities are lab-defined, so the label comes from the
  /// case itself rather than from an enum.
  final String priorityLabel;

  /// Resolved by the caller from the priority's `badgeVariant`, since the
  /// case rows themselves only carry the priority's id and name.
  final Color priorityColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final railColor = priorityColor;

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
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: glass.brandGradient,
                              ),
                              child: const Icon(
                                Icons.folder_outlined,
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
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          patientName.isEmpty
                                              ? '—'
                                              : patientName,
                                          style: AppTextStyles.font16MediumText
                                              .copyWith(color: glass.onGlass),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (priorityLabel.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        _Badge(
                                          label: priorityLabel,
                                          color: railColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    caseNumber.isEmpty
                                        ? 'بدون رقم'
                                        : 'رقم: $caseNumber',
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: glass.onGlassMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      if (stageName.isNotEmpty)
                                        _Badge(
                                          label: stageName,
                                          color: glass.success,
                                        ),
                                      if (doctorName.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'د. $doctorName',
                                            style: AppTextStyles
                                                .font12RegularHint
                                                .copyWith(
                                                  color: glass.onGlassMuted,
                                                ),
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
