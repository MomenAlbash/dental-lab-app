import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:flutter/material.dart';

/// One date override. A closure reads in the error tint and a changed-hours
/// day in the warning one, so the two are told apart before the text is.
class ScannerExceptionListItemWidget extends StatelessWidget {
  const ScannerExceptionListItemWidget({
    super.key,
    required this.exception,
    required this.onEdit,
    required this.onDelete,
  });

  final ScannerAvailabilityExceptionModel exception;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = exception.isClosed ? glass.error : glass.warning;
    final date = exception.date;

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
                Container(width: 4, color: accent),
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
                            color: accent.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            exception.isClosed
                                ? Icons.event_busy_outlined
                                : Icons.schedule_outlined,
                            color: accent,
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
                                exception.dateLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                // The weekday is what makes the date mean
                                // something at a glance.
                                date == null
                                    ? exception.summaryLabel
                                    : '${WeekDays.labelOf(WeekDays.fromDateTime(date))} — ${exception.summaryLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: accent,
                                ),
                              ),
                              if ((exception.reason ?? '').trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    exception.reason!.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: glass.onGlassMuted),
                                  ),
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
