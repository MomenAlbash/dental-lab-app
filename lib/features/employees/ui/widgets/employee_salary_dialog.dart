import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/payroll/data/models/payroll_enums.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:flutter/material.dart';

/// Opens a new pay spell for an employee.
///
/// Seeded from the current arrangement, because a raise is almost always "the
/// same shape, a different number" — and starting from blank would make
/// somebody re-pick the currency and pay type every time.
Future<SaveEmployeeSalarySystemRequestModel?> showEmployeeSalaryDialog(
  BuildContext context, {
  required String employeeId,
  EmployeeSalarySystemModel? current,
}) {
  return showDialog<SaveEmployeeSalarySystemRequestModel>(
    context: context,
    builder: (_) =>
        _EmployeeSalaryDialog(employeeId: employeeId, current: current),
  );
}

class _EmployeeSalaryDialog extends StatefulWidget {
  const _EmployeeSalaryDialog({required this.employeeId, this.current});

  final String employeeId;
  final EmployeeSalarySystemModel? current;

  @override
  State<_EmployeeSalaryDialog> createState() => _EmployeeSalaryDialogState();
}

class _EmployeeSalaryDialogState extends State<_EmployeeSalaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rateController;
  late final TextEditingController _noteController;
  late final TextEditingController _absentValueController;
  late final TextEditingController _delayController;
  late final TextEditingController _earlyLeaveController;
  late final TextEditingController _gapController;
  late final TextEditingController _divisorController;
  late final TextEditingController _workHoursController;
  late final TextEditingController _overtimeController;

  late PayType _payType;
  late PayPeriod _payPeriod;
  late AbsentDeductionType _absentType;
  late MinutePenaltyBasis _penaltyBasis;
  late bool _includeStagePay;
  String? _currencyId;

  List<CurrencyModel> _currencies = const [];

  /// The API implies stage pay for [PayType.pieceRate], so the switch is
  /// shown on and locked rather than offering a choice that does nothing.
  bool get _stagePayImplied => _payType == PayType.pieceRate;

  @override
  void initState() {
    super.initState();
    final current = widget.current;

    _rateController = TextEditingController(
      text: current == null ? '' : current.payRate.toString(),
    );
    _noteController = TextEditingController(text: current?.note ?? '');
    _absentValueController = TextEditingController(
      text: '${current?.absentDeductionValue ?? 0}',
    );
    _delayController = TextEditingController(
      text: '${current?.delayDeductionPerMinute ?? 0}',
    );
    _earlyLeaveController = TextEditingController(
      text: '${current?.earlyLeaveDeductionPerMinute ?? 0}',
    );
    _gapController = TextEditingController(
      text: '${current?.gapDeductionPerMinute ?? 0}',
    );
    _divisorController = TextEditingController(
      text: '${current?.dailyRateDivisor ?? 30}',
    );
    _workHoursController = TextEditingController(
      text: '${current?.workHoursPerDay ?? 8}',
    );
    _overtimeController = TextEditingController(
      text: current?.overtimePayPerMinute?.toString() ?? '',
    );

    _payType = current?.payType ?? PayType.attendance;
    _payPeriod = current?.payPeriod ?? PayPeriod.monthly;
    _absentType = current?.absentDeductionType ?? AbsentDeductionType.none;
    _penaltyBasis =
        current?.minutePenaltyBasis ?? MinutePenaltyBasis.fixedAmount;
    _includeStagePay = current?.includeStagePay ?? false;
    _currencyId = current?.currencyId;

    _loadCurrencies();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _noteController.dispose();
    _absentValueController.dispose();
    _delayController.dispose();
    _earlyLeaveController.dispose();
    _gapController.dispose();
    _divisorController.dispose();
    _workHoursController.dispose();
    _overtimeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    final result = await getIt<AccountingRepo>().getCurrencies();
    if (!mounted) return;

    setState(() {
      _currencies = result.fold((_) => const [], (list) => list);
      // One currency means nothing to ask.
      if (_currencyId == null && _currencies.length == 1) {
        _currencyId = _currencies.single.id;
      }
    });
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currencyId = _currencyId;
    if (currencyId == null) return;

    final note = _noteController.text.trim();
    final overtimeText = _overtimeController.text.trim();

    Navigator.of(context).pop(
      SaveEmployeeSalarySystemRequestModel(
        employeeId: widget.employeeId,
        currencyId: currencyId,
        payType: _payType,
        payPeriod: _payPeriod,
        payRate: _number(_rateController),
        absentDeductionType: _absentType,
        absentDeductionValue: _number(_absentValueController),
        minutePenaltyBasis: _penaltyBasis,
        delayDeductionPerMinute: _number(_delayController),
        earlyLeaveDeductionPerMinute: _number(_earlyLeaveController),
        gapDeductionPerMinute: _number(_gapController),
        dailyRateDivisor: int.tryParse(_divisorController.text.trim()) ?? 30,
        workHoursPerDay: _number(_workHoursController),
        // Empty means overtime is not paid at all — a different statement
        // from a rate of zero.
        overtimePayPerMinute: overtimeText.isEmpty
            ? null
            : double.tryParse(overtimeText),
        includeStagePay: _stagePayImplied || _includeStagePay,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      title: Text('نظام الراتب', style: AppTextStyles.font18MediumText),
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
                  // The spell is what makes a past payslip still correct.
                  'سيبدأ نظام جديد من اليوم ويُغلق النظام الحالي، '
                  'وتبقى كشوف الرواتب السابقة محسوبة بالنظام القديم',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<PayType>(
                  initialValue: _payType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'طريقة الاحتساب',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final type in PayType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _payType = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PayPeriod>(
                  initialValue: _payPeriod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'دورة الراتب',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final period in PayPeriod.values)
                      DropdownMenuItem(
                        value: period,
                        child: Text(period.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _payPeriod = value);
                  },
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _rateController,
                  hintText: switch (_payType) {
                    PayType.perTooth => 'الأجر لكل سن',
                    PayType.pieceRate => 'الأجر لكل قطعة',
                    PayType.salesPercentage => 'النسبة المئوية',
                    PayType.scannerSessionRate => 'الأجر لكل جلسة',
                    PayType.hourly => 'الأجر لكل ساعة',
                    _ => 'الراتب',
                  },
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final rate = double.tryParse(value?.trim() ?? '');
                    // Zero is allowed by the API — a commission-only
                    // arrangement is a real one.
                    if (rate == null || rate < 0) return 'أدخل قيمة صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إضافة أجر المراحل فوق الراتب'),
                  subtitle: _stagePayImplied
                      ? const Text('مشمول تلقائياً مع هذه الطريقة')
                      : null,
                  value: _stagePayImplied || _includeStagePay,
                  onChanged: _stagePayImplied
                      ? null
                      : (value) => setState(() => _includeStagePay = value),
                ),

                const SizedBox(height: 12),
                const _SectionLabel('الغياب'),
                DropdownButtonFormField<AbsentDeductionType>(
                  initialValue: _absentType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'طريقة خصم الغياب',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final type in AbsentDeductionType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _absentType = value);
                  },
                ),
                if (_absentType != AbsentDeductionType.none) ...[
                  const SizedBox(height: 8),
                  _AmountField(
                    controller: _absentValueController,
                    label: _absentType == AbsentDeductionType.fixedAmount
                        ? 'المبلغ المخصوم عن يوم الغياب'
                        : 'عدد أضعاف الأجر اليومي',
                  ),
                ],

                const SizedBox(height: 12),
                const _SectionLabel('خصومات الدقائق'),
                SegmentedButton<MinutePenaltyBasis>(
                  segments: [
                    for (final basis in MinutePenaltyBasis.values)
                      ButtonSegment(value: basis, label: Text(basis.label)),
                  ],
                  selected: {_penaltyBasis},
                  onSelectionChanged: (selection) =>
                      setState(() => _penaltyBasis = selection.first),
                ),
                if (_penaltyBasis.isDerived)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      // The per-minute rates stop mattering: the server works
                      // the figure out of this salary.
                      'ستُحتسب قيمة الدقيقة من الراتب نفسه',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 8),
                  _AmountField(
                    controller: _delayController,
                    label: 'خصم دقيقة التأخير',
                  ),
                  _AmountField(
                    controller: _earlyLeaveController,
                    label: 'خصم دقيقة الخروج المبكر',
                  ),
                  _AmountField(
                    controller: _gapController,
                    label: 'خصم دقيقة الانقطاع',
                  ),
                ],

                const SizedBox(height: 12),
                const _SectionLabel('الاحتساب'),
                _AmountField(
                  controller: _divisorController,
                  label: 'عدد أيام قسمة الراتب الشهري',
                  isInteger: true,
                  validator: (value) {
                    final days = int.tryParse(value?.trim() ?? '');
                    // The API's own bounds — a month has at most 31 days.
                    if (days == null || days < 1 || days > 31) {
                      return 'بين 1 و31';
                    }
                    return null;
                  },
                ),
                _AmountField(
                  controller: _workHoursController,
                  label: 'ساعات العمل اليومية',
                  validator: (value) {
                    final hours = double.tryParse(value?.trim() ?? '');
                    if (hours == null || hours < 0.1 || hours > 24) {
                      return 'بين 0.1 و24';
                    }
                    return null;
                  },
                ),
                _AmountField(
                  controller: _overtimeController,
                  label: 'أجر دقيقة العمل الإضافي (اتركه فارغاً إن لم يُحتسب)',
                ),

                const SizedBox(height: 4),
                AppTextFormField(
                  controller: _noteController,
                  hintText: 'ملاحظة (اختيارية)',
                  maxLines: 2,
                  validator: (_) => null,
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
        TextButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.font14MediumText.copyWith(
          color: context.glass.onGlass,
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    this.isInteger = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool isInteger;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppTextFormField(
        controller: controller,
        hintText: label,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
        validator: validator ?? (_) => null,
      ),
    );
  }
}

