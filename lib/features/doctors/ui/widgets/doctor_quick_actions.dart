import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contact actions for a doctor — call, WhatsApp, email, map.
///
/// The phone number and email used to be plain label/value rows the user had
/// to copy by hand. Here the same data is the control: each tile launches the
/// matching intent, and tiles whose data is missing render disabled rather
/// than disappearing, so the row's shape stays stable between doctors.
class DoctorQuickActions extends StatelessWidget {
  const DoctorQuickActions({super.key, required this.doctor});

  final DoctorModel doctor;

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ShowToast(
          message: 'لا يوجد تطبيق يدعم هذا الإجراء',
          state: toastState.error,
        );
      }
    } catch (_) {
      ShowToast(message: 'تعذّر تنفيذ الإجراء', state: toastState.error);
    }
  }

  /// WhatsApp's `wa.me` form needs digits only, no `+`, spaces or dashes.
  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  Widget build(BuildContext context) {
    final phone = doctor.phoneNumber?.trim() ?? '';
    final email = doctor.email?.trim() ?? '';
    final address = doctor.address?.trim() ?? '';

    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.call_outlined,
        label: 'اتصال',
        color: context.glass.success,
        onTap: phone.isEmpty
            ? null
            : () => _launch(context, Uri.parse('tel:$phone')),
      ),
      _QuickAction(
        icon: Icons.chat_bubble_outline,
        label: 'واتساب',
        color: const Color(0xFF25D366),
        onTap: phone.isEmpty
            ? null
            : () => _launch(
                context,
                Uri.parse('https://wa.me/${_digitsOnly(phone)}'),
              ),
      ),
      _QuickAction(
        icon: Icons.mail_outline,
        label: 'بريد',
        color: context.glass.info,
        onTap: email.isEmpty
            ? null
            : () => _launch(context, Uri.parse('mailto:$email')),
      ),
      _QuickAction(
        icon: Icons.location_on_outlined,
        label: 'الموقع',
        color: Theme.of(context).colorScheme.primary,
        onTap: address.isEmpty
            ? null
            : () => _launch(
                context,
                Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query='
                  '${Uri.encodeComponent(address)}',
                ),
              ),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: _QuickActionTile(action: actions[i])),
        ],
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Null renders the tile disabled — the data behind it is missing.
  final VoidCallback? onTap;
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.action.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final enabled = widget.action.onTap != null;
    final tint = enabled ? widget.action.color : glass.onGlassMuted;
    final radius = BorderRadius.circular(AppRadius.glass);

    return AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.action.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: glass.surfaceGradient,
                border: Border.all(color: glass.strokeColor),
                boxShadow: enabled ? glass.shadows : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint.withValues(alpha: 0.14),
                    ),
                    child: Icon(widget.action.icon, size: 19, color: tint),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
