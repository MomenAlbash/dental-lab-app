import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:flutter/material.dart';

/// Sets what the box held in one currency before its ledger begins.
///
/// One balance per currency, replaced rather than added to — picking a
/// currency that already has one loads its amount so the user edits what is
/// there instead of unknowingly overwriting it with a blank field.
Future<SetCashBoxOpeningBalanceRequestModel?>
showCashboxOpeningBalanceDialog(
  BuildContext context, {
  required List<CurrencyModel> currencies,
  required List<CashBoxOpeningBalanceModel> existing,
}) {
  return showDialog<SetCashBoxOpeningBalanceRequestModel>(
    context: context,
    builder: (_) => _OpeningBalanceDialog(
      currencies: currencies,
      existing: existing,
    ),
  );
}

class _OpeningBalanceDialog extends StatefulWidget {
  const _OpeningBalanceDialog({
    required this.currencies,
    required this.existing,
  });

  final List<CurrencyModel> currencies;
  final List<CashBoxOpeningBalanceModel> existing;

  @override
  State<_OpeningBalanceDialog> createState() => _OpeningBalanceDialogState();
}

class _OpeningBalanceDialogState extends State<_OpeningBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _currencyId;
  DateTime _asOfDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.currencies.length == 1) {
      _onCurrencyChanged(widget.currencies.single.id);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Loads whatever this currency's box already declares, so the field shows
  /// the value being replaced rather than an empty box that reads as "none".
  void _onCurrencyChanged(String? currencyId) {
    setState(() {
      _currencyId = currencyId;

      for (final balance in widget.existing) {
        if (balance.currencyId == currencyId) {
          _amountController.text = balance.amount.toStringAsFixed(2);
          _asOfDate = balance.asOfDate ?? _asOfDate;
          return;
        }
      }
      _amountController.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOfDate,
      firstDate: DateTime(_asOfDate.year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _asOfDate = picked);
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currencyId = _currencyId;
    if (currencyId == null) return;

    Navigator.of(context).pop(
      SetCashBoxOpeningBalanceRequestModel(
        currencyId: currencyId,
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        asOfDate: ApiTime.formatDate(_asOfDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      title: Text('الرصيد الافتتاحي', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ما كان في الصندوق قبل بداية السجل، لكل عملة على حدة',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
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
                  onChanged: _onCurrencyChanged,
                ),
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
                  controller: _amountController,
                  hintText: 'المبلغ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icon(
                    Icons.account_balance_outlined,
                    color: glass.onGlassMuted,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    // Zero is allowed here, unlike a movement: "the box
                    // started empty" is a real statement about the box.
                    if (amount == null || amount < 0) {
                      return 'أدخل مبلغاً صحيحاً';
                    }
                    return null;
                  },
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
                        ApiTime.formatDate(_asOfDate),
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
