import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:flutter/material.dart';

/// One payslip, broken out.
///
/// Read-only on purpose: every figure is the server's arithmetic over the
/// period's attendance, and the way to change one is to fix the day behind it
/// and regenerate — not to edit the total.
Future<void> showSalaryStatementSheet(
  BuildContext context, {
  required SalaryStatementModel statement,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _SalaryStatementSheet(statement: statement),
  );
}

class _SalaryStatementSheet extends StatelessWidget {
  const _SalaryStatementSheet({required this.statement});

  final SalaryStatementModel statement;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            statement.employeeName ?? '—',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          Text(
            [
              statement.periodLabel,
              if (statement.payType != null) statement.payType!.label,
              statement.status?.label ?? '—',
            ].join(' · '),
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          _Line(
            label: 'الأساسي',
            value: statement.format(statement.grossAmount),
            color: glass.onGlass,
          ),

          const SizedBox(height: AppSpacing.md),
          const _GroupLabel('ما رُصد خلال الفترة'),
          _Line(
            label: 'أيام الغياب',
            value: '${statement.absentDays}',
            color: glass.onGlassMuted,
          ),
          _Line(
            label: 'دقائق التأخير',
            value: '${statement.delayMinutesTotal}',
            color: glass.onGlassMuted,
          ),
          _Line(
            label: 'دقائق الخروج المبكر',
            value: '${statement.earlyLeaveMinutesTotal}',
            color: glass.onGlassMuted,
          ),
          _Line(
            label: 'دقائق الانقطاع',
            value: '${statement.gapMinutesTotal}',
            color: glass.onGlassMuted,
          ),
          _Line(
            label: 'دقائق العمل الإضافي',
            value: '${statement.overtimeMinutesTotal}',
            color: glass.onGlassMuted,
          ),

          const SizedBox(height: AppSpacing.md),
          const _GroupLabel('الخصومات والإضافات'),
          _Line(
            label: 'خصم الغياب',
            value: statement.format(statement.absentDeduction),
            color: glass.error,
          ),
          _Line(
            label: 'خصم التأخير',
            value: statement.format(statement.delayDeduction),
            color: glass.error,
          ),
          _Line(
            label: 'خصم الخروج المبكر',
            value: statement.format(statement.earlyLeaveDeduction),
            color: glass.error,
          ),
          _Line(
            label: 'خصم الانقطاع',
            value: statement.format(statement.gapDeduction),
            color: glass.error,
          ),
          _Line(
            label: 'أجر العمل الإضافي',
            value: statement.format(statement.overtimePay),
            color: glass.success,
          ),
          if (statement.exceptionAdjustmentTotal != 0)
            _Line(
              // One net figure: an increase and a cut in the same period
              // cancel out, and the server reports what is left.
              label: 'صافي استثناءات الراتب',
              value: statement.format(statement.exceptionAdjustmentTotal),
              color: statement.exceptionAdjustmentTotal < 0
                  ? glass.error
                  : glass.success,
            ),

          const Divider(height: 24),
          _Line(
            label: 'الصافي',
            value: statement.format(statement.netAmount),
            color: glass.onGlass,
            emphasize: true,
          ),

          if (statement.notes?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              statement.notes!,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],

          if (statement.isDraft) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              // A draft is still downstream of its attendance: correcting a
              // punch inside the period changes these numbers, but only once
              // payroll is generated again.
              'مسودة — أي تعديل على حضور الفترة يتطلب إعادة توليد الكشف',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? AppTextStyles.font16MediumText
        : AppTextStyles.font14RegularSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: context.glass.onGlassMuted,
              ),
            ),
          ),
          Text(value, style: style.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.font14MediumText.copyWith(
          color: context.glass.onGlass,
        ),
      ),
    );
  }
}
