import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/stage_assignees_sheet.dart';
import 'package:flutter/material.dart';

/// Summarises a stage's assignment and opens the picker.
///
/// Counts rather than names: a stage can carry a whole department plus a
/// handful of people, and a wall of chips inside a form is unreadable. The
/// sheet is where the detail lives.
class StageAssigneesField extends StatelessWidget {
  const StageAssigneesField({
    super.key,
    required this.assignees,
    required this.onEdit,
  });

  final StageAssignees assignees;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final parts = [
      if (assignees.departmentIds.isNotEmpty)
        '${assignees.departmentIds.length} قسم',
      if (assignees.userIds.isNotEmpty) '${assignees.userIds.length} شخص',
      if (assignees.excludedUserIds.isNotEmpty)
        '${assignees.excludedUserIds.length} مستثنى',
    ];
    // Said plainly: an empty assignment is legal — a lab may draw its flow
    // before filling in an org chart — but it must not look like a filled one.
    final isEmpty = parts.isEmpty;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(AppRadius.glass),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: glass.surfaceGradient,
          borderRadius: BorderRadius.circular(AppRadius.glass),
          border: Border.all(color: glass.strokeColor),
        ),
        child: Row(
          children: [
            Icon(Icons.groups_outlined, color: glass.onGlassMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEmpty ? 'لم يُسنَد لأحد بعد' : parts.join(' • '),
                overflow: TextOverflow.ellipsis,
                style: isEmpty
                    ? AppTextStyles.font14RegularSecondary.copyWith(
                        color: glass.onGlassMuted,
                      )
                    : AppTextStyles.font14MediumText.copyWith(
                        color: glass.onGlass,
                      ),
              ),
            ),
            Icon(Icons.chevron_left, color: glass.onGlassMuted),
          ],
        ),
      ),
    );
  }
}
