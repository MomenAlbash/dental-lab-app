import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_card.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A patient row.
///
/// What makes a patient worth glancing at in a list is not a status — it's
/// *who is treating them and how many cases they have* — so the design leads
/// with a gender-marked avatar and closes with the case count as a stat badge,
/// rather than a generic chevron. The phone number, when present, is a
/// working call button like the doctor row's.
class PatientListItemWidget extends StatelessWidget {
  const PatientListItemWidget({
    super.key,
    required this.fullName,
    required this.doctorName,
    required this.clinicName,
    required this.caseCount,
    required this.onTap,
    this.gender,
    this.phoneNumber,
    this.heroTag,
  });

  final String fullName;
  final String doctorName;
  final String clinicName;
  final int caseCount;
  final VoidCallback onTap;
  final PatientGender? gender;
  final String? phoneNumber;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final hasPhone = (phoneNumber ?? '').trim().isNotEmpty;

    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PatientAvatar(gender: gender, heroTag: heroTag),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName.trim().isEmpty ? '—' : fullName.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 4),
                _AssociationLine(
                  doctorName: doctorName,
                  clinicName: clinicName,
                  color: glass.onGlassMuted,
                ),
                if (hasPhone) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _CallChip(phoneNumber: phoneNumber!.trim()),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _CaseCountBadge(count: caseCount),
        ],
      ),
    );
  }
}

class _PatientAvatar extends StatelessWidget {
  const _PatientAvatar({required this.gender, required this.heroTag});

  final PatientGender? gender;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final icon = switch (gender) {
      PatientGender.male => Icons.male_outlined,
      PatientGender.female => Icons.female_outlined,
      null => Icons.person_outline,
    };

    final circle = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: context.glass.brandGradient,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );

    if (heroTag == null) return circle;
    return Hero(tag: heroTag!, child: circle);
  }
}

class _AssociationLine extends StatelessWidget {
  const _AssociationLine({
    required this.doctorName,
    required this.clinicName,
    required this.color,
  });

  final String doctorName;
  final String clinicName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasDoctor = doctorName.trim().isNotEmpty;
    final hasClinic = clinicName.trim().isNotEmpty;

    if (!hasDoctor && !hasClinic) {
      return Row(
        children: [
          Icon(Icons.link_off, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'بدون طبيب',
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.medical_services_outlined, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            [
              if (hasDoctor) 'د. ${doctorName.trim()}',
              if (hasClinic) clinicName.trim(),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12RegularHint.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// The number of cases as a small stat badge — this is the datum most worth
/// scanning a patient list for, so it gets its own visual weight instead of
/// being buried in a text line.
class _CaseCountBadge extends StatelessWidget {
  const _CaseCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final hasCases = count > 0;
    final color = hasCases ? context.glass.info : glass.onGlassMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.font14MediumText.copyWith(color: color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'حالة',
          style: AppTextStyles.font12RegularHint.copyWith(color: color),
        ),
      ],
    );
  }
}

/// The phone number as a tappable call chip, matching the doctor row.
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
