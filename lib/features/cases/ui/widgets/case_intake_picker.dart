import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter/material.dart';

/// Chooses how the case arrives, and — for a digital one — where the scan came
/// from.
///
/// This is not a cosmetic label. The laboratory's routes carry a traditional
/// head and a digital head, and the server prunes the stages that do not apply
/// (`RouteStageAppliesTo`). Picking the wrong one, or leaving it unset, is how
/// a scanner case ends up with impression stages on its board.
class CaseIntakePicker extends StatelessWidget {
  const CaseIntakePicker({
    super.key,
    required this.method,
    required this.scanSource,
    required this.onMethodChanged,
    required this.onScanSourceChanged,
  });

  final ImpressionMethod? method;
  final DigitalScanSource? scanSource;
  final ValueChanged<ImpressionMethod> onMethodChanged;
  final ValueChanged<DigitalScanSource?> onScanSourceChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlassSectionTitle('طريقة الاستلام *'),
        const SizedBox(height: 4),
        // Marked required before the user tries to leave the step: the answer
        // decides which head of the lab's route the case runs on, so it cannot
        // be left open.
        Text(
          method == null
              ? 'مطلوب — كيف وصلت الحالة؟'
              : 'يمكن تغييرها قبل الحفظ',
          style: AppTextStyles.font12RegularHint.copyWith(
            color: method == null ? glass.warning : glass.onGlassMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MethodCard(
                icon: Icons.back_hand_outlined,
                title: ImpressionMethod.traditional.label,
                subtitle: 'يرسلها الطبيب أو يستلمها مندوب',
                isSelected: method == ImpressionMethod.traditional,
                onTap: () => onMethodChanged(ImpressionMethod.traditional),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MethodCard(
                icon: Icons.document_scanner_outlined,
                title: ImpressionMethod.digital.label,
                subtitle: 'ملف مسح يراجعه قسم الكونترول',
                isSelected: method == ImpressionMethod.digital,
                onTap: () => onMethodChanged(ImpressionMethod.digital),
              ),
            ),
          ],
        ),

        // The scan source only exists for a digital intake, so it appears with
        // that choice rather than sitting greyed out beside it.
        AnimatedSize(
          duration: AppMotion.base,
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: method != ImpressionMethod.digital
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'مصدر المسح *',
                        style: AppTextStyles.font14MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Required, and said before the user leaves the step:
                        // the two answers send the case down different paths —
                        // a doctor upload arrives with the file, a lab session
                        // still has to be booked and driven.
                        scanSource == null
                            ? 'مطلوب — من أين يصل المسح؟'
                            : 'يمكن تغييره قبل الحفظ',
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: scanSource == null
                              ? glass.warning
                              : glass.onGlassMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final source in DigitalScanSource.values)
                            _SourceChip(
                              label: source.label,
                              isSelected: scanSource == source,
                              // No longer clearable by re-tapping: the field is
                              // required now, and an "undo" that puts the form
                              // back into an invalid state is not a kindness.
                              onTap: () => onScanSourceChanged(source),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.enter,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.10)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? accent : glass.strokeColor,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: radius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? accent : glass.onGlassMuted,
                    ),
                    const Spacer(),
                    // Selection is marked by the check as well as the tint, so
                    // it never rests on colour alone.
                    if (isSelected)
                      Icon(Icons.check_circle, size: 18, color: accent),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
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

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? accent : glass.strokeColor,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: AppTextStyles.font13MediumPrimary.copyWith(
              color: isSelected ? accent : glass.onGlass,
            ),
          ),
        ),
      ),
    );
  }
}
