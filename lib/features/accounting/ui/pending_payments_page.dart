import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/accounting/logic/pending_payments/pending_payments_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/pending_payments/pending_payments_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Payments a doctor submitted proof for, waiting on the lab to confirm the
/// money actually arrived (`GET /Accounting/payments/pending`).
class PendingPaymentsPage extends StatelessWidget {
  const PendingPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PendingPaymentsCubit>()..getPendingPayments(),
      child: const _PendingPaymentsView(),
    );
  }
}

class _PendingPaymentsView extends StatelessWidget {
  const _PendingPaymentsView();

  Future<void> _decide(
    BuildContext context,
    PaymentModel payment,
    bool approve,
  ) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => _VerifyDialog(approve: approve),
    );
    // Cancelled — the dialog pops null only when the user backs out, never
    // on confirm (confirm always pops at least an empty string).
    if (notes == null || !context.mounted) return;

    await context.read<PendingPaymentsCubit>().verify(
      id: payment.id,
      approve: approve,
      notes: notes.isEmpty ? null : notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.pendingPaymentsScreen),
      appBar: GlassAppBar(
        title: Text(
          'دفعات بانتظار التحقق',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<PendingPaymentsCubit, PendingPaymentsState>(
          listener: (context, state) {
            if (state is PendingPaymentsActionError) {
              showToast(message: state.message, state: ToastState.error);
            }
          },
          buildWhen: (_, current) => current is! PendingPaymentsActionError,
          builder: (context, state) {
            return switch (state) {
              PendingPaymentsLoaded(:final payments) =>
                payments.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<PaymentModel>(
                        items: payments,
                        cardHeight: 148,
                        onRefresh: () => context
                            .read<PendingPaymentsCubit>()
                            .getPendingPayments(),
                        itemBuilder: (context, payment, _) =>
                            _PendingPaymentCard(
                              payment: payment,
                              onApprove: () => _decide(context, payment, true),
                              onReject: () => _decide(context, payment, false),
                            ),
                      ),
              PendingPaymentsError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            };
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: glass.surfaceGradient,
                border: Border.all(color: glass.strokeColor),
              ),
              child: Icon(
                Icons.task_alt_outlined,
                size: 40,
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا يوجد دفعات بانتظار التحقق',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  const _PendingPaymentCard({
    required this.payment,
    required this.onApprove,
    required this.onReject,
  });

  final PaymentModel payment;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: radius,
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payment.doctorName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              Text(
                payment.currency == null
                    ? payment.amount.toStringAsFixed(2)
                    : payment.currency!.format(payment.amount),
                style: AppTextStyles.font16MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            payment.method?.label ?? '—',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          if (payment.notes?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              payment.notes!,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(foregroundColor: glass.error),
                  child: const Text('رفض'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(backgroundColor: glass.success),
                  child: const Text('اعتماد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerifyDialog extends StatefulWidget {
  const _VerifyDialog({required this.approve});

  final bool approve;

  @override
  State<_VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<_VerifyDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.approve ? 'اعتماد الدفعة' : 'رفض الدفعة',
        style: AppTextStyles.font18MediumText,
      ),
      content: AppTextFormField(
        controller: _notesController,
        hintText: 'ملاحظة (اختياري)',
        maxLines: 3,
        validator: (_) => null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        CustomButtonWidget(
          onPressed: () =>
              Navigator.of(context).pop(_notesController.text.trim()),
          buttonText: widget.approve ? 'اعتماد' : 'رفض',
        ),
      ],
    );
  }
}
