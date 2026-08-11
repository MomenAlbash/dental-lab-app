import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A doctor row.
///
/// Shaped as a profile card rather than a generic list tile: a status-coloured
/// rail down the leading edge, an initials avatar carrying a live/paused dot,
/// and the phone number as a working call button instead of dead text — the
/// same treatment the detail screen uses, so the two read as one product.
class DoctorListItemWidget extends StatelessWidget {
  const DoctorListItemWidget({
    super.key,
    required this.fullName,
    required this.initials,
    required this.phoneNumber,
    required this.clinicName,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    this.approvalStatus = DoctorApprovalStatus.approved,
    this.onTap,
    this.heroTag,
  });

  final String fullName;
  final String initials;
  final String phoneNumber;
  final String clinicName;
  final bool isActive;

  /// Self-registered doctors wait on the lab's decision — the row says so, and
  /// the decision itself is taken on the detail screen.
  final DoctorApprovalStatus approvalStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  /// Shares the avatar with the detail screen. Null disables the transition
  /// (e.g. when the same doctor could appear twice in one tree).
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    // A pending registration outranks active/paused on the rail: it is the one
    // state that needs the user to do something.
    final railColor = switch (approvalStatus) {
      DoctorApprovalStatus.pending => glass.warning,
      DoctorApprovalStatus.rejected => glass.error,
      DoctorApprovalStatus.approved =>
        isActive ? Theme.of(context).colorScheme.primary : glass.onGlassMuted,
    };

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
                    // Status rail: colour-codes the row without spending a
                    // badge on it, and gives the card a distinct silhouette.
                    Container(width: 4, color: railColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            _Avatar(
                              initials: initials,
                              isActive: isActive,
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
                                  _ClinicLine(
                                    clinicName: clinicName,
                                    color: glass.onGlassMuted,
                                  ),
                                  // Approved is the ordinary state, so it gets
                                  // no badge — only the two that mean
                                  // something is outstanding or settled badly.
                                  if (approvalStatus !=
                                      DoctorApprovalStatus.approved) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    _ApprovalBadge(status: approvalStatus),
                                  ],
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

/// Pill stating where the registration stands. Pending carries an icon as
/// well as the colour, so it still reads as "needs you" without relying on
/// colour alone.
class _ApprovalBadge extends StatelessWidget {
  const _ApprovalBadge({required this.status});

  final DoctorApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final (Color color, IconData icon) = switch (status) {
      DoctorApprovalStatus.pending => (glass.warning, Icons.schedule),
      DoctorApprovalStatus.rejected => (glass.error, Icons.block_outlined),
      DoctorApprovalStatus.approved => (
        glass.success,
        Icons.check_circle_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            status.arabicLabel,
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.isActive,
    required this.heroTag,
  });

  final String initials;
  final bool isActive;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final circle = Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: glass.brandGradient,
      ),
      child: Text(
        initials,
        style: AppTextStyles.font16MediumText.copyWith(color: Colors.white),
      ),
    );

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          heroTag == null ? circle : Hero(tag: heroTag!, child: circle),
          // Live/paused dot, ringed in the card colour so it reads as
          // attached to the avatar rather than floating over it.
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? context.glass.success : glass.onGlassMuted,
                border: Border.all(
                  color: glass.onGlass.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicLine extends StatelessWidget {
  const _ClinicLine({required this.clinicName, required this.color});

  final String clinicName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasClinic = clinicName.trim().isNotEmpty;

    return Row(
      children: [
        Icon(
          hasClinic ? Icons.local_hospital_outlined : Icons.help_outline,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            hasClinic ? clinicName.trim() : 'بدون عيادة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// The phone number as a tappable call chip.
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
                // Flexible: the number is user data and the row is already
                // width-constrained, so at large text scales it must ellipsise
                // rather than push past the card.
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
        // InkResponse rather than IconButton so the press state is ours to
        // observe; an IconButton wrapped in a GestureDetector would fight over
        // the tap in the gesture arena.
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
