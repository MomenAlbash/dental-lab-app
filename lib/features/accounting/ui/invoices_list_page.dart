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
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/logic/invoices/invoices_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/invoices/invoices_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The lab's invoices (`GET /Accounting/invoices`) — every doctor, every
/// case that was billed.
class InvoicesListPage extends StatelessWidget {
  const InvoicesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InvoicesCubit>()..getInvoices(),
      child: const _InvoicesListView(),
    );
  }
}

class _InvoicesListView extends StatelessWidget {
  const _InvoicesListView();

  Future<void> _openForm(BuildContext context) async {
    final result = await context.push<InvoiceModel>(Routes.invoiceFormScreen);
    if (result != null && context.mounted) {
      context.read<InvoicesCubit>().getInvoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.finance);

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.invoicesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الفواتير',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'فاتورة جديدة',
              isExtended: true,
              onPressed: () => _openForm(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocBuilder<InvoicesCubit, InvoicesState>(
          builder: (context, state) {
            return switch (state) {
              InvoicesLoaded(:final invoices) =>
                invoices.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<InvoiceModel>(
                        items: invoices,
                        cardHeight: 108,
                        onRefresh: () =>
                            context.read<InvoicesCubit>().getInvoices(),
                        itemBuilder: (context, invoice, _) => _InvoiceListItem(
                          invoice: invoice,
                          onTap: () => context.push(
                            Routes.invoiceDetailScreen,
                            extra: invoice.id,
                          ),
                        ),
                      ),
              InvoicesError(:final message) => Center(
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
                Icons.receipt_long_outlined,
                size: 40,
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد فواتير بعد',
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

class _InvoiceListItem extends StatelessWidget {
  const _InvoiceListItem({required this.invoice, required this.onTap});

  final InvoiceModel invoice;
  final VoidCallback onTap;

  Color _statusColor(GlassTokens glass) => switch (invoice.status) {
    InvoiceStatus.paid => glass.success,
    InvoiceStatus.partiallyPaid => glass.warning,
    InvoiceStatus.cancelled => glass.onGlassMuted,
    InvoiceStatus.unpaid || null => glass.error,
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
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
                                    invoice.invoiceNumber ?? '—',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font16MediumText
                                        .copyWith(color: glass.onGlass),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    invoice.doctorName ?? '—',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: glass.onGlassMuted),
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
                                  invoice.currency == null
                                      ? invoice.totalAmount.toStringAsFixed(2)
                                      : invoice.currency!.format(
                                          invoice.totalAmount,
                                        ),
                                  style: AppTextStyles.font14MediumText
                                      .copyWith(color: glass.onGlass),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  invoice.status?.label ?? '—',
                                  style: AppTextStyles.font12RegularHint
                                      .copyWith(color: statusColor),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