/// A standing payroll adjustment.
///
/// The kind decides what the value even means — a count of minutes for an
/// override, an amount for a raise or a cut — which is why the currency field
/// appears and disappears with it rather than sitting there unused.
Future<SaveSalaryExceptionRequestModel?> showSalaryExceptionDialog(
  BuildContext context, {
  required String employeeId,
}) {
  return showDialog<SaveSalaryExceptionRequestModel>(
    context: context,
    builder: (_) => _SalaryExceptionDialog(employeeId: employeeId),
  );
}

class _SalaryExceptionDialog extends StatefulWidget {
  const _SalaryExceptionDialog({required this.employeeId});

  final String employeeId;

  @override
  State<_SalaryExceptionDialog> createState() => _SalaryExceptionDialogState();
}

class _SalaryExceptionDialogState extends State<_SalaryExceptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();

  SalaryExceptionKind _kind = SalaryExceptionKind.salaryIncrease;
  String? _currencyId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  List<CurrencyModel> _currencies = const [];

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime(initial.year + 2),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_kind.needsCurrency && _currencyId == null) return;

    Navigator.of(context).pop(
      SaveSalaryExceptionRequestModel(
        employeeId: widget.employeeId,
        kind: _kind,
        value: double.tryParse(_valueController.text.trim()) ?? 0,
        currencyId: _currencyId,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      title: Text('استثناء راتب', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<SalaryExceptionKind>(
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'النوع',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final kind in SalaryExceptionKind.values)
                      DropdownMenuItem(value: kind, child: Text(kind.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _kind = value);
                  },
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _valueController,
                  hintText: _kind.needsCurrency ? 'المبلغ' : 'القيمة',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null) return 'أدخل قيمة صحيحة';
                    return null;
                  },
                ),

                // Only the two money kinds carry a currency; an override is a
                // count of days or minutes and has none.
                if (_kind.needsCurrency) ...[
                  const SizedBox(height: 12),
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
                ],

                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _reasonController,
                  hintText: 'السبب',
                  maxLines: 2,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      // Required by the API, and rightly: an adjustment
                      // nobody can account for later is the one thing payroll
                      // cannot afford.
                      ? 'السبب مطلوب'
                      : null,
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _pickDate(isStart: true),
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        label: Text(ApiTime.formatDate(_startDate)),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _pickDate(isStart: false),
                        icon: const Icon(Icons.event_busy_outlined, size: 16),
                        label: Text(
                          _endDate == null
                              ? 'مستمر'
                              : ApiTime.formatDate(_endDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  // Null end date is how a standing raise or cut is expressed
                  // — it applies until somebody deactivates it.
                  'اترك تاريخ الانتهاء فارغاً ليبقى الاستثناء مستمراً',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                if (_endDate != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => setState(() => _endDate = null),
                      child: const Text('إزالة تاريخ الانتهاء'),
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
        TextButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}
