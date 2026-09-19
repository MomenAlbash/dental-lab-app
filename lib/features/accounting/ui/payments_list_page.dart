import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/accounting/logic/payments/payments_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/payments/payments_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The lab's verified/rejected payment history (`GET /Accounting/payments`).
/// Payments still awaiting a decision live on their own screen
/// ([Routes.pendingPaymentsScreen]) since that one carries an action.
class PaymentsListPage extends StatelessWidget {
  const PaymentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentsCubit>()..getPayments(),
      child: const _PaymentsListView(),
    );
  }
}

class _PaymentsListView extends StatelessWidget {
  const _PaymentsListView();

  Future<void> _openManualPaymentForm(BuildContext context) async {
    final saved = await context.push<PaymentModel>(
      Routes.manualPaymentFormScreen,
    );
    if (saved != null && context.mounted) {
      context.read<PaymentsCubit>().getPayments();
    }
  }

  /// Deleting a payment is not a correction — it reopens the invoice it was
  /// against — so it is confirmed, and the confirmation says what it costs.
  Future<void> _confirmDelete(
    BuildContext context,
    PaymentModel payment,
  ) async {
    final cubit = context.read<PaymentsCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الدفعة',
      message:
          'سيُحذف هذا السداد نهائياً وتعود الفاتورة المرتبطة به إلى الاستحقاق.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.deletePayment(payment.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.finance);

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.paymentsListScreen),
      appBar: GlassAppBar(
        title: Text(
          'المدفوعات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'تسجيل دفعة',
              isExtended: true,
              onPressed: () => _openManualPaymentForm(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<PaymentsCubit, PaymentsState>(
          listenWhen: (previous, current) =>
              current is PaymentDeleted || current is PaymentDeleteError,
          listener: (context, state) {
            switch (state) {
              case PaymentDeleted():
                showToast(message: 'تم حذف الدفعة', state: ToastState.success);
              case PaymentDeleteError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! PaymentDeleted && current is! PaymentDeleteError,
          builder: (context, state) {
            return switch (state) {
              PaymentsLoaded(:final payments) =>
                payments.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<PaymentModel>(
                        items: payments,
                        cardHeight: 108,
                        onRefresh: () =>
                            context.read<PaymentsCubit>().getPayments(),
                        itemBuilder: (context, payment, _) => _PaymentListItem(
                          payment: payment,
                          // Hidden outright without `Finance:FullAccess`
                          // rather than shown and refused.
                          onDelete: canEdit
                              ? () => _confirmDelete(context, payment)
                              : null,
                        ),
                      ),
              PaymentsError(:final message) => Center(
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
                Icons.payments_outlined,
                size: 40,
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد دفعات بعد',
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

class _PaymentListItem extends StatelessWidget {
  const _PaymentListItem({required this.payment, this.onDelete});

  final PaymentModel payment;

  /// Null without `Finance:FullAccess` — the row then carries no delete.
  final VoidCallback? onDelete;

  Color _statusColor(GlassTokens glass) => switch (payment.status) {
    PaymentStatus.verified => glass.success,
    PaymentStatus.rejected => glass.error,
    PaymentStatus.pendingVerification || null => glass.warning,
  };

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final statusColor = _statusColor(glass);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                payment.doctorName ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                payment.method?.label ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              payment.currency == null
                                  ? payment.amount.toStringAsFixed(2)
                                  : payment.currency!.format(payment.amount),
                              style: AppTextStyles.font14MediumText.copyWith(
                                color: glass.onGlass,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              payment.status?.label ?? '—',
                              style: AppTextStyles.font12RegularHint.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        if (onDelete != null)
                          IconButton(
                            tooltip: 'حذف الدفعة',
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: glass.error,
                            ),
                            onPressed: onDelete,
                          ),
                      ],
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
