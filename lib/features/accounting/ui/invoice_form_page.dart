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
import 'package:dental_lab_app/features/accounting/data/models/create_invoice_request_model.dart';
import 'package:dental_lab_app/features/accounting/logic/invoice_form/invoice_form_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/invoice_form/invoice_form_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Creates a manual, ad-hoc invoice not tied to a case
/// (`POST /Accounting/invoices`) — a case's own invoice is generated instead
/// from the case detail screen through `POST /Accounting/invoices/from-case/{caseId}`.
class InvoiceFormPage extends StatelessWidget {
  const InvoiceFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InvoiceFormCubit>()..loadCatalog(),
      child: const _InvoiceFormView(),
    );
  }
}

class _InvoiceFormView extends StatefulWidget {
  const _InvoiceFormView();

  @override
  State<_InvoiceFormView> createState() => _InvoiceFormViewState();
}

class _InvoiceFormViewState extends State<_InvoiceFormView> {
  final _discountValueController = TextEditingController();
  final _discountPercentageController = TextEditingController();

  String? _doctorId;
  String? _currencyId;
  DateTime? _dueDate;
  final List<CreateInvoiceLineRequestModel> _lines = [];

  /// The last loaded catalog — kept around so the form stays populated while
  /// [InvoiceFormSubmitting]/[InvoiceFormError] replace [InvoiceFormCatalogLoaded]
  /// in the cubit's state during and after submission.
  InvoiceFormCatalogLoaded? _catalog;

