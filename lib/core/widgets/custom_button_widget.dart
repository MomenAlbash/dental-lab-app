import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// The app's button.
///
/// Colours are optional and default to the active theme, so a screen gets the
/// right button by writing nothing about colour at all — that is what keeps
/// every screen on the same palette, and what makes a brand or dark-mode
/// change land everywhere at once. Pass [backgroundColor] / [textColor] only
/// for a genuine exception (e.g. a destructive action).
class CustomButtonWidget extends StatelessWidget {
  const CustomButtonWidget({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.borderRadius,
    this.icon,
    this.horizontalPadding,
    this.verticalPadding,
    this.buttonWidth,
    this.buttonHeight,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
  });

  final String buttonText;

  /// Null disables the button — the themed disabled colours apply.
  final VoidCallback? onPressed;

  final double? borderRadius;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double? buttonWidth;
  final double? buttonHeight;
  final IconData? icon;

  /// Defaults to the theme's primary colour.
  final Color? backgroundColor;

  /// Defaults to the contrasting colour the theme pairs with [backgroundColor].
  final Color? textColor;

  /// Swaps the label for a spinner and blocks presses, so callers stop
  /// hand-rolling their own "submitting" branch around the button.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = backgroundColor ?? scheme.primary;
    final foreground = textColor ?? scheme.onPrimary;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.5),
          disabledForegroundColor: foreground.withValues(alpha: 0.8),
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding ?? 14,
            horizontal: horizontalPadding ?? AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppRadius.glass,
            ),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      buttonText,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font16MediumText.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
