import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:flutter/material.dart';

/// Step — a read-only summary. The submit action lives in the wizard's
/// bottom bar.
class CaseReviewStep extends StatelessWidget {
  const CaseReviewStep({
    super.key,
    required this.patientName,
    required this.priority,
    required this.restorations,
  });

  final String patientName;
  final CasePriority priority;
  final List<RestorationEntry> restorations;

  int get _teethCount =>
      restorations.fold(0, (sum, r) => sum + r.teeth.length);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColorsManger.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColorsManger.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('المريض', patientName.isEmpty ? '—' : patientName),
              _row('الأولوية', priority.arabicLabel),
              _row('عدد التعويضات', '${restorations.length}'),
              _row('عدد الأسنان', '$_teethCount'),
            ],
          ),
        ),
        if (restorations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('التعويضات', style: AppTextStyles.font14MediumText),
          const SizedBox(height: 8),
          ...restorations.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorsManger.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorsManger.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    color: AppColorsManger.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.restorationName,
                          style: AppTextStyles.font14MediumText,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.teeth.isEmpty
                              ? 'بدون أسنان محددة'
                              : 'الأسنان: ${r.teeth.map((t) => t.toothNumber).join(', ')}',
                          style: AppTextStyles.font12RegularHint,
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.font14RegularSecondary),
          const Spacer(),
          Text(value, style: AppTextStyles.font14MediumText),
        ],
      ),
    );
  }
}
