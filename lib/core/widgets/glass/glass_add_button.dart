import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// The app's "add entity" floating action.
///
/// A gradient pill rather than a stock circular FAB: it carries the brand
/// gradient, states its purpose in words, and collapses to a bare icon while
/// the list behind it is scrolled. Every list screen (doctors, patients,
/// clinics, ...) used to keep its own byte-for-byte copy of this widget with
/// only the label swapped — one shared widget means a design change lands
/// everywhere at once instead of needing N synchronized edits.
class GlassAddButton extends StatefulWidget {
  const GlassAddButton({
    super.key,
    required this.label,
    required this.isExtended,
    required this.onPressed,
  });

  /// Shown next to the `+` icon while extended, and as the tooltip always.
  final String label;
  final bool isExtended;
  final VoidCallback onPressed;

  @override
  State<GlassAddButton> createState() => _GlassAddButtonState();
}

class _GlassAddButtonState extends State<GlassAddButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.full);

    return Tooltip(
      message: widget.label,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: glass.glowColor,
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: glass.brandGradient),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  onTapDown: (_) => _setPressed(true),
                  onTapUp: (_) => _setPressed(false),
                  onTapCancel: () => _setPressed(false),
                  child: AnimatedSize(
                    duration: AppMotion.base,
                    curve: AppMotion.enter,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isExtended ? 20 : 16,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 22),
                          // Removed, not just faded, so AnimatedSize can
                          // shrink the pill around it.
                          if (widget.isExtended) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              widget.label,
                              style: AppTextStyles.font14MediumText.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
