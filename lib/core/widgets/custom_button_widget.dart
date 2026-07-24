import 'package:flutter/material.dart';

class CustomButtonWidget extends StatelessWidget {
  const CustomButtonWidget({
    super.key,
    this.borderRadius,
    this.icon,
    this.horizontalPadding,
    required this.textColor,
    this.verticalPadding,
    this.buttonWidth,
    this.buttonHeight,
    required this.onPressed,
    this.backgroundColor,
    required this.buttonText,
  });
  final double? borderRadius;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double? buttonWidth;
  final double? buttonHeight;
  final String buttonText;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
            ),
          ),
          padding: WidgetStateProperty.all<EdgeInsets>(
            EdgeInsets.symmetric(
              vertical: verticalPadding ?? 14,
              horizontal: horizontalPadding ?? 16,
            ),
          ),
          backgroundColor: WidgetStateProperty.all(
            backgroundColor ?? Colors.white,
          ),
          // Removed minimumSize to allow SizedBox to control the size
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Ensure the inner Row takes minimum space
          children: [
            icon != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      right: 8.0,
                    ), // Changed left to right for spacing between icon and text
                    child: Icon(icon, color: textColor),
                  )
                : const SizedBox.shrink(),
            Flexible(
              // Added Flexible to prevent text overflow
              child: Text(
                buttonText,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis, // Added ellipsis for long text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
