import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Labelled filter control for a list screen's app bar.
///
/// A bare funnel icon reads as decoration to most users, so this spells out
/// "تصفية" and turns solid with the active-filter count once any filter is on
/// — the state is legible without opening the sheet. Was duplicated
/// byte-for-byte across the doctors and patients screens; consolidated here.
class GlassFilterButton extends StatelessWidget {
  const GlassFilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final isFiltering = activeCount > 0;
    final radius = BorderRadius.circular(AppRadius.full);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.enter,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: isFiltering
                  ? accent.withValues(alpha: 0.18)
                  : glass.fillColor,
              border: Border.all(
                color: isFiltering ? accent : glass.strokeColor,
                width: isFiltering ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 17,
                  color: isFiltering ? accent : glass.onGlass,
                ),
                const SizedBox(width: 5),
                Text(
                  'تصفية',
                  style: AppTextStyles.font13MediumPrimary.copyWith(
                    color: isFiltering ? accent : glass.onGlass,
                  ),
                ),
                if (isFiltering) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                    child: Text(
                      '$activeCount',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
