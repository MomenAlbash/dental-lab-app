import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/payment_model.dart';
import 'package:flutter/material.dart';

/// How the doctor settled, and anything worth recording about it.
typedef SettleDoctorResult = ({PaymentMethod? method, String? notes});

/// Confirms closing **every** outstanding invoice a doctor has in one
/// currency.
///
/// A confirmation rather than a form: there is no amount to type — the server
/// settles whatever is outstanding — and no receipt to attach, since one file
/// cannot stand for the N invoices this closes. What it does ask is how the
/// money came in, because that is not derivable from anything.
Future<SettleDoctorResult?> showSettleDoctorDialog(
  BuildContext context, {
  required String currencyLabel,
  required String outstanding,
}) {
  return showDialog<SettleDoctorResult>(
    context: context,
    builder: (_) => _SettleDoctorDialog(
      currencyLabel: currencyLabel,
      outstanding: outstanding,
    ),
  );
}

class _SettleDoctorDialog extends StatefulWidget {
  const _SettleDoctorDialog({
    required this.currencyLabel,
    required this.outstanding,
  });

  final String currencyLabel;

  /// Already formatted with its currency — this screen never shows a bare
  /// number where two currencies could be in play.
  final String outstanding;

  @override
  State<_SettleDoctorDialog> createState() => _SettleDoctorDialogState();
}

class _SettleDoctorDialogState extends State<_SettleDoctorDialog> {
  final _notesController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final notes = _notesController.text.trim();
    Navigator.of(
      context,
    ).pop((method: _method, notes: notes.isEmpty ? null : notes));
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      title: Text('تسوية الحساب', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ستُسدَّد كل الفواتير المستحقة بعملة ${widget.currencyLabel}، '
                'بمبلغ ${widget.outstanding}.',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الفواتير بالعملات الأخرى تبقى كما هي.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _method,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'طريقة الدفع',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final method in PaymentMethod.values)
                    DropdownMenuItem(
                      value: method,
                      child: Text(method.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _notesController,
                hintText: 'ملاحظات (اختياري)',
                maxLines: 2,
                validator: (_) => null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onConfirm, child: const Text('تسوية')),
      ],
    );
  }
}