  @override
  void dispose() {
    _discountValueController.dispose();
    _discountPercentageController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  String _isoDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  Future<void> _addLine() async {
    final line = await showDialog<CreateInvoiceLineRequestModel>(
      context: context,
      builder: (_) => const _InvoiceLineFormDialog(),
    );
    if (line == null) return;
    setState(() => _lines.add(line));
  }

  void _removeLine(int index) => setState(() => _lines.removeAt(index));

  void _onSubmit() {
    final doctorId = _doctorId;
    if (doctorId == null) {
      showToast(message: 'اختر الطبيب', state: ToastState.error);
      return;
    }
    if (_lines.isEmpty) {
      showToast(message: 'أضف بنداً واحداً على الأقل', state: ToastState.error);
      return;
    }

    context.read<InvoiceFormCubit>().submit(
      CreateInvoiceRequestModel(
        doctorId: doctorId,
        currencyId: _currencyId,
        dueDate: _dueDate == null ? null : _isoDate(_dueDate!),
        discountValue: double.tryParse(_discountValueController.text.trim()),
        discountPercentage: double.tryParse(
          _discountPercentageController.text.trim(),
        ),
        lines: _lines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'فاتورة جديدة',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<InvoiceFormCubit, InvoiceFormState>(
          listener: (context, state) {
            switch (state) {
              case InvoiceFormSuccess(:final invoice):
                showToast(
                  message: 'تم إنشاء الفاتورة',
                  state: ToastState.success,
                );
                Navigator.of(context).pop(invoice);
              case InvoiceFormError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            if (state is InvoiceFormCatalogLoading ||
                state is InvoiceFormInitial) {
              return const Center(
                child: CustomCircleProgressIndiacatorWidget(),
              );
            }
            if (state is InvoiceFormCatalogError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              );
            }

            if (state is InvoiceFormCatalogLoaded) _catalog = state;
            final doctors = _catalog?.doctors ?? const [];
            final currencies = _catalog?.currencies ?? const [];
            final isSubmitting = state is InvoiceFormSubmitting;

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('الطبيب', style: AppTextStyles.font14MediumText),
                          const SizedBox(height: 8),
                          CaseLookupDropdown(
                            value: _doctorId,
                            icon: Icons.medical_services_outlined,
                            hintText: 'اختر الطبيب',
                            items: doctors
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(d.fullName),
                                  ),
                                )
                                .toList(),
                            onChanged: isSubmitting
                                ? (_) {}
                                : (id) => setState(() => _doctorId = id),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'العملة (اختياري)',
                            style: AppTextStyles.font14MediumText,
                          ),
                          const SizedBox(height: 8),
                          CaseLookupDropdown(
                            value: _currencyId,
                            icon: Icons.attach_money_outlined,
                            hintText: 'اختر العملة',
                            items: currencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name ?? c.code ?? '—'),
                                  ),
                                )
                                .toList(),
                            onChanged: isSubmitting
                                ? (_) {}
                                : (id) => setState(() => _currencyId = id),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'تاريخ الاستحقاق (اختياري)',
                            style: AppTextStyles.font14MediumText,
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: isSubmitting ? null : _pickDueDate,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: glass.surfaceGradient,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.glass,
                                ),
                                border: Border.all(color: glass.strokeColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: glass.onGlassMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _dueDate == null
                                        ? 'اختر تاريخ الاستحقاق'
                                        : _isoDate(_dueDate!),
                                    style: AppTextStyles.font14MediumText
                                        .copyWith(
                                          color: _dueDate == null
                                              ? glass.onGlassMuted
                                              : glass.onGlass,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الخصم (قيمة)',
                                      style: AppTextStyles.font14MediumText,
                                    ),
                                    const SizedBox(height: 8),
                                    AppTextFormField(
                                      controller: _discountValueController,
                                      hintText: '0',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      enabled: !isSubmitting,
                                      validator: (_) => null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الخصم (%)',
                                      style: AppTextStyles.font14MediumText,
                                    ),
                                    const SizedBox(height: 8),
                                    AppTextFormField(
                                      controller: _discountPercentageController,
                                      hintText: '0',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      enabled: !isSubmitting,
                                      validator: (_) => null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                'البنود',
                                style: AppTextStyles.font16MediumText,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: isSubmitting ? null : _addLine,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('إضافة بند'),
                              ),
                            ],
                          ),
                          if (_lines.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'لا توجد بنود بعد',
                                style: AppTextStyles.font14RegularSecondary
                                    .copyWith(color: glass.onGlassMuted),
                              ),
                            )
                          else
                            for (var i = 0; i < _lines.length; i++)
                              _InvoiceLineTile(
                                line: _lines[i],
                                onRemove: isSubmitting
                                    ? null
                                    : () => _removeLine(i),
                              ),
                          const SizedBox(height: 24),
                          if (isSubmitting)
                            const Center(
                              child: CustomCircleProgressIndiacatorWidget(),
                            )
                          else
                            CustomButtonWidget(
                              onPressed: _onSubmit,
                              buttonText: 'إنشاء الفاتورة',
                            ),
                        ],
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

class _InvoiceLineTile extends StatelessWidget {
  const _InvoiceLineTile({required this.line, required this.onRemove});

  final CreateInvoiceLineRequestModel line;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.description,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${line.quantity} × ${line.unitPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'حذف البند',
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 18, color: glass.error),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLineFormDialog extends StatefulWidget {
  const _InvoiceLineFormDialog();

  @override
  State<_InvoiceLineFormDialog> createState() => _InvoiceLineFormDialogState();
}

class _InvoiceLineFormDialogState extends State<_InvoiceLineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      CreateInvoiceLineRequestModel(
        description: _descriptionController.text.trim(),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        unitPrice: double.tryParse(_unitPriceController.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة بند', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextFormField(
                  controller: _descriptionController,
                  hintText: 'الوصف',
                  prefixIcon: Icon(
                    Icons.description_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'الوصف مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _quantityController,
                  hintText: 'الكمية',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(
                    Icons.numbers_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) {
                    final qty = int.tryParse(value?.trim() ?? '');
                    if (qty == null || qty <= 0) return 'أدخل كمية صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _unitPriceController,
                  hintText: 'سعر الوحدة',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) {
                    final price = double.tryParse(value?.trim() ?? '');
                    if (price == null || price < 0) return 'أدخل سعراً صحيحاً';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onConfirm, child: const Text('إضافة')),
      ],
    );
  }
}
