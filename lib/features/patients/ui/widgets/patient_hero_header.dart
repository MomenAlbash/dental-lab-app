import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:flutter/material.dart';

/// Collapsing identity header for the patient detail screen.
///
/// Mirrors the doctor detail header's mechanics (a gradient panel that
/// parallaxes into a compact toolbar row) but carries what actually
/// distinguishes a patient: no status to show, so the case count takes that
/// slot instead — it's the number a clinician actually wants at a glance.
class PatientSliverHeader extends StatelessWidget {
  const PatientSliverHeader({super.key, required this.patient});

  final PatientModel patient;

  static const double expandedHeight = 236;

  @override
  Widget build(BuildContext context) {
    final name = patient.fullName.isEmpty ? '—' : patient.fullName;

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
      // `FlexibleSpaceBar.title` is not used: it stays mounted while expanded
      // too, which would render the name twice. The two placements are
      // cross-faded by scroll progress instead — see the doctor header for the
      // full rationale.
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
                            child: _Panel(patient: patient, name: name),
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
                          child: _CompactIdentity(patient: patient, name: name),
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
  const _Panel({required this.patient, required this.name});

  final PatientModel patient;
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
            _Avatar(
              gender: patient.gender,
              heroTag: 'patient-avatar-${patient.id}',
            ),
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
            _StatChips(patient: patient),
          ],
        ),
      ),
    );
  }
}

class _CompactIdentity extends StatelessWidget {
  const _CompactIdentity({required this.patient, required this.name});

  final PatientModel patient;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(gender: patient.gender, heroTag: null, size: 34),
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
              Text(
                '${patient.caseCount} حالة',
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
  const _Avatar({required this.gender, required this.heroTag, this.size = 84});

  final PatientGender? gender;
  final Object? heroTag;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = switch (gender) {
      PatientGender.male => Icons.male_outlined,
      PatientGender.female => Icons.female_outlined,
      null => Icons.person_outline,
    };

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
      child: Icon(icon, color: Colors.white, size: size * 0.45),
    );

    if (heroTag == null) return circle;
    return Hero(tag: heroTag!, child: circle);
  }
}

/// The case count and, when present, the doctor — replaces the status pill
/// used on the doctor header since a patient has no active/paused state.
class _StatChips extends StatelessWidget {
  const _StatChips({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    final doctorName = patient.doctorName?.trim();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _Chip(icon: Icons.folder_outlined, label: '${patient.caseCount} حالة'),
        if (doctorName != null && doctorName.isNotEmpty)
          _Chip(icon: Icons.medical_services_outlined, label: 'د. $doctorName'),
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
