import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_price_tier_spell_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:flutter/material.dart';

/// Every stretch of time this doctor spent on a price tier — what explains
/// an old invoice that a "current tier" field alone cannot.
Future<void> showPriceTierHistorySheet(
  BuildContext context, {
  required String doctorId,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _PriceTierHistorySheet(doctorId: doctorId),
  );
}

class _PriceTierHistorySheet extends StatefulWidget {
  const _PriceTierHistorySheet({required this.doctorId});

  final String doctorId;

  @override
  State<_PriceTierHistorySheet> createState() => _PriceTierHistorySheetState();
}

class _PriceTierHistorySheetState extends State<_PriceTierHistorySheet> {
  List<DoctorPriceTierSpellModel>? _spells;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<DoctorsRepo>().getPriceTierHistory(
      widget.doctorId,
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() => _error = failure.errorMessage),
      (spells) => setState(() => _spells = spells),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سجل الشريحة السعرية',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              )
            else if (_spells == null)
              const Column(
                children: [
                  GlassSkeletonBox(height: 64),
                  SizedBox(height: AppSpacing.sm),
                  GlassSkeletonBox(height: 64),
                ],
              )
            else if (_spells!.isEmpty)
              Text(
                'لم يكن هذا الطبيب على أي شريحة سعرية بعد',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _spells!.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _SpellRow(spell: _spells![index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpellRow extends StatelessWidget {
  const _SpellRow({required this.spell});

  final DoctorPriceTierSpellModel spell;

  String get _range {
    final start = _date(spell.startDate);
    // Null end means the spell in force — "since" reads better than a range
    // to nowhere.
    if (spell.endDate == null) return 'منذ $start';
    return '$start – ${_date(spell.endDate)}';
  }

  static String _date(DateTime? date) {
    if (date == null) return '؟';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.surfaceColor,
        border: Border.all(
          color: spell.isActive ? accent : glass.strokeColor,
          width: spell.isActive ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spell.tierLabel,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              if (spell.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'الحالية',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _range,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          if (spell.note?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              spell.note!.trim(),
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
