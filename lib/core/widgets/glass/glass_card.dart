import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:flutter/material.dart';

import 'glass_container.dart';

/// A tappable glass pane for repeating content (list rows, detail sections).
///
/// Deliberately does not blur — see the note on [GlassContainer]. Adds a subtle
/// press-scale so a tap feels physical, which the previous flat `Container` +
/// `InkWell` cards lacked.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppRadius.glass);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      child: GlassContainer(
        margin: widget.margin,
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: radius,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
