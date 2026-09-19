import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:flutter/material.dart';

/// Records a manual cash movement — money put into or taken out of the drawer
/// that is neither a doctor's payment nor a recorded expense.
///
/// The currency is required, not optional as it is on an expense: this writes
/// into one specific box, and the server has no sane default to pick when the
/// lab keeps more than one.
Future<CreateCashBoxEntryRequestModel?> showCashboxEntryDialog(
  BuildContext context, {
  required List<CurrencyModel> currencies,
}) {
  return showDialog<CreateCashBoxEntryRequestModel>(
    context: context,
    builder: (_) => _CashboxEntryDialog(currencies: currencies),
  );
}

class _CashboxEntryDialog extends StatefulWidget {
  const _CashboxEntryDialog({required this.currencies});

  final List<CurrencyModel> currencies;

  @override
  State<_CashboxEntryDialog> createState() => _CashboxEntryDialogState();
}

class _CashboxEntryDialogState extends State<_CashboxEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  CashBoxEntryType _type = CashBoxEntryType.cashIn;
  String? _currencyId;
  DateTime _entryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // One currency means there is nothing to ask: pre-selecting it saves the
    // most common lab a tap on every movement.
    if (widget.currencies.length == 1) {
      _currencyId = widget.currencies.single.id;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(_entryDate.year - 3),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _entryDate = picked);
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currencyId = _currencyId;
    if (currencyId == null) return;

    final notes = _notesController.text.trim();

    Navigator.of(context).pop(
      CreateCashBoxEntryRequestModel(
        currencyId: currencyId,
        type: _type,
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        category: _categoryController.text.trim(),
        notes: notes.isEmpty ? null : notes,
        entryDate: ApiTime.formatDate(_entryDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      title: Text('حركة نقدية', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<CashBoxEntryType>(
                  segments: [
                    for (final type in CashBoxEntryType.values)
                      ButtonSegment(
                        value: type,
                        label: Text(type.label),
                        icon: Icon(
                          type == CashBoxEntryType.cashIn
                              ? Icons.south_west
                              : Icons.north_east,
                          size: 16,
                        ),
                      ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) =>
                      setState(() => _type = selection.first),
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _amountController,
                  hintText: 'المبلغ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: glass.onGlassMuted,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    // The server refuses anything under 0.01; saying so here
                    // beats a round-trip to be told.
                    if (amount == null || amount < 0.01) {
                      return 'أدخل مبلغاً صحيحاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CaseLookupDropdown(
                  value: _currencyId,
                  icon: Icons.attach_money_outlined,
                  hintText: 'العملة',
                  items: widget.currencies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name ?? c.code ?? '—'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _currencyId = value),
                ),
                // The dropdown carries no validator of its own, so the
                // requirement is said here rather than left to a silent
                // no-op when Save is pressed with nothing chosen.
                if (_currencyId == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'العملة مطلوبة',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _categoryController,
                  hintText: 'الفئة (مثال: سلفة، إيداع بنكي)',
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: glass.onGlassMuted,
                  ),
                  // Required by the API, and rightly: a movement nobody can
                  // account for later is worse than no record at all.
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'الفئة مطلوبة'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _notesController,
                  hintText: 'ملاحظات (اختياري)',
                  maxLines: 2,
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: glass.onGlassMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ApiTime.formatDate(_entryDate),
                        style: AppTextStyles.font14MediumText,
                      ),
                    ],
                  ),
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
        TextButton(onPressed: _onConfirm, child: const Text('حفظ')),
      ],
    );
  }
}
