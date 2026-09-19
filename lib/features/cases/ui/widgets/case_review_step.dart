import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/features/cases/logic/delivery_estimate.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:flutter/material.dart';

/// Step — a read-only summary. The submit action lives in the wizard's
/// bottom bar.
class CaseReviewStep extends StatelessWidget {
  const CaseReviewStep({
    super.key,
    required this.patientName,
    required this.priorityName,
    required this.restorations,
    this.estimate,
    this.expectedAt,
    this.onPickExpectedAt,
    this.attachments = const [],
    this.onPickAttachment,
    this.onRemoveAttachment,
  });

  final String patientName;
  final String priorityName;
  final List<RestorationEntry> restorations;

  /// What the lab's own turnaround figures work out to for this case.
  /// Null when nothing can be said — no priority chosen, or no restoration
  /// type carrying a row for it.
  final DeliveryEstimate? estimate;

  /// The date actually being promised: the estimate unless the user overrode
  /// it. Kept apart from [estimate] so the screen can show both — "the lab
  /// says X, we are promising Y" is the whole point of letting it be edited.
  final DateTime? expectedAt;

  final VoidCallback? onPickExpectedAt;

  /// Files picked for this case — not uploaded yet, since that needs a case
  /// id this form does not have until it saves.
  final List<String> attachments;
  final VoidCallback? onPickAttachment;
  final ValueChanged<int>? onRemoveAttachment;

  int get _teethCount => restorations.fold(0, (sum, r) => sum + r.teeth.length);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: context.glass.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            border: Border.all(color: context.glass.strokeColor),
            boxShadow: context.glass.shadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(context, 'المريض', patientName.isEmpty ? '—' : patientName),
              _row(
                context,
                'الأولوية',
                priorityName.isEmpty ? '—' : priorityName,
              ),
              _row(context, 'عدد التعويضات', '${restorations.length}'),
              _row(context, 'عدد الأسنان', '$_teethCount'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const GlassSectionTitle('موعد التسليم'),
        const SizedBox(height: AppSpacing.sm),
        _DeliveryCard(
          estimate: estimate,
          expectedAt: expectedAt,
          onPick: onPickExpectedAt,
        ),

        if (restorations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const GlassSectionTitle('التعويضات'),
          const SizedBox(height: AppSpacing.sm),
          ...restorations.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: context.glass.surfaceGradient,
                borderRadius: BorderRadius.circular(AppRadius.glass),
                border: Border.all(color: context.glass.strokeColor),
                boxShadow: context.glass.shadows,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: context.glass.brandGradient,
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.restorationName,
                          style: AppTextStyles.font14MediumText.copyWith(
                            color: context.glass.onGlass,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.teeth.isEmpty
                              ? 'بدون أسنان محددة'
                              : 'الأسنان: ${r.teeth.map((t) => t.toothNumber).join(', ')}',
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: context.glass.onGlassMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        GlassSectionTitle(
          'المرفقات',
          count: attachments.isEmpty ? null : attachments.length,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AttachmentCard(
          fileNames: attachments,
          onPick: onPickAttachment,
          onRemove: onRemoveAttachment,
        ),
      ],
    );
  }

  static String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.font14MediumText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the lab's own turnaround figures promise, and the date actually being
/// filed — editable, because the estimate is a floor, not a contract.
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.estimate,
    required this.expectedAt,
    required this.onPick,
  });

  final DeliveryEstimate? estimate;
  final DateTime? expectedAt;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final est = estimate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (est == null)
            Text(
              // Not an error: a case with no priority chosen yet, or a
              // restoration type the lab never gave a turnaround for, simply
              // has nothing to promise — said plainly rather than defaulted
              // to "today".
              'لا يمكن تقدير موعد التسليم بعد — اختر الأولوية والتعويضات أولاً',
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          else ...[
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: glass.onGlassMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'مدة التصنيع المقدّرة: ${est.durationLabel}',
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              ],
            ),
            if (!est.hasEstimateForEveryLine) ...[
              const SizedBox(height: 4),
              Text(
                // A missing row is "no estimate declared", not zero days —
                // the figure above is only the slowest of the types that
                // *did* have one, so it may understate the real wait.
                'بعض التعويضات ليس لها تقدير عند هذه الأولوية — المدة أعلاه قد تكون أقل من الفعلية',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.warning,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    'موعد التسليم المتوقع',
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    expectedAt == null
                        ? '—'
                        : CaseReviewStep.formatDate(expectedAt!),
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit_calendar_outlined,
                    size: 16,
                    color: glass.onGlassMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The files picked for this case, if any. Upload itself only happens once
/// the case is saved and has an id — see [CaseFormCubit.createCase]. More
/// than one is normal: an intake photo, a lab prescription scan, a doctor's
/// note.
class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    this.fileNames = const [],
    this.onPick,
    this.onRemove,
  });

  final List<String> fileNames;
  final VoidCallback? onPick;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < fileNames.length; i++) ...[
            Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 18,
                  color: glass.onGlassMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileNames[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة الملف',
                  onPressed: onRemove == null ? null : () => onRemove!(i),
                  icon: Icon(Icons.close, size: 18, color: glass.error),
                ),
              ],
            ),
            if (i < fileNames.length - 1)
              Divider(height: 1, color: glass.strokeColor),
          ],
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            child: Padding(
              padding: EdgeInsets.only(top: fileNames.isEmpty ? 0 : 12),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file_outlined,
                    size: 18,
                    color: glass.onGlassMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fileNames.isEmpty ? 'إرفاق ملف (اختياري)' : 'إرفاق ملف آخر',
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
