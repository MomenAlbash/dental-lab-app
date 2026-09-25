import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:flutter/material.dart';

/// A visit's status as a small coloured label.
class PhotographyStatusChip extends StatelessWidget {
  const PhotographyStatusChip({super.key, required this.status});

  final PhotographyVisitStatus status;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = switch (status) {
      PhotographyVisitStatus.requested => glass.warning,
      PhotographyVisitStatus.scheduled => glass.info,
      PhotographyVisitStatus.completed => glass.success,
      PhotographyVisitStatus.cancelled => glass.onGlassMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}
