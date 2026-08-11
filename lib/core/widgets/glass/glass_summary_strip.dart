import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// One counter tile in a [GlassSummaryStrip].
class GlassSummaryTileData<T> {
  const GlassSummaryTileData({
    required this.value,
    required this.label,
    required this.count,
    required this.color,
  });

  /// The filter value this tile selects (e.g. an enum case).
  final T value;
  final String label;
  final int count;
  final Color color;
}

/// A row of counters that doubles as a status filter.
///
/// The doctors list pioneered this: the counts are not decoration — each tile
/// is the control for its own slice, so "show me the paused doctors" is one
/// tap instead of a trip through a filter sheet. Generic over the filter
/// enum [T] so every list screen (doctors, users, ...) shares one
/// implementation instead of each keeping its own copy.
class GlassSummaryStrip<T> extends StatelessWidget {
  const GlassSummaryStrip({
    super.key,
    required this.tiles,
    required this.selected,
    required this.onSelected,
  });

  final List<GlassSummaryTileData<T>> tiles;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryTile(
              label: tiles[i].label,
              count: tiles[i].count,
              color: tiles[i].color,
              isSelected: selected == tiles[i].value,
              onTap: () => onSelected(tiles[i].value),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: isSelected ? null : glass.surfaceGradient,
            color: isSelected ? color.withValues(alpha: 0.16) : null,
            border: Border.all(
              color: isSelected ? color : glass.strokeColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppTextStyles.font20BoldText.copyWith(
                  color: isSelected ? color : glass.onGlass,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: isSelected ? color : glass.onGlassMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
