import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Section heading with a short accent rule, optionally followed by a count
/// badge and a trailing action.
///
/// Cheaper visually than wrapping each section in another card, and it stops a
/// detail page reading as one undifferentiated stack.
class GlassSectionTitle extends StatelessWidget {
  const GlassSectionTitle(this.text, {super.key, this.count, this.trailing});

  final String text;

  /// Rendered as a tinted pill after the title. Null hides it.
  final int? count;

  /// Pushed to the far end of the row (typically a `TextButton.icon`).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Flexible so a large system text scale ellipsises the heading rather
        // than pushing the trailing action off the row.
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.font12RegularHint.copyWith(color: accent),
            ),
          ),
        ],
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}
