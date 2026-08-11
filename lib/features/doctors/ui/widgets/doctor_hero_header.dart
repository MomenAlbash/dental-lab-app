import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter/material.dart';

/// Collapsing brand header for the doctor detail screen.
///
/// Replaces the old "avatar centred above a white page" layout: the identity
/// lives in a coloured, curved panel that parallaxes away on scroll and leaves
/// a compact title bar behind, so the screen has a focal point instead of
/// reading as a form printout.
class DoctorSliverHeader extends StatelessWidget {
  const DoctorSliverHeader({
    super.key,
    required this.doctor,
    required this.onEdit,
  });

  final DoctorModel doctor;
  final VoidCallback onEdit;

  static const double expandedHeight = 268;

  @override
  Widget build(BuildContext context) {
    final name = doctor.fullName.isEmpty ? '—' : doctor.fullName;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      // Curved bottom edge — the panel reads as a card the content slides
      // under, not as a rectangular banner.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.glassLg),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'تعديل',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      // `FlexibleSpaceBar.title` is deliberately not used: it stays on screen
      // while expanded as well, which rendered the name twice. Instead the two
      // placements are cross-faded by scroll progress, and only the one with
      // non-zero opacity is built — so the name is never in the tree twice at
      // rest.
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topInset = MediaQuery.paddingOf(context).top;
          final maxExtent = expandedHeight + topInset;
          final minExtent = kToolbarHeight + topInset;

          final collapsed =
              ((maxExtent - constraints.maxHeight) / (maxExtent - minExtent))
                  .clamp(0.0, 1.0);

          // The panel clears out before the toolbar title arrives, so the two
          // never overlap mid-flight.
          final panelOpacity = (1 - collapsed * 1.8).clamp(0.0, 1.0);
          final titleOpacity = ((collapsed - 0.65) / 0.35).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              _HeaderBackdrop(
                child: panelOpacity == 0
                    ? const SizedBox.shrink()
                    : Opacity(
                        opacity: panelOpacity,
                        // The panel keeps its full expanded height while the
                        // header shrinks: it is clipped away, not squeezed.
                        // Laying it out against the shrinking constraint
                        // overflowed the column mid-scroll.
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minHeight: maxExtent,
                            maxHeight: maxExtent,
                            child: _HeaderPanel(doctor: doctor, name: name),
                          ),
                        ),
                      ),
              ),
              if (titleOpacity > 0)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: SizedBox(
                      height: kToolbarHeight,
                      // Horizontal insets clear the back button and the edit
                      // action on either side of the toolbar.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 52),
                        child: Opacity(
                          opacity: titleOpacity,
                          child: _CompactIdentity(doctor: doctor, name: name),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The gradient plate and its decorative glows. Stays fully opaque as the
/// header collapses so the toolbar keeps a solid brand background.
class _HeaderBackdrop extends StatelessWidget {
  const _HeaderBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.glass.brandGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft light blobs give the flat gradient depth.
          const Positioned(top: -60, right: -40, child: _Blob(size: 200)),
          const Positioned(bottom: -70, left: -50, child: _Blob(size: 180)),
          child,
        ],
      ),
    );
  }
}

/// The collapsed form of the identity block: the photo shrinks to the side
/// with the name beside it and the status underneath, rather than the panel
/// disappearing and leaving a bare title.
///
/// The avatar here is intentionally *not* a [Hero]: during the cross-fade both
/// this and the expanded panel can be mounted for a frame, and two heroes
/// sharing a tag in one tree is an error.
class _CompactIdentity extends StatelessWidget {
  const _CompactIdentity({required this.doctor, required this.name});

  final DoctorModel doctor;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _Avatar(doctor: doctor, size: 34, showHero: false),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font14MediumText.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              _StatusPill(isActive: doctor.isActive, compact: true),
            ],
          ),
        ),
      ],
    );
  }
}

/// Identity block: photo, then name, then status — the order requested.
class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.doctor, required this.name});

  final DoctorModel doctor;
  final String name;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        // Top inset clears the toolbar row (back button / edit action).
        padding: const EdgeInsets.fromLTRB(24, kToolbarHeight - 8, 24, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(doctor: doctor),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font20BoldText.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusPill(isActive: doctor.isActive),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.doctor, this.size = 88, this.showHero = true});

  final DoctorModel doctor;
  final double size;

  /// Only the expanded panel's avatar carries the hero tag — two heroes with
  /// the same tag in one tree is an error, and both can be mounted for a frame
  /// during the collapse cross-fade.
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(doctor.imagePath);

    final fallback = Center(
      child: Text(
        doctor.initials,
        style: AppTextStyles.font24BoldText.copyWith(
          color: Colors.white,
          // Scales with the avatar so the initials still fit when compact.
          fontSize: size * 0.34,
        ),
      ),
    );

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: size >= 60 ? 2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: size >= 60 ? 22 : 8,
            offset: Offset(0, size >= 60 ? 8 : 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? fallback
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );

    if (!showHero) return avatar;
    return Hero(tag: 'doctor-avatar-${doctor.id}', child: avatar);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive, this.compact = false});

  final bool isActive;

  /// Tighter padding for the collapsed row, which only has the toolbar's
  /// height to work with.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? const Color(0xFF7BF1A8)
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'نشط' : 'موقوف',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.20),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
