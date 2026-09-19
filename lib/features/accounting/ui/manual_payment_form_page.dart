import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/invoice_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:dental_lab_app/features/accounting/logic/manual_payment/manual_payment_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/manual_payment/manual_payment_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Records a manual payment against one of a doctor's invoices
/// (`POST /Accounting/payments/manual`) — a payment a doctor paid in person
/// or transferred outside the app, with an optional receipt photo as proof.
///
/// [initialDoctorId]/[initialInvoiceId] pre-select both pickers when opened
/// from an invoice's own detail screen; opened from the payments list they
/// start empty and the doctor has to be chosen first.
class ManualPaymentFormPage extends StatelessWidget {
  const ManualPaymentFormPage({
    super.key,
    this.initialDoctorId,
    this.initialDoctorName,
    this.initialInvoiceId,
  });

  final String? initialDoctorId;
  final String? initialDoctorName;
  final String? initialInvoiceId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ManualPaymentCubit>()),
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
      ],
      child: _ManualPaymentView(
        initialDoctorId: initialDoctorId,
        initialDoctorName: initialDoctorName,
        initialInvoiceId: initialInvoiceId,
      ),
    );
  }
}

class _ManualPaymentView extends StatefulWidget {
  const _ManualPaymentView({
    this.initialDoctorId,
    this.initialDoctorName,
    this.initialInvoiceId,
  });

  final String? initialDoctorId;
  final String? initialDoctorName;
  final String? initialInvoiceId;

  @override
  State<_ManualPaymentView> createState() => _ManualPaymentViewState();
}

