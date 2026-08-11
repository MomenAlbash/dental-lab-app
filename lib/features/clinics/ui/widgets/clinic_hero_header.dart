import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

/// Collapsing identity header for the clinic detail screen.
///
/// Mirrors the doctor/patient detail headers' mechanics (a gradient panel that
/// parallaxes into a compact toolbar row) but carries what identifies an
/// organisation rather than a person: an initials mark instead of a gender
/// icon, and the clinic code as the pill instead of an active/paused status.
class ClinicSliverHeader extends StatelessWidget {
  const ClinicSliverHeader({
    super.key,
    required this.clinic,
    required this.onEdit,
  });

  final ClinicModel clinic;
  final VoidCallback onEdit;

  // Taller than the patient header's 236: two chips (code + city) can sit
  // side by side or wrap, and at large text scales the wrapped row needs more
  // room than the panel's fixed OverflowBox height allows before it overflows.
  static const double expandedHeight = 284;

  @override
  Widget build(BuildContext context) {
    final name = clinic.name.trim().isEmpty ? '—' : clinic.name.trim();

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
      actions: [
        IconButton(
          tooltip: 'تعديل',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      // `FlexibleSpaceBar.title` is not used: it stays mounted while expanded
      // too, which would render the name twice. The two placements are
      // cross-faded by scroll progress instead — see the doctor header for
      // the full rationale.
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
              _Backdrop(
                child: panelOpacity == 0
                    ? const SizedBox.shrink()
                    : Opacity(
                        opacity: panelOpacity,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minHeight: maxExtent,
                            maxHeight: maxExtent,
                            child: _Panel(clinic: clinic, name: name),
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
                          child: _CompactIdentity(clinic: clinic, name: name),
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

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.glass.brandGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(top: -50, right: -35, child: _Glow(size: 170)),
          const Positioned(bottom: -60, left: -40, child: _Glow(size: 150)),
          child,
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.clinic, required this.name});

  final ClinicModel clinic;
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
            _Avatar(name: name, heroTag: 'clinic-avatar-${clinic.id}'),
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
            _IdentityChips(clinic: clinic),
          ],
        ),
      ),
    );
  }
}

class _CompactIdentity extends StatelessWidget {
  const _CompactIdentity({required this.clinic, required this.name});

  final ClinicModel clinic;
  final String name;

  @override
  Widget build(BuildContext context) {
    final subtitle = clinic.code?.trim().isNotEmpty ?? false
        ? clinic.code!.trim()
        : clinic.cityName?.trim();

    return Row(
      children: [
        _Avatar(name: name, heroTag: null, size: 34),
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
              if (subtitle != null && subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.heroTag, this.size = 84});

  final String name;
  final Object? heroTag;
  final double size;

  /// Up to two leading characters of the name — the same institutional-mark
  /// treatment as the list row's avatar.
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
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: size >= 60 ? 2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: size >= 60 ? 20 : 8,
            offset: Offset(0, size >= 60 ? 8 : 3),
          ),
        ],
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
          color: Colors.white,
        ),
      ),
    );

    if (heroTag == null) return circle;
    return Hero(tag: heroTag!, child: circle);
  }
}

/// The clinic code and, when present, the city — replaces the doctor header's
/// active/paused pill since a clinic has no such status.
class _IdentityChips extends StatelessWidget {
  const _IdentityChips({required this.clinic});

  final ClinicModel clinic;

  @override
  Widget build(BuildContext context) {
    final code = clinic.code?.trim();
    final cityName = clinic.cityName?.trim();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        if (code != null && code.isNotEmpty)
          _Chip(icon: Icons.tag_outlined, label: code),
        if (cityName != null && cityName.isNotEmpty)
          _Chip(icon: Icons.location_city_outlined, label: cityName),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});

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
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
