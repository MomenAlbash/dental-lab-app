import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// One row of a [DashboardBreakdownBars] chart.
class BreakdownBar {
  const BreakdownBar({
    required this.label,
    required this.value,
    required this.color,
    this.valueLabel,
  });

  final String label;

  /// Drives the bar's length. Negative values are clamped to zero rather than
  /// drawn backwards.
  final double value;

  final Color color;

  /// What to print at the end of the row. Defaults to [value] as a whole
  /// number — set it where the figure needs formatting (money, percentages).
  final String? valueLabel;
}

/// A horizontal bar chart sized to a phone.
///
/// Bars rather than a pie: these are counts across a handful of named
/// categories, and comparing lengths on a shared baseline is the one job a
/// human eye does well. It also degrades gracefully — a long Arabic stage name
/// gets a full-width line to itself instead of a leader line into a slice.
///
/// Each bar is measured against the largest value in the set, so the biggest
/// category always fills the track and the rest read as fractions of it.
class DashboardBreakdownBars extends StatelessWidget {
  const DashboardBreakdownBars({super.key, required this.bars});

  final List<BreakdownBar> bars;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final maxValue = bars
        .map((b) => b.value)
        .fold<double>(0, (a, b) => b > a ? b : a);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bars.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _Bar(
            bar: bars[i],
            // An all-zero set would divide by zero; every bar reads empty,
            // which is the honest picture.
            fraction: maxValue <= 0
                ? 0
                : (bars[i].value.clamp(0, double.infinity) / maxValue),
            trackColor: glass.mutedSurface,
            index: i,
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.bar,
    required this.fraction,
    required this.trackColor,
    required this.index,
  });

  final BreakdownBar bar;
  final double fraction;
  final Color trackColor;
  final int index;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Semantics(
      label: '${bar.label}: ${bar.valueLabel ?? bar.value.round()}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bar.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font13MediumPrimary.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                bar.valueLabel ?? '${bar.value.round()}',
                style: AppTextStyles.font13MediumPrimary.copyWith(
                  color: bar.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Stack(
              children: [
                Container(height: 8, color: trackColor),
                // FractionallySizedBox rather than a measured width: the track
                // is whatever the column gives it, and this follows a rotation
                // or a split-screen resize without a LayoutBuilder.
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: AnimatedContainer(
                    duration: AppMotion.slow,
                    curve: AppMotion.enter,
                    height: 8,
                    decoration: BoxDecoration(
                      color: bar.color,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