class _ManualPaymentViewState extends State<_ManualPaymentView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String? _doctorId = widget.initialDoctorId;
  String? _invoiceId;
  PaymentMethod _method = PaymentMethod.cash;
  String? _receiptPath;
  String? _receiptName;

  @override
  void initState() {
    super.initState();
    final doctorId = widget.initialDoctorId;
    if (doctorId != null) {
      context.read<ManualPaymentCubit>().loadInvoicesForDoctor(doctorId);
      _invoiceId = widget.initialInvoiceId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onDoctorChanged(String? doctorId) {
    setState(() {
      _doctorId = doctorId;
      _invoiceId = null;
    });
    if (doctorId != null) {
      context.read<ManualPaymentCubit>().loadInvoicesForDoctor(doctorId);
    }
  }

  void _onInvoiceChanged(String? invoiceId, List<InvoiceModel> invoices) {
    setState(() {
      _invoiceId = invoiceId;
      final invoice = invoices.where((i) => i.id == invoiceId).firstOrNull;
      if (invoice != null && _amountController.text.trim().isEmpty) {
        _amountController.text = invoice.remainingAmount.toStringAsFixed(2);
      }
    });
  }

  Future<void> _pickReceipt() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      final file = result?.files.single;
      if (file?.path == null) return;
      setState(() {
        _receiptPath = file!.path;
        _receiptName = file.name;
      });
    } catch (e) {
      showToast(
        message: 'تعذّر فتح منتقي الملفات: $e',
        state: ToastState.error,
      );
    }
  }

  void _removeReceipt() {
    setState(() {
      _receiptPath = null;
      _receiptName = null;
    });
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final doctorId = _doctorId;
    final invoiceId = _invoiceId;
    if (doctorId == null) {
      showToast(message: 'اختر الطبيب', state: ToastState.error);
      return;
    }
    if (invoiceId == null) {
      showToast(message: 'اختر الفاتورة', state: ToastState.error);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    context.read<ManualPaymentCubit>().submit(
      invoiceId: invoiceId,
      doctorId: doctorId,
      amount: amount,
      method: _method,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      receiptFilePath: _receiptPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'تسجيل دفعة',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ManualPaymentCubit, ManualPaymentState>(
          listener: (context, state) {
            switch (state) {
              case ManualPaymentSuccess(:final payment):
                showToast(
                  message: 'تم تسجيل الدفعة',
                  state: ToastState.success,
                );
                Navigator.of(context).pop(payment);
              case ManualPaymentError(:final message):
                showToast(message: message, state: ToastState.error);
              case ManualPaymentInvoicesError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            final invoices = switch (state) {
              ManualPaymentInvoicesLoaded(:final invoices) => invoices,
              _ => const <InvoiceModel>[],
            };
            final invoicesLoading = state is ManualPaymentInvoicesLoading;
            final isSubmitting = state is ManualPaymentSubmitting;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    AdaptiveLayout.formFactorFor(constraints.maxWidth) !=
                    AdaptiveFormFactor.mobile;
                final contentWidth = isWide ? 560.0 : constraints.maxWidth;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'الطبيب',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<DoctorsCubit, DoctorsState>(
                              builder: (context, doctorsState) {
                                final doctors = doctorsState is DoctorsLoaded
                                    ? doctorsState.doctors
                                    : null;
                                return CaseLookupDropdown(
                                  value: _doctorId,
                                  icon: Icons.medical_services_outlined,
                                  hintText: doctorsState is DoctorsLoading
                                      ? 'جارٍ تحميل الأطباء...'
                                      : 'اختر الطبيب',
                                  items: doctors
                                      ?.map(
                                        (d) => DropdownMenuItem(
                                          value: d.id,
                                          child: Text(d.fullName),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: isSubmitting
                                      ? (_) {}
                                      : _onDoctorChanged,
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'الفاتورة',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            CaseLookupDropdown(
                              value: _invoiceId,
                              icon: Icons.receipt_long_outlined,
                              hintText: _doctorId == null
                                  ? 'اختر الطبيب أولاً'
                                  : invoicesLoading
                                  ? 'جارٍ تحميل الفواتير...'
                                  : 'اختر الفاتورة',
                              items: _doctorId == null || invoicesLoading
                                  ? null
                                  : invoices
                                        .map(
                                          (i) => DropdownMenuItem(
                                            value: i.id,
                                            child: Text(
                                              '${i.invoiceNumber ?? '—'} '
                                              '(${i.currency == null ? i.remainingAmount.toStringAsFixed(2) : i.currency!.format(i.remainingAmount)})',
                                            ),
                                          ),
                                        )
                                        .toList(),
                              onChanged: isSubmitting
                                  ? (_) {}
                                  : (id) => _onInvoiceChanged(id, invoices),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'المبلغ',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _amountController,
                              hintText: 'أدخل المبلغ المدفوع',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              enabled: !isSubmitting,
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (value) {
                                final amount = double.tryParse(
                                  value?.trim() ?? '',
                                );
                                if (amount == null || amount <= 0) {
                                  return 'أدخل مبلغاً صحيحاً';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'طريقة الدفع',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final method in PaymentMethod.values)
                                  ChoiceChip(
                                    label: Text(method.label),
                                    selected: _method == method,
                                    onSelected: isSubmitting
                                        ? null
                                        : (_) =>
                                              setState(() => _method = method),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'ملاحظات (اختياري)',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _notesController,
                              hintText: 'أدخل ملاحظة',
                              maxLines: 3,
                              enabled: !isSubmitting,
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'صورة الإيصال (اختياري)',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            _ReceiptField(
                              fileName: _receiptName,
                              onPick: isSubmitting ? null : _pickReceipt,
                              onRemove: isSubmitting ? null : _removeReceipt,
                            ),
                            const SizedBox(height: 24),
                            if (isSubmitting)
                              const Center(
                                child: CustomCircleProgressIndiacatorWidget(),
                              )
                            else
                              CustomButtonWidget(
                                onPressed: _onSubmit,
                                buttonText: 'تسجيل الدفعة',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReceiptField extends StatelessWidget {
  const _ReceiptField({this.fileName, this.onPick, this.onRemove});

  final String? fileName;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: fileName == null
          ? InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(AppRadius.glass),
              child: Row(
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 18,
                    color: glass.onGlassMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إرفاق صورة الإيصال',
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Icon(Icons.image_outlined, size: 18, color: glass.onGlassMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة الصورة',
                  onPressed: onRemove,
                  icon: Icon(Icons.close, size: 18, color: glass.error),
                ),
              ],
            ),
    );
  }
}
