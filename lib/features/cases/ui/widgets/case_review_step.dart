import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
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
  });

  final String patientName;
  final String priorityName;
  final List<RestorationEntry> restorations;

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
      ],
    );
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
