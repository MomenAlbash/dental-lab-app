import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:flutter/material.dart';

/// Bumps one doctor's free allowance at one priority level.
///
/// **Two independent decisions**, which is why the dialog asks both rather
/// than offering four buttons:
/// - *permanent or this period only* — permanent rewrites the standing
///   free-per-month; a bonus tops up the current period and is gone next.
/// - *free or paid* — paid raises an ad-hoc invoice; free just notifies the
///   doctor of the new terms.
///
/// The fee is typed, never computed from the level's per-case surcharge: this
/// is a negotiated figure, and deriving it would quietly invent a price
/// nobody agreed.
Future<IncreasePriorityAllowanceRequestModel?> showIncreaseAllowanceDialog(
  BuildContext context, {
  required String doctorName,
  required PriorityQuotaLineModel line,
}) {
  return showDialog<IncreasePriorityAllowanceRequestModel>(
    context: context,
    builder: (_) =>
        _IncreaseAllowanceDialog(doctorName: doctorName, line: line),
  );
}

class _IncreaseAllowanceDialog extends StatefulWidget {
  const _IncreaseAllowanceDialog({
    required this.doctorName,
    required this.line,
  });

  final String doctorName;
  final PriorityQuotaLineModel line;

  @override
  State<_IncreaseAllowanceDialog> createState() =>
      _IncreaseAllowanceDialogState();
}

class _IncreaseAllowanceDialogState extends State<_IncreaseAllowanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _feeController = TextEditingController();

  bool _permanent = false;
  bool _isPaid = false;
  String? _currencyId;

  List<CurrencyModel> _currencies = const [];

  @override
  void initState() {
    super.initState();
    // Seeded with the standing figure when writing a permanent one: a raise is
    // almost always "the current number, plus a bit".
    _amountController = TextEditingController(
      text: '${widget.line.freePerMonth}',
    );
    _currencyId = widget.line.currency?.id;
    _loadCurrencies();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    final result = await getIt<AccountingRepo>().getCurrencies();
    if (!mounted) return;

    setState(() {
      _currencies = result.fold((_) => const [], (list) => list);
      if (_currencyId == null && _currencies.length == 1) {
        _currencyId = _currencies.single.id;
      }
    });
  }

  void _onPermanentChanged(bool value) {
    setState(() {
      _permanent = value;
      // The field means a different number in each mode — a standing total
      // versus a top-up — so it is reseeded rather than carried across.
      _amountController.text = value ? '${widget.line.freePerMonth}' : '';
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isPaid && _currencyId == null) return;

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    Navigator.of(context).pop(
      IncreasePriorityAllowanceRequestModel(
        permanent: _permanent,
        newFreePerMonth: _permanent ? amount : null,
        bonusFree: _permanent ? null : amount,
        isPaid: _isPaid,
        paidAmount: _isPaid
            ? double.tryParse(_feeController.text.trim())
            : null,
        currencyId: _isPaid ? _currencyId : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final line = widget.line;

    return AlertDialog(
      title: Text('زيادة الحصة', style: AppTextStyles.font18MediumText),
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
                  '${widget.doctorName} · ${line.priorityLabel}',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  'الحالي: ${line.totalFree} مجانية، مستعمَل ${line.usedThisMonth}',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _permanent,
                  onChanged: _onPermanentChanged,
                  title: Text(
                    'دائمة',
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                  subtitle: Text(
                    _permanent
                        ? 'تُعدَّل الحصة الشهرية الثابتة لهذا الطبيب'
                        : 'إضافة لهذه الفترة فقط، تنتهي مع بداية الفترة القادمة',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                AppTextFormField(
                  controller: _amountController,
                  hintText: _permanent
                      ? 'الحصة الشهرية الجديدة'
                      : 'عدد الحالات الإضافية لهذه الفترة',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'أدخل عدداً صحيحاً';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPaid,
                  onChanged: (value) => setState(() => _isPaid = value),
                  title: Text(
                    'مقابل مبلغ',
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                  subtitle: Text(
                    _isPaid
                        ? 'تُصدَر فاتورة بالمبلغ أدناه'
                        : 'يُبلَّغ الطبيب بالشروط الجديدة بلا فاتورة',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),

                if (_isPaid) ...[
                  const SizedBox(height: 8),
                  AppTextFormField(
                    controller: _feeController,
                    hintText: 'المبلغ',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (!_isPaid) return null;
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'أدخل مبلغاً صحيحاً';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  CaseLookupDropdown(
                    value: _currencyId,
                    icon: Icons.attach_money_outlined,
                    hintText: 'العملة',
                    items: [
                      for (final currency in _currencies)
                        DropdownMenuItem(
                          value: currency.id,
                          child: Text(currency.name ?? currency.code ?? '—'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _currencyId = value),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'المبلغ يُكتب يدوياً ولا يُحسب من رسم الحالة الواحدة',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ),
                ],
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
        TextButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}
