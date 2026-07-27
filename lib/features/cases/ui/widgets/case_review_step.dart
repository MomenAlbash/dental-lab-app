import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:flutter/material.dart';

/// Step 4 — a read-only summary. The submit action lives in the wizard's
/// bottom bar.
class CaseReviewStep extends StatelessWidget {
  const CaseReviewStep({
    super.key,
    required this.patientName,
    required this.priority,
    required this.teethCount,
    required this.restorations,
  });

  final String patientName;
  final CasePriority priority;
  final int teethCount;
  final List<RestorationEntry> restorations;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _row('عدد الأسنان', '$teethCount'),
          _row('عدد التعويضات', '${restorations.length}'),
        ],
      ),
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
