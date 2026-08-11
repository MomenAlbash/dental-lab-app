import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter/material.dart';

/// Doctor attributes as a tile mosaic.
///
/// The previous divided label/value list gave every field the same weight and
/// read like a printed record. Tiles let the eye jump straight to a field, and
/// the accent-tinted icon chips carry the brand into the body of the screen.
class DoctorInfoTiles extends StatelessWidget {
  const DoctorInfoTiles({super.key, required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final tiles = <_InfoTileData>[
      _InfoTileData(
        icon: Icons.local_hospital_outlined,
        label: 'العيادة',
        value: doctor.clinicName,
        color: Theme.of(context).colorScheme.primary,
      ),
      _InfoTileData(
        icon: Icons.location_city_outlined,
        label: 'المدينة',
        value: doctor.cityName,
        color: context.glass.info,
      ),
      _InfoTileData(
        icon: Icons.wc_outlined,
        label: 'الجنس',
        value: doctor.gender?.arabicLabel,
        color: glass.primaryDark,
      ),
      _InfoTileData(
        icon: Icons.cake_outlined,
        label: 'تاريخ الميلاد',
        value: doctor.dateOfBirth,
        color: context.glass.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across once there is room; two on a phone. Tiles are laid out
        // with a Wrap rather than a GridView so they can size to their content
        // and never clip at large text scales.
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final spacing = AppSpacing.md;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final tile in tiles)
                  SizedBox(
                    width: tileWidth,
                    child: _InfoTile(data: tile),
                  ),
              ],
            ),
            if ((doctor.address?.trim().isNotEmpty ?? false)) ...[
              SizedBox(height: spacing),
              // The address is free text and can be long, so it gets a full
              // width tile instead of a cell it would overflow.
              _InfoTile(
                data: _InfoTileData(
                  icon: Icons.map_outlined,
                  label: 'العنوان',
                  value: doctor.address,
                  color: context.glass.success,
                ),
                wide: true,
              ),
            ],
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
  const _InfoTile({required this.data, this.wide = false});

  final _InfoTileData data;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final icon = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        color: data.color.withValues(alpha: 0.14),
      ),
      child: Icon(data.icon, size: 18, color: data.color),
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.label,
          style: AppTextStyles.font12RegularHint.copyWith(
            color: glass.onGlassMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.hasValue ? data.value!.trim() : '—',
          maxLines: wide ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.font14MediumText.copyWith(
            color: data.hasValue ? glass.onGlass : glass.onGlassMuted,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: text),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: AppSpacing.sm),
                text,
              ],
            ),
    );
  }
}
