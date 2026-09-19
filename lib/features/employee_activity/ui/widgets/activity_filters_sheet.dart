import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:flutter/material.dart';

/// The window and the event kinds the report covers.
///
/// All three tabs read these same filters — a summary covering a different
/// window from the timeline under it is how a report stops being evidence.
Future<EmployeeActivityFiltersModel?> showActivityFiltersSheet(
  BuildContext context, {
  required EmployeeActivityFiltersModel initial,
}) {
  return showGlassBottomSheet<EmployeeActivityFiltersModel>(
    context: context,
    builder: (_) => _FiltersSheet(initial: initial),
  );
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});

  final EmployeeActivityFiltersModel initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late DateTime? _from = widget.initial.from;
  late DateTime? _to = widget.initial.to;
  late final Set<ActivityKind> _kinds = {...widget.initial.kinds};
  late bool _includeReturns = widget.initial.includeReturns;
  late bool _includeRejected = widget.initial.includeRejected;

  late final _caseController = TextEditingController(
    text: widget.initial.caseNumber ?? '',
  );

  @override
  void dispose() {
    _caseController.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _from = picked;
        // A window that ends before it starts returns nothing, and an empty
        // report reads as "no activity" rather than as a bad date.
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(picked)) _from = picked;
      }
    });
  }

  void _apply() {
    final caseNumber = _caseController.text.trim();

    Navigator.of(context).pop(
      widget.initial.copyWith(
        from: _from,
        to: _to,
        kinds: _kinds.toList(),
        caseNumber: caseNumber,
        includeReturns: _includeReturns,
        includeRejected: _includeRejected,
        page: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'فلاتر التقرير',
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(isFrom: true),
                    icon: const Icon(Icons.event, size: 16),
                    label: Text(
                      _from == null ? 'من' : ApiTime.formatDate(_from!),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(isFrom: false),
                    icon: const Icon(Icons.event, size: 16),
                    label: Text(_to == null ? 'إلى' : ApiTime.formatDate(_to!)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            Text(
              'نوع الحدث',
              style: AppTextStyles.font14MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            Text(
              // Said because an empty selection reading as "none" would be the
              // opposite of what it does.
              'بلا اختيار = كل الأنواع',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final kind in ActivityKind.values)
                  FilterChip(
                    label: Text(kind.label),
                    selected: _kinds.contains(kind),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _kinds.add(kind);
                      } else {
                        _kinds.remove(kind);
                      }
                    }),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            AppTextFormField(
              controller: _caseController,
              hintText: 'رقم الطلب (اختياري)',
              validator: (_) => null,
            ),

            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeReturns,
              onChanged: (value) => setState(() => _includeReturns = value),
              title: Text(
                'تضمين المرتجعات',
                style: AppTextStyles.font14MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              subtitle: Text(
                // Warned about, because this is the switch that can make a bad
                // week look like a good one.
                _includeReturns
                    ? 'مشمولة — التقرير بيبيّن إعادة العمل'
                    : 'مستثناة — التقرير رح يبيّن أحسن من الواقع',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: _includeReturns ? glass.onGlassMuted : glass.warning,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeRejected,
              onChanged: (value) => setState(() => _includeRejected = value),
              title: Text(
                'تضمين المرفوضة',
                style: AppTextStyles.font14MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            CustomButtonWidget(buttonText: 'تطبيق', onPressed: _apply),
          ],
        ),
      ),
    );
  }
}
