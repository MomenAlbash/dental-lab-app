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
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/purchases/data/models/create_purchase_request_model.dart';
import 'package:dental_lab_app/features/purchases/logic/purchase_form/purchase_form_cubit.dart';
import 'package:dental_lab_app/features/purchases/logic/purchase_form/purchase_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Records one purchase (`POST /Purchases`) — a supplier, an inventory item,
/// what it cost, and how much landed. The server writes the matching
/// inventory movement on its own; nothing further moves stock here.
class PurchaseFormPage extends StatelessWidget {
  const PurchaseFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PurchaseFormCubit>()..loadCatalog(),
      child: const _PurchaseFormView(),
    );
  }
}

class _PurchaseFormView extends StatefulWidget {
  const _PurchaseFormView();

  @override
  State<_PurchaseFormView> createState() => _PurchaseFormViewState();
}

class _PurchaseFormViewState extends State<_PurchaseFormView> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _supplierId;
  String? _inventoryItemId;
  String? _currencyId;
  DateTime _purchaseDate = DateTime.now();

  /// The last loaded catalog — kept around so the form stays populated while
  /// [PurchaseFormSubmitting]/[PurchaseFormError] replace
  /// [PurchaseFormCatalogLoaded] in the cubit's state during and after
  /// submission.
  PurchaseFormCatalogLoaded? _catalog;

  @override
  void dispose() {
    _quantityController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  String _isoDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final supplierId = _supplierId;
    final inventoryItemId = _inventoryItemId;
    final currencyId = _currencyId;
    if (supplierId == null) {
      showToast(message: 'اختر المورد', state: ToastState.error);
      return;
    }
    if (inventoryItemId == null) {
      showToast(message: 'اختر الصنف', state: ToastState.error);
      return;
    }
    if (currencyId == null) {
      showToast(message: 'اختر العملة', state: ToastState.error);
      return;
    }

    context.read<PurchaseFormCubit>().submit(
      CreatePurchaseRequestModel(
        supplierId: supplierId,
        inventoryItemId: inventoryItemId,
        currencyId: currencyId,
        quantity: double.parse(_quantityController.text.trim()),
        amount: double.parse(_amountController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        purchaseDate: _isoDate(_purchaseDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'تسجيل شراء',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<PurchaseFormCubit, PurchaseFormState>(
          listener: (context, state) {
            switch (state) {
              case PurchaseFormSuccess(:final purchase):
                showToast(
                  message: 'تم تسجيل الشراء',
                  state: ToastState.success,
                );
                Navigator.of(context).pop(purchase);
              case PurchaseFormError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            if (state is PurchaseFormCatalogLoading ||
                state is PurchaseFormInitial) {
              return const Center(
                child: CustomCircleProgressIndiacatorWidget(),
              );
            }
            if (state is PurchaseFormCatalogError) {
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

            if (state is PurchaseFormCatalogLoaded) _catalog = state;
            final suppliers = _catalog?.suppliers ?? const [];
            final items = _catalog?.inventoryItems ?? const [];
            final currencies = _catalog?.currencies ?? const [];
            final isSubmitting = state is PurchaseFormSubmitting;

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
                              'المورد',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            CaseLookupDropdown(
                              value: _supplierId,
                              icon: Icons.local_shipping_outlined,
                              hintText: 'اختر المورد',
                              items: suppliers
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.name ?? '—'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSubmitting
                                  ? (_) {}
                                  : (id) => setState(() => _supplierId = id),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'الصنف',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            CaseLookupDropdown(
                              value: _inventoryItemId,
                              icon: Icons.inventory_2_outlined,
                              hintText: 'اختر الصنف',
                              items: items
                                  .map(
                                    (i) => DropdownMenuItem(
                                      value: i.id,
                                      child: Text(i.name ?? '—'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSubmitting
                                  ? (_) {}
                                  : (id) =>
                                        setState(() => _inventoryItemId = id),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'العملة',
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
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الكمية',
                                        style: AppTextStyles.font14MediumText,
                                      ),
                                      const SizedBox(height: 8),
                                      AppTextFormField(
                                        controller: _quantityController,
                                        hintText: '0',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        enabled: !isSubmitting,
                                        validator: (value) {
                                          final trimmed = value?.trim() ?? '';
                                          if (trimmed.isEmpty) {
                                            return 'الكمية مطلوبة';
                                          }
                                          final quantity = double.tryParse(
                                            trimmed,
                                          );
                                          if (quantity == null ||
                                              quantity <= 0) {
                                            return 'أدخل كمية صحيحة';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'المبلغ',
                                        style: AppTextStyles.font14MediumText,
                                      ),
                                      const SizedBox(height: 8),
                                      AppTextFormField(
                                        controller: _amountController,
                                        hintText: '0',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        enabled: !isSubmitting,
                                        validator: (value) {
                                          final trimmed = value?.trim() ?? '';
                                          if (trimmed.isEmpty) {
                                            return 'المبلغ مطلوب';
                                          }
                                          final amount = double.tryParse(
                                            trimmed,
                                          );
                                          if (amount == null || amount < 0) {
                                            return 'أدخل مبلغاً صحيحاً';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'تاريخ الشراء',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: isSubmitting ? null : _pickDate,
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
                                      _isoDate(_purchaseDate),
                                      style: AppTextStyles.font14MediumText
                                          .copyWith(color: glass.onGlass),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'ملاحظات',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _notesController,
                              hintText: 'أدخل ملاحظات (اختياري)',
                              maxLines: 2,
                              enabled: !isSubmitting,
                              prefixIcon: Icon(
                                Icons.notes_outlined,
                                color: glass.onGlassMuted,
                              ),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 24),
                            if (isSubmitting)
                              const Center(
                                child: CustomCircleProgressIndiacatorWidget(),
                              )
                            else
                              CustomButtonWidget(
                                onPressed: _onSubmit,
                                buttonText: 'تسجيل الشراء',
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
