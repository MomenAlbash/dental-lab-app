import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// One invoice's full detail — read-only (no manual invoice editing yet, see
/// the accounting overview screen for what else the API already supports).
class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late final Future<InvoiceModel?> _future = _load();

  Future<InvoiceModel?> _load() async {
    final result = await getIt<AccountingRepo>().getInvoiceById(
      widget.invoiceId,
    );
    return result.fold((failure) {
      _error = failure.errorMessage;
      return null;
    }, (invoice) => invoice);
  }

  String? _error;
  bool _downloadingPdf = false;

  Future<void> _openPdf(InvoiceModel invoice) async {
    setState(() => _downloadingPdf = true);

    final result = await getIt<AccountingRepo>().downloadInvoicePdf(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber ?? invoice.id,
    );

    if (!mounted) return;
    setState(() => _downloadingPdf = false);

    await result.fold(
      (failure) async =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      // A raw file:// launch crashes on Android 7+ without a FileProvider —
      // the share sheet is the same safe hand-off already used for the
      // barcode image (see core/helper/barcode_sharing.dart), and lets the
      // user pick a PDF viewer to open it in, or save it.
      (path) async {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'فاتورة ${invoice.invoiceNumber ?? ''}',
          ),
        );
      },
    );
  }

  /// Deletes the invoice outright.
  ///
  /// Three server-side rules gate this — admin only, within five minutes of
  /// issue, and only while nothing has been paid against it — so the button is
  /// offered to an admin whatever `canDelete` says (that flag ignores who is
  /// asking, and the admin bypass is applied at deletion) and disabled with
  /// the server's own reason for everyone else.
  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الفاتورة',
      message:
          'سيُحذف رقم الفاتورة ${invoice.invoiceNumber ?? ''} نهائياً. '
          'لا يمكن التراجع.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final result = await getIt<AccountingRepo>().deleteInvoice(invoice.id);
    if (!mounted) return;

    result.fold(
      (failure) =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (_) {
        showToast(message: 'تم حذف الفاتورة', state: ToastState.success);
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isAdmin = getIt<SessionCubit>().state.isAdmin;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'الفاتورة',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          FutureBuilder<InvoiceModel?>(
            future: _future,
            builder: (context, snapshot) {
              final loadedInvoice = snapshot.data;
              // Not an admin: the action is not theirs at all, and a disabled
              // button here would only advertise a door they cannot open.
              if (loadedInvoice == null || !isAdmin) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: loadedInvoice.canDelete
                    ? 'حذف الفاتورة'
                    : (loadedInvoice.deleteMessage ??
                          'يمكن الحذف خلال 5 دقائق من الإصدار وقبل أي سداد'),
                icon: Icon(Icons.delete_outline, color: glass.error),
                onPressed: () => _deleteInvoice(loadedInvoice),
              );
            },
          ),
          FutureBuilder<InvoiceModel?>(
            future: _future,
            builder: (context, snapshot) {
              final loadedInvoice = snapshot.data;
              if (loadedInvoice == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'عرض PDF',
                icon: _downloadingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                onPressed: _downloadingPdf
                    ? null
                    : () => _openPdf(loadedInvoice),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<InvoiceModel?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CustomCircleProgressIndiacatorWidget(),
              );
            }

            final invoice = snapshot.data;
            if (invoice == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error ?? 'تعذّر تحميل الفاتورة',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              );
            }

            return _InvoiceBody(invoice: invoice);
          },
        ),
      ),
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({required this.invoice});

  final InvoiceModel invoice;

  Future<void> _recordPayment(BuildContext context) async {
    final saved = await context.push<PaymentModel>(
      Routes.manualPaymentFormScreen,
      extra: (
        doctorId: invoice.doctorId,
        doctorName: invoice.doctorName,
        invoiceId: invoice.id,
      ),
    );
    // The numbers on this screen would otherwise go stale (paidAmount is not
    // re-fetched here) — popping back to the invoices list is simpler than
    // threading a refresh callback through for a screen the user is about to
    // leave anyway.
    if (saved != null && context.mounted) Navigator.of(context).pop();
  }

  String _amount(double value) => invoice.currency == null
      ? value.toStringAsFixed(2)
      : invoice.currency!.format(value);

  String _date(DateTime? date) {
    if (date == null) return '—';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.glass),
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
                      invoice.invoiceNumber ?? '—',
                      style: AppTextStyles.font18MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ),
                  Text(
                    invoice.status?.label ?? '—',
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                invoice.doctorName ?? '—',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              if (invoice.caseNumber != null) ...[
                const SizedBox(height: 2),
                InkWell(
                  onTap: invoice.caseId == null
                      ? null
                      : () => context.push(
                          Routes.caseDetailScreen,
                          extra: invoice.caseId,
                        ),
                  child: Text(
                    'الحالة: ${invoice.caseNumber}',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (invoice.status != InvoiceStatus.paid &&
            invoice.status != InvoiceStatus.cancelled &&
            getIt<SessionCubit>().state.canEdit(PermissionName.finance)) ...[
          const SizedBox(height: AppSpacing.md),
          CustomButtonWidget(
            onPressed: () => _recordPayment(context),
            buttonText: 'تسجيل دفعة',
          ),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        const GlassSectionTitle('التفاصيل'),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            border: Border.all(color: glass.strokeColor),
            boxShadow: glass.shadows,
          ),
          child: Column(
            children: [
              _row(context, 'تاريخ الإصدار', _date(invoice.issuedAt)),
              _row(context, 'تاريخ الاستحقاق', _date(invoice.dueDate)),
              _row(context, 'المجموع الفرعي', _amount(invoice.subtotalAmount)),
              if (invoice.discountValue > 0)
                _row(context, 'الخصم', _amount(invoice.discountValue)),
              if (invoice.discountPercentage > 0)
                _row(
                  context,
                  'نسبة الخصم',
                  '${invoice.discountPercentage.toStringAsFixed(0)}%',
                ),
              _row(context, 'الإجمالي', _amount(invoice.totalAmount)),
              _row(context, 'المدفوع', _amount(invoice.paidAmount)),
              _row(
                context,
                'المتبقي',
                _amount(invoice.remainingAmount),
                valueColor: invoice.remainingAmount > 0 ? glass.warning : null,
              ),
            ],
          ),
        ),
        if (invoice.lines.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          const GlassSectionTitle('البنود'),
          const SizedBox(height: AppSpacing.sm),
          for (final line in invoice.lines)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: glass.surfaceGradient,
                borderRadius: BorderRadius.circular(AppRadius.glass),
                border: Border.all(color: glass.strokeColor),
                boxShadow: glass.shadows,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.description ?? '—',
                          style: AppTextStyles.font14MediumText.copyWith(
                            color: glass.onGlass,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${line.quantity} × ${_amount(line.unitPrice)}',
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _amount(line.total),
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.font14MediumText.copyWith(
              color: valueColor ?? glass.onGlass,
            ),
          ),
        ],
      ),
    );
  }
}
