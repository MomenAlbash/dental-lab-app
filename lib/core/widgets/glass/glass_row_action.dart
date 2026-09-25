import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:flutter/material.dart';

/// A small icon button for a list row's trailing actions — edit, delete, and
/// the like.
///
/// Lives in `core/` because every list row wants the same thing: a 19px icon
/// with a tinted press response, tight enough that two of them stack inside a
/// card without crowding the content beside them.
///
/// A null [onPressed] renders it disabled — the row is there but the action
/// is refused, which is why [tooltip] should then say why.
class GlassRowAction extends StatefulWidget {
  const GlassRowAction({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;

  /// Doubles as the explanation when [onPressed] is null.
  final String tooltip;

  final VoidCallback? onPressed;

  @override
  State<GlassRowAction> createState() => _GlassRowActionState();
}

class _GlassRowActionState extends State<GlassRowAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return Tooltip(
      message: widget.tooltip,
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: InkResponse(
            onTap: widget.onPressed,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            radius: 20,
            highlightColor: widget.color.withValues(alpha: 0.10),
            splashColor: widget.color.withValues(alpha: 0.16),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(widget.icon, size: 19, color: widget.color),
            ),
          ),
        ),
      ),
    );
  }
}
