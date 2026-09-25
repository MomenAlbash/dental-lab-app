import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_card.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_save_bar.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_rates/stage_rates_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_rates/stage_rates_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The price of each production stage, per restoration type.
///
/// A form, not a card collection: every row is an input, so it stays capped
/// and centred on a tablet rather than spreading into a grid of text fields.
class StageRatesTab extends StatelessWidget {
  const StageRatesTab({super.key, required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocConsumer<StageRatesCubit, StageRatesState>(
      listenWhen: (_, current) =>
          current is StageRatesSaved || current is StageRatesSaveError,
      listener: (context, state) {
        switch (state) {
          case StageRatesSaved():
            showToast(message: 'تم حفظ الأسعار', state: ToastState.success);
          case StageRatesSaveError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (_, current) =>
          current is! StageRatesSaved && current is! StageRatesSaveError,
      builder: (context, state) => switch (state) {
        StageRatesLoaded() when state.types.isEmpty => _Message(
          'لا توجد أنواع تعويض لها مراحل بعد',
          color: glass.onGlassMuted,
        ),
        StageRatesLoaded() => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<StageRatesCubit>().load(),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          children: [
                            Text(
                              'يُدفع للموظف سعر المرحلة عند إنهائها. '
                              'السعر صفر يعني أن المرحلة بلا أجر.',
                              style: AppTextStyles.font12RegularHint.copyWith(
                                color: glass.onGlassMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            for (final type in state.types)
                              _TypeCard(
                                type: type,
                                state: state,
                                canEdit: canEdit && !state.isSaving,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (canEdit && state.hasChanges)
              Row(
                children: [
                  TextButton(
                    onPressed: state.isSaving
                        ? null
                        : context.read<StageRatesCubit>().discard,
                    child: const Text('تراجع'),
                  ),
                  Expanded(
                    child: GlassSaveBar(
                      isSubmitting: state.isSaving,
                      label: 'حفظ (${state.drafts.length})',
                      onSave: context.read<StageRatesCubit>().save,
                    ),
                  ),
                ],
              ),
          ],
        ),
        StageRatesError(:final message) => _Message(
          message,
          color: glass.onGlassMuted,
        ),
        _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.state,
    required this.canEdit,
  });

  final StagePayRestorationTypeModel type;
  final StageRatesLoaded state;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          type.displayName,
          style: AppTextStyles.font14MediumText.copyWith(color: glass.onGlass),
        ),
        subtitle: Text(
          '${type.pricedCount} من ${type.stages.length} مراحل مسعّرة',
          style: AppTextStyles.font12RegularHint.copyWith(
            color: glass.onGlassMuted,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          if (type.stages.isEmpty)
            Text(
              'لا مراحل لهذا النوع',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          for (final stage in type.stages)
            _StageRateRow(
              key: ValueKey(stage.rootStageId),
              stage: stage,
              price: state.priceOf(stage),
              isEdited: state.drafts.containsKey(stage.rootStageId),
              enabled: canEdit,
            ),
        ],
      ),
    );
  }
}

class _StageRateRow extends StatefulWidget {
  const _StageRateRow({
    super.key,
    required this.stage,
    required this.price,
    required this.isEdited,
    required this.enabled,
  });

  final StagePayRateModel stage;
  final StagePayRateDraft price;
  final bool isEdited;
  final bool enabled;

  @override
  State<_StageRateRow> createState() => _StageRateRowState();
}

class _StageRateRowState extends State<_StageRateRow> {
  late final TextEditingController _amountController = TextEditingController(
    text: _format(widget.price.amount),
  );

  static String _format(double amount) =>
      amount == amount.roundToDouble() ? '${amount.toInt()}' : '$amount';

  @override
  void didUpdateWidget(covariant _StageRateRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follows a price changed from outside the field — a discard, a reload —
    // but never fights the user's own typing, which already matches.
    final typed = double.tryParse(_amountController.text.trim()) ?? 0;
    if (typed != widget.price.amount) {
      _amountController.text = _format(widget.price.amount);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cubit = context.read<StageRatesCubit>();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.stage.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: widget.isEdited
                    ? Theme.of(context).colorScheme.primary
                    : glass.onGlass,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _amountController,
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'السعر',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                final amount = double.tryParse(text.trim());
                // Half-typed or negative input is not a price; it waits.
                if (amount == null && text.trim().isNotEmpty) return;
                if (amount != null && amount < 0) return;
                cubit.edit(widget.stage, amount: amount ?? 0);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<StagePayBasis>(
              // Keyed on the value so a discard resets what it shows —
              // `initialValue` is only read once.
              key: ValueKey(widget.price.basis),
              initialValue: widget.price.basis,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final basis in StagePayBasis.values)
                  DropdownMenuItem(value: basis, child: Text(basis.label)),
              ],
              onChanged: widget.enabled
                  ? (basis) => cubit.edit(widget.stage, basis: basis)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.font14RegularSecondary.copyWith(color: color),
        ),
      ),
    );
  }
}
