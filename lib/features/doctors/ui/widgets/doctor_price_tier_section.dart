import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/price_tier_history_sheet.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:flutter/material.dart';

/// The price list this doctor is billed at, and the button that changes it.
///
/// The doctor-first half of the same link the price-tier screen edits
/// tier-first. Both are needed: "who is on the gold list" and "what is this
/// doctor on" are asked by different people at different times.
class DoctorPriceTierSection extends StatefulWidget {
  const DoctorPriceTierSection({
    super.key,
    required this.doctor,
    required this.isBusy,
    required this.onChanged,
  });

  final DoctorModel doctor;
  final bool isBusy;

  /// Null moves the doctor off every tier.
  final ValueChanged<String?> onChanged;

  @override
  State<DoctorPriceTierSection> createState() => _DoctorPriceTierSectionState();
}

class _DoctorPriceTierSectionState extends State<DoctorPriceTierSection> {
  List<PriceTierModel> _tiers = const [];

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    final result = await getIt<PriceTiersRepo>().getPriceTiers();
    if (!mounted) return;

    // A failure here is not worth an error screen: the current tier still
    // reads, and only the picker is poorer for it.
    result.fold((_) {}, (tiers) {
      setState(() {
        _tiers = [
          for (final tier in tiers)
            if (tier.isActive) tier,
        ];
      });
    });
  }

  Future<void> _pick() async {
    final chosen = await showGlassBottomSheet<_TierChoice>(
      context: context,
      builder: (sheetContext) =>
          _TierPicker(tiers: _tiers, selectedId: widget.doctor.priceTierId),
    );
    if (chosen == null) return;

    widget.onChanged(chosen.tierId);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.finance);
    final name = widget.doctor.priceTierName?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSectionTitle(
          'الشريحة السعرية',
          trailing: TextButton.icon(
            onPressed: () =>
                showPriceTierHistorySheet(context, doctorId: widget.doctor.id),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('السجل'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: glass.surfaceColor,
            border: Border.all(color: glass.strokeColor),
            borderRadius: BorderRadius.circular(AppRadius.glass),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name.isEmpty ? 'بلا شريحة' : name,
                      style: AppTextStyles.font14RegularSecondary.copyWith(
                        color: name.isEmpty ? glass.warning : glass.onGlass,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // "No tier" is not a cheap tier — nothing prices this
                      // doctor's cases at all, which is worth saying plainly
                      // rather than showing an empty field.
                      name.isEmpty
                          ? 'لا تُسعَّر حالات هذا الطبيب حتى تُسنَد له شريحة'
                          : _sinceLabel(widget.doctor.priceTierSince),
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                TextButton(
                  onPressed: widget.isBusy ? null : _pick,
                  child: Text(name.isEmpty ? 'إسناد' : 'تغيير'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _sinceLabel(String? since) {
    final text = since?.trim();
    if (text == null || text.isEmpty) return '';
    // The date part only: the exact minute a tier changed is noise.
    final date = DateTime.tryParse(text);
    if (date == null) return text;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'منذ ${date.year}-$month-$day';
  }
}

/// A chosen tier, or the explicit "no tier" answer.
///
/// A plain nullable return could not tell "the user picked none" from "the
/// user dismissed the sheet", and those must not do the same thing.
class _TierChoice {
  const _TierChoice(this.tierId);

  final String? tierId;
}

class _TierPicker extends StatelessWidget {
  const _TierPicker({required this.tiers, required this.selectedId});

  final List<PriceTierModel> tiers;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختيار الشريحة السعرية',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (tiers.isEmpty)
            Text(
              'لا توجد شرائح سعرية مفعّلة',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final tier in tiers)
                    ListTile(
                      onTap: () =>
                          Navigator.of(context).pop(_TierChoice(tier.id)),
                      contentPadding: EdgeInsets.zero,
                      trailing: selectedId == tier.id
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      title: Text(
                        tier.name ?? '—',
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                      subtitle: Text(
                        '${tier.pricedRestorationCount}/'
                        '${tier.totalRestorationTypeCount} مسعّرة',
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.sm),
          // The way off a tier. Without it a doctor once assigned could only
          // ever be moved to another tier, never back to none.
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _TierChoice(null)),
            child: const Text('بلا شريحة'),
          ),
        ],
      ),
    );
  }
}
