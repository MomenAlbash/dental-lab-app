import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/send_back_models.dart';
import 'package:dental_lab_app/features/cases/logic/breakage_loss/breakage_loss_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Why a piece goes back — and, for a breakage, who is responsible and what
/// it does to their pay.
///
/// Shared by every send-back: a move back mid-production and each refused
/// piece of a trying ask the same question, so they answer it with the same
/// fields. The loss preview is fetched for [targetStageId]; picking another
/// target refetches it.
class SendBackReasonFields extends StatefulWidget {
  const SendBackReasonFields({
    super.key,
    required this.caseId,
    required this.restorationId,
    required this.targetStageId,
    required this.value,
    required this.onChanged,
  });

  final String caseId;
  final String restorationId;
  final String targetStageId;
  final SendBackReason value;
  final ValueChanged<SendBackReason> onChanged;

  @override
  State<SendBackReasonFields> createState() => _SendBackReasonFieldsState();
}

class _SendBackReasonFieldsState extends State<SendBackReasonFields> {
  final _amountController = TextEditingController();

  /// Whether the amount was typed by hand. Until it is, it follows the lost
  /// work's value as each preview arrives.
  bool _amountTouched = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  BreakageLossDraft get _loss => widget.value.loss ?? const BreakageLossDraft();

  void _setLoss(BreakageLossDraft loss) => widget.onChanged(
    SendBackReason(category: widget.value.category, loss: loss),
  );

  void _setCategory(FailureReasonCategory? category) => widget.onChanged(
    SendBackReason(
      category: category,
      loss: (category?.carriesLoss ?? false) ? _loss : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final category = widget.value.category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'سبب الإرجاع',
          style: AppTextStyles.font14MediumText.copyWith(color: glass.onGlass),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in FailureReasonCategory.values)
              ChoiceChip(
                label: Text(option.label),
                selected: category == option,
                // Tapping the chosen one again clears it — the reason is
                // optional.
                onSelected: (on) => _setCategory(on ? option : null),
              ),
          ],
        ),
        if (category?.carriesLoss ?? false) ...[
          const SizedBox(height: AppSpacing.md),
          BlocProvider(
            key: ValueKey(widget.targetStageId),
            create: (_) => getIt<BreakageLossCubit>()
              ..load(
                caseId: widget.caseId,
                restorationId: widget.restorationId,
                targetStageId: widget.targetStageId,
              ),
            child: BlocConsumer<BreakageLossCubit, BreakageLossState>(
              listener: (context, state) {
                // Suggest the lost work's value as the deduction until the
                // user types their own figure.
                final value = switch (state) {
                  BreakageLossReady(:final preview) => preview?.lostWorkValue,
                  _ => null,
                };
                if (value != null && !_amountTouched) {
                  _amountController.text = value.toStringAsFixed(2);
                  _setLoss(_loss.copyWith(deductionAmount: value));
                }
              },
              builder: (context, state) => switch (state) {
                BreakageLossReady() => _LossFields(
                  state: state,
                  loss: _loss,
                  amountController: _amountController,
                  onChanged: _setLoss,
                  onAmountTyped: (amount) {
                    _amountTouched = true;
                    _setLoss(_loss.copyWith(deductionAmount: amount));
                  },
                ),
                BreakageLossLoading() => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: LinearProgressIndicator(),
                ),
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _LossFields extends StatelessWidget {
  const _LossFields({
    required this.state,
    required this.loss,
    required this.amountController,
    required this.onChanged,
    required this.onAmountTyped,
  });

  final BreakageLossReady state;
  final BreakageLossDraft loss;
  final TextEditingController amountController;
  final ValueChanged<BreakageLossDraft> onChanged;
  final ValueChanged<double> onAmountTyped;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final preview = state.preview;
    final employees = state.orderedEmployees;
    final problem = loss.problem;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            preview == null
                ? 'تعذّر حساب قيمة العمل الضائع'
                : 'قيمة العمل الضائع: ${preview.lostWorkValue.toStringAsFixed(2)}',
            style: AppTextStyles.font14MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          for (final row in preview?.lostEarnings ?? const [])
            Text(
              '${row.employeeName ?? '—'} · ${row.stageDisplayName} · '
              '${row.amount.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: employees.any((e) => e.id == loss.responsibleEmployeeId)
                ? loss.responsibleEmployeeId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'المسؤول عن الكسر',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(child: Text('غير محدد')),
              for (final employee in employees)
                DropdownMenuItem<String?>(
                  value: employee.id,
                  child: Text(
                    employee.fullName.isEmpty ? '—' : employee.fullName,
                  ),
                ),
            ],
            onChanged: (id) => onChanged(
              id == null
                  ? loss.copyWith(clearResponsible: true)
                  : loss.copyWith(responsibleEmployeeId: id),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'أثره على الأجر',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlass,
            ),
          ),
          for (final impact in LossPayImpact.values)
            _ImpactOption(
              impact: impact,
              isSelected: loss.payImpact == impact,
              onTap: () => onChanged(loss.copyWith(payImpact: impact)),
            ),
          if (loss.payImpact == LossPayImpact.deductAmount) ...[
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              controller: amountController,
              hintText: 'مبلغ الخصم',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (text) =>
                  onAmountTyped(double.tryParse(text.trim()) ?? 0),
              validator: (_) => null,
            ),
          ],
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                problem,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImpactOption extends StatelessWidget {
  const _ImpactOption({
    required this.impact,
    required this.isSelected,
    required this.onTap,
  });

  final LossPayImpact impact;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? accent : context.glass.onGlassMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                impact.label,
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: context.glass.onGlass,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
