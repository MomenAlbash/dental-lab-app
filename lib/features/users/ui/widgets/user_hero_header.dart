import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:flutter/material.dart';

/// Collapsing brand header for the user detail screen — mirrors
/// [DoctorSliverHeader] / [EmployeeSliverHeader]'s layout and motion.
///
/// No edit action in the toolbar: unlike doctors/employees, a user account
/// is edited inline on this same screen (email/role/admin), not through a
/// separate form route.
class UserSliverHeader extends StatelessWidget {
  const UserSliverHeader({super.key, required this.user});

  final UserModel user;

  static const double expandedHeight = 240;

  @override
  Widget build(BuildContext context) {
    final name = user.username?.trim().isNotEmpty == true
        ? user.username!.trim()
        : '—';

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.glassLg),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topInset = MediaQuery.paddingOf(context).top;
          final maxExtent = expandedHeight + topInset;
          final minExtent = kToolbarHeight + topInset;

          final collapsed =
              ((maxExtent - constraints.maxHeight) / (maxExtent - minExtent))
                  .clamp(0.0, 1.0);

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
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minHeight: maxExtent,
                            maxHeight: maxExtent,
                            child: _HeaderPanel(user: user, name: name),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 52),
                        child: Opacity(
                          opacity: titleOpacity,
                          child: _CompactIdentity(user: user, name: name),
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
          const Positioned(top: -60, right: -40, child: _Blob(size: 200)),
          const Positioned(bottom: -70, left: -50, child: _Blob(size: 180)),
          child,
        ],
      ),
    );
  }
}

class _CompactIdentity extends StatelessWidget {
  const _CompactIdentity({required this.user, required this.name});

  final UserModel user;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _Avatar(user: user, size: 34),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font14MediumText.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Identity block: photo (borrowed from the linked doctor/employee record),
/// username, then account-type + status pills.
class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.user, required this.name});

  final UserModel user;
  final String name;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, kToolbarHeight - 8, 24, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(user: user),
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _Pill(label: user.type.isDoctor ? 'حساب طبيب' : 'حساب موظف'),
                _Pill(label: user.isActive ? 'مفعّل' : 'موقوف'),
                if (user.isAdmin) const _Pill(label: 'مدير'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.size = 88});

  final UserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(user.imagePath);

    final fallback = Center(
      child: Icon(
        user.type.isDoctor
            ? Icons.medical_services_outlined
            : Icons.badge_outlined,
        size: size * 0.4,
        color: Colors.white,
      ),
    );

    return Container(
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
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: Colors.white),
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
