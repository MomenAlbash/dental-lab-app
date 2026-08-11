import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:flutter/material.dart';

/// Patient attributes as a tile mosaic — mirrors the doctor detail screen's
/// treatment so the two features read as one design language.
class PatientInfoTiles extends StatelessWidget {
  const PatientInfoTiles({super.key, required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final tiles = <_InfoTileData>[
      _InfoTileData(
        icon: Icons.medical_services_outlined,
        label: 'الطبيب',
        value: patient.doctorName,
        color: Theme.of(context).colorScheme.primary,
      ),
      _InfoTileData(
        icon: Icons.local_hospital_outlined,
        label: 'العيادة',
        value: patient.clinicName,
        color: context.glass.info,
      ),
      _InfoTileData(
        icon: Icons.wc_outlined,
        label: 'الجنس',
        value: patient.gender?.arabicLabel,
        color: glass.primaryDark,
      ),
      _InfoTileData(
        icon: Icons.cake_outlined,
        label: 'تاريخ الميلاد',
        value: patient.dateOfBirth,
        color: context.glass.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final spacing = AppSpacing.md;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: tileWidth,
                child: _InfoTile(data: tile),
              ),
          ],
        );
      },
    );
  }
}

class _InfoTileData {
  const _InfoTileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color color;

  bool get hasValue => value != null && value!.trim().isNotEmpty;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.data});

  final _InfoTileData data;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              color: data.color.withValues(alpha: 0.14),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.label,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.hasValue ? data.value!.trim() : '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font14MediumText.copyWith(
              color: data.hasValue ? glass.onGlass : glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}
