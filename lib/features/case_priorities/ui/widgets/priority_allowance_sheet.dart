import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:flutter/material.dart';

/// What the sheet decided: the figures to hand out, or a reset.
class PriorityAllowanceResult {
  const PriorityAllowanceResult({this.freePerMonth, this.surchargeAmount});

  /// Both null clears the doctors' overrides and puts them back on the
  /// laboratory default. Null is not zero: zero means "no free cases", which
  /// is a decision, not the absence of one.
  final int? freePerMonth;
  final double? surchargeAmount;

  bool get isReset => freePerMonth == null && surchargeAmount == null;
}

/// Sets one priority's free monthly allowance for a group of doctors.
Future<PriorityAllowanceResult?> showPriorityAllowanceSheet(
  BuildContext context, {
  required CasePriorityModel priority,
  required int doctorCount,
}) {
  return showGlassBottomSheet<PriorityAllowanceResult>(
    context: context,
    builder: (_) =>
        _AllowanceSheet(priority: priority, doctorCount: doctorCount),
  );
}

class _AllowanceSheet extends StatefulWidget {
  const _AllowanceSheet({required this.priority, required this.doctorCount});

  final CasePriorityModel priority;
  final int doctorCount;

  @override
  State<_AllowanceSheet> createState() => _AllowanceSheetState();
}

class _AllowanceSheetState extends State<_AllowanceSheet> {
  final _formKey = GlobalKey<FormState>();

  /// Pre-filled with the laboratory's own default, which is the figure the
  /// user is departing from — starting empty would make them look it up.
  late final _freeController = TextEditingController(
    text: '${widget.priority.freePerMonth}',
  );
  late final _surchargeController = TextEditingController(
    text: widget.priority.surcharge == 0 ? '' : '${widget.priority.surcharge}',
  );

  @override
  void dispose() {
    _freeController.dispose();
    _surchargeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final surchargeText = _surchargeController.text.trim();

    Navigator.of(context).pop(
      PriorityAllowanceResult(
        freePerMonth: int.parse(_freeController.text.trim()),
        surchargeAmount: surchargeText.isEmpty
            ? null
            : double.tryParse(surchargeText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'حصة "${widget.priority.displayName}"',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ستُطبَّق على ${widget.doctorCount} طبيب.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: 20),

              const _Label('عدد الحالات المجانية شهرياً'),
              AppTextFormField(
                controller: _freeController,
                hintText: 'مثال: 5',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.confirmation_number_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (value) {
                  final number = int.tryParse(value?.trim() ?? '');
                  if (number == null) return 'الرجاء إدخال رقم صحيح';
                  if (number < 0) return 'لا يمكن أن يكون بالسالب';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const _Label('الرسم بعد استنفاد الحصة'),
              AppTextFormField(
                controller: _surchargeController,
                hintText: 'اتركه فارغاً لاعتماد رسم المخبر',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icon(
                  Icons.payments_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final number = double.tryParse(text);
                  if (number == null) return 'الرجاء إدخال رقم';
                  if (number < 0) return 'لا يمكن أن يكون بالسالب';
                  return null;
                },
              ),

              const SizedBox(height: 12),
              _Note(
                text:
                    'الافتراضي في المخبر لهذه الأولوية: '
                    '${widget.priority.isUnlimited ? 'بلا حد' : '${widget.priority.freePerMonth} مجاناً شهرياً'}'
                    '. الحصة تُصفَّر مع بداية كل شهر.',
              ),

              const SizedBox(height: 24),
              CustomButtonWidget(buttonText: 'تطبيق', onPressed: _submit),
              const SizedBox(height: 8),
              // The way out of a special arrangement. Without it a doctor put
              // on a custom figure could never be returned to the lab default
              // — only to another custom figure that happens to match it,
              // which reads the same but is not.
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const PriorityAllowanceResult()),
                child: const Text('إلغاء التخصيص والعودة لإعداد المخبر'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppTextStyles.font14RegularSecondary.copyWith(
        color: context.glass.onGlass,
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
