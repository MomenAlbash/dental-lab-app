import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A clinic row.
///
/// A clinic is an organisation, not a person, so the card leads with an
/// initials mark drawn from its name (matching the doctor/patient rows'
/// avatar treatment) rather than a generic building icon, and closes with the
/// phone number as a working call button — the same contact-first idea
/// applied everywhere else in the app.
class ClinicListItemWidget extends StatelessWidget {
  const ClinicListItemWidget({
    super.key,
    required this.name,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.cityName,
    this.code,
    this.phoneNumber,
    this.onTap,
    this.heroTag,
  });

  final String name;
  final String address;
  final String? cityName;
  final String? code;
  final String? phoneNumber;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  /// Shares the avatar with the detail screen. Null disables the transition.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final hasPhone = (phoneNumber ?? '').trim().isNotEmpty;

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
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClinicAvatar(name: name, heroTag: heroTag),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name.trim().isEmpty ? '—' : name.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.font16MediumText.copyWith(
                              color: glass.onGlass,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _AddressLine(
                            address: address,
                            color: glass.onGlassMuted,
                          ),
                          if ((cityName?.isNotEmpty ?? false) ||
                              (code?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (cityName?.isNotEmpty ?? false)
                                  _Badge(
                                    label: cityName!,
                                    color: context.glass.info,
                                  ),
                                if (code?.isNotEmpty ?? false)
                                  _Badge(
                                    label: code!,
                                    color: glass.onGlassMuted,
                                  ),
                              ],
                            ),
                          ],
                          if (hasPhone) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _CallChip(phoneNumber: phoneNumber!.trim()),
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
                          color: context.glass.error,
                          tooltip: 'حذف',
                          onPressed: onDelete,
                        ),
                      ],
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

class _ClinicAvatar extends StatelessWidget {
  const _ClinicAvatar({required this.name, required this.heroTag});

  final String name;
  final Object? heroTag;

  /// Up to two leading characters of the name — mirrors the doctor/patient
  /// avatar so a clinic's mark reads the same way at a glance.
  String get _initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '؟';
    return words
        .map((word) => String.fromCharCode(word.runes.first))
        .take(2)
        .join();
  }

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
        _initials,
        style: AppTextStyles.font16MediumText.copyWith(color: Colors.white),
      ),
    );

    if (heroTag == null) return circle;
    return Hero(tag: heroTag!, child: circle);
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({required this.address, required this.color});

  final String address;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.trim().isNotEmpty;

    return Row(
      children: [
        Icon(
          hasAddress ? Icons.location_on_outlined : Icons.help_outline,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            hasAddress ? address.trim() : 'بدون عنوان',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

/// The phone number as a tappable call chip, matching the doctor/patient rows.
class _CallChip extends StatelessWidget {
  const _CallChip({required this.phoneNumber});

  final String phoneNumber;

  Future<void> _call() async {
    try {
      final launched = await launchUrl(
        Uri.parse('tel:$phoneNumber'),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ShowToast(message: 'تعذّر بدء الاتصال', state: toastState.error);
      }
    } catch (_) {
      ShowToast(message: 'تعذّر بدء الاتصال', state: toastState.error);
    }
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
