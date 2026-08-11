import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// An employee row.
///
/// Shaped as a profile card — matches the doctor row: an initials avatar,
/// then the code and phone number, with the phone as a working call button
/// instead of dead text.
class EmployeeListItemWidget extends StatelessWidget {
  const EmployeeListItemWidget({
    super.key,
    required this.fullName,
    required this.initials,
    required this.code,
    required this.phoneNumber,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.heroTag,
  });

  final String fullName;
  final String initials;
  final String code;
  final String phoneNumber;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  /// Shares the avatar with the detail screen. Null disables the transition.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            _Avatar(
                              initials: initials,
                              accent: accent,
                              heroTag: heroTag,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fullName.trim().isEmpty
                                        ? '—'
                                        : fullName.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font16MediumText
                                        .copyWith(color: glass.onGlass),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    code.isEmpty ? 'بدون رمز' : 'الرمز: $code',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: glass.onGlassMuted),
                                  ),
                                  if (phoneNumber.trim().isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    _CallChip(phoneNumber: phoneNumber.trim()),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _RowAction(
                                  icon: Icons.edit_outlined,
                                  color: glass.onGlassMuted,
                                  tooltip: 'تعديل',
                                  onPressed: onEdit,
                                ),
                                _RowAction(
                                  icon: Icons.delete_outline,
                                  color: glass.error,
                                  tooltip: 'حذف',
                                  onPressed: onDelete,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.accent, this.heroTag});

  final String initials;
  final Color accent;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: context.glass.brandGradient,
      ),
      child: Text(
        initials,
        style: AppTextStyles.font16MediumText.copyWith(color: Colors.white),
      ),
    );

    return heroTag == null ? circle : Hero(tag: heroTag!, child: circle);
  }
}

/// The phone number as a tappable call chip.
class _CallChip extends StatelessWidget {
  const _CallChip({required this.phoneNumber});

  final String phoneNumber;

  Future<void> _call() async {
    await launchUrl(
      Uri.parse('tel:$phoneNumber'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _call,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_outlined, size: 13, color: accent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    phoneNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font13MediumPrimary.copyWith(
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An icon action that dips slightly while held.
class _RowAction extends StatefulWidget {
  const _RowAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_RowAction> createState() => _RowActionState();
}

class _RowActionState extends State<_RowAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
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
    );
  }
}
