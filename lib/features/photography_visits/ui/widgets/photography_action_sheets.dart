import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/ui/widgets/date_time_pick.dart';
import 'package:dental_lab_app/features/photography_visits/ui/widgets/shade_notes_fields.dart';
import 'package:flutter/material.dart';

/// Sets (or moves) a clinic visit's date and technician.
Future<SchedulePhotographyVisitRequestModel?> showScheduleVisitSheet(
  BuildContext context, {
  required PhotographyVisitModel visit,
  required List<EmployeeModel> employees,
  required List<CurrencyModel> currencies,
}) {
  return showGlassBottomSheet<SchedulePhotographyVisitRequestModel>(
    context: context,
    builder: (_) => _ScheduleSheet(
      visit: visit,
      employees: employees,
      currencies: currencies,
    ),
  );
}

/// Completes the visit — which also bills its price to the doctor.
Future<CompletePhotographyVisitRequestModel?> showCompleteVisitSheet(
  BuildContext context, {
  required PhotographyVisitModel visit,
  required List<CurrencyModel> currencies,
}) {
  return showGlassBottomSheet<CompletePhotographyVisitRequestModel>(
    context: context,
    builder: (_) => _CompleteSheet(visit: visit, currencies: currencies),
  );
}

/// Asks for an optional reason. Null means dismissed; an empty string means
/// "cancel without a note".
Future<String?> showCancelVisitDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _CancelDialog(),
  );
}

/// The price as it may be changed while scheduling or completing. Sent only
/// when it actually differs — a null price keeps the one set on request.
class _PriceFields extends StatelessWidget {
  const _PriceFields({
    required this.priceController,
    required this.currencies,
    required this.currencyId,
    required this.onCurrencyChanged,
  });

  final TextEditingController priceController;
  final List<CurrencyModel> currencies;
  final String? currencyId;
  final ValueChanged<String?> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextFormField(
            controller: priceController,
            hintText: 'السعر',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final price = double.tryParse(value?.trim() ?? '');
              return price == null || price < 0 ? 'قيمة غير صالحة' : null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: currencies.any((c) => c.id == currencyId)
                ? currencyId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'العملة',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final currency in currencies)
                DropdownMenuItem(
                  value: currency.id,
                  child: Text(currency.code ?? currency.name ?? '—'),
                ),
            ],
            onChanged: onCurrencyChanged,
          ),
        ),
      ],
    );
  }
}

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({
    required this.visit,
    required this.employees,
    required this.currencies,
  });

  final PhotographyVisitModel visit;
  final List<EmployeeModel> employees;
  final List<CurrencyModel> currencies;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _priceController = TextEditingController(
    text: widget.visit.price.toString(),
  );
  final _noteController = TextEditingController();

  late DateTime? _scheduledAt = widget.visit.scheduledAt?.toLocal();
  late String? _employeeId = widget.visit.assignedEmployeeId;
  late String? _currencyId = widget.visit.currencyId;

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final scheduledAt = _scheduledAt;
    if (scheduledAt == null) return;

    final price = double.tryParse(_priceController.text.trim());
    final priceChanged =
        price != widget.visit.price || _currencyId != widget.visit.currencyId;
    final note = _noteController.text.trim();

    Navigator.of(context).pop(
      SchedulePhotographyVisitRequestModel(
        scheduledAt: scheduledAt,
        assignedEmployeeId: _employeeId,
        price: priceChanged ? price : null,
        currencyId: priceChanged ? _currencyId : null,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return _SheetFrame(
      title: 'جدولة الزيارة',
      formKey: _formKey,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await pickDateTime(context, initial: _scheduledAt);
            if (picked != null) setState(() => _scheduledAt = picked);
          },
          icon: const Icon(Icons.event_outlined),
          label: Text(
            _scheduledAt == null
                ? 'اختر الموعد'
                : ApiTime.displayDateTime(_scheduledAt),
          ),
        ),
        if (_scheduledAt == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'الموعد مطلوب',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.error,
              ),
            ),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: widget.employees.any((e) => e.id == _employeeId)
              ? _employeeId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'الفني (اختياري)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(child: Text('لاحقاً')),
            for (final employee in widget.employees)
              DropdownMenuItem<String?>(
                value: employee.id,
                child: Text(
                  employee.fullName.isEmpty ? '—' : employee.fullName,
                ),
              ),
          ],
          onChanged: (id) => setState(() => _employeeId = id),
        ),
        const SizedBox(height: 12),
        _PriceFields(
          priceController: _priceController,
          currencies: widget.currencies,
          currencyId: _currencyId,
          onCurrencyChanged: (id) => setState(() => _currencyId = id),
        ),
        const SizedBox(height: 12),
        AppTextFormField(
          controller: _noteController,
          hintText: 'ملاحظة (اختيارية)',
          maxLines: 2,
          validator: (_) => null,
        ),
        const SizedBox(height: 16),
        CustomButtonWidget(
          buttonText: 'حفظ الموعد',
          onPressed: _scheduledAt == null ? null : _submit,
        ),
      ],
    );
  }
}

class _CompleteSheet extends StatefulWidget {
  const _CompleteSheet({required this.visit, required this.currencies});

  final PhotographyVisitModel visit;
  final List<CurrencyModel> currencies;

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _shade = ShadeNotesControllers(widget.visit.shade);
  late final _priceController = TextEditingController(
    text: widget.visit.price.toString(),
  );
  final _noteController = TextEditingController();

  late String? _currencyId = widget.visit.currencyId;

  @override
  void dispose() {
    _shade.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = double.tryParse(_priceController.text.trim());
    final priceChanged =
        price != widget.visit.price || _currencyId != widget.visit.currencyId;
    final note = _noteController.text.trim();

    Navigator.of(context).pop(
      CompletePhotographyVisitRequestModel(
        shade: _shade.toModel(),
        price: priceChanged ? price : null,
        currencyId: priceChanged ? _currencyId : null,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return _SheetFrame(
      title: 'إكمال الزيارة',
      formKey: _formKey,
      children: [
        Text(
          // Completing is the billing step — say so before the button.
          'سيُسجَّل السعر على حساب الطبيب بفاتورة عند الإكمال.',
          style: AppTextStyles.font12RegularHint.copyWith(color: glass.warning),
        ),
        const SizedBox(height: 12),
        _PriceFields(
          priceController: _priceController,
          currencies: widget.currencies,
          currencyId: _currencyId,
          onCurrencyChanged: (id) => setState(() => _currencyId = id),
        ),
        const SizedBox(height: 12),
        ShadeNotesFields(controllers: _shade),
        AppTextFormField(
          controller: _noteController,
          hintText: 'ملاحظة (اختيارية)',
          maxLines: 2,
          validator: (_) => null,
        ),
        const SizedBox(height: 16),
        CustomButtonWidget(buttonText: 'إكمال', onPressed: _submit),
      ],
    );
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إلغاء الزيارة'),
      content: TextField(
        controller: _noteController,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'السبب (اختياري)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('رجوع'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_noteController.text.trim()),
          style: TextButton.styleFrom(foregroundColor: context.glass.error),
          child: const Text('إلغاء الزيارة'),
        ),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.formKey,
    required this.children,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTextStyles.font18MediumText.copyWith(
                  color: context.glass.onGlass,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
