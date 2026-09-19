import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:flutter/material.dart';

/// Draws a shift: which days, which hours, and what missing them costs.
///
/// [impact] is what the server says editing this shift would disturb — the
/// people on it and the span of attendance already judged under the old rules.
/// Shown before anything is changed, because "this will affect 9 employees and
/// four months of records" is a different decision from "this is new".
Future<SaveWorkShiftRequestModel?> showWorkShiftFormSheet(
  BuildContext context, {
  WorkShiftModel? shift,
  WorkShiftAttendanceImpactModel? impact,
}) {
  return showGlassBottomSheet<SaveWorkShiftRequestModel>(
    context: context,
    builder: (_) => _WorkShiftFormSheet(shift: shift, impact: impact),
  );
}

class _WorkShiftFormSheet extends StatefulWidget {
  const _WorkShiftFormSheet({this.shift, this.impact});

  final WorkShiftModel? shift;
  final WorkShiftAttendanceImpactModel? impact;

  @override
  State<_WorkShiftFormSheet> createState() => _WorkShiftFormSheetState();
}

class _WorkShiftFormSheetState extends State<_WorkShiftFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _absentValueController;
  late final TextEditingController _delayController;
  late final TextEditingController _earlyLeaveController;
  late final TextEditingController _gapController;
  late final TextEditingController _allowedDelayController;
  late final TextEditingController _allowedEarlyLeaveController;
  late final TextEditingController _allowedGapController;
  late final TextEditingController _divisorController;
  late final TextEditingController _workHoursController;
  late final TextEditingController _overtimeController;

  late AbsentDeductionType _absentType;
  late MinutePenaltyBasis _penaltyBasis;

  /// The week, editable in place. A day with no times is simply not worked —
  /// which is how a five-day shift is expressed.
  final Map<ApiDayOfWeek, ({TimeOfDay? start, TimeOfDay? end})> _days = {};

  @override
  void initState() {
    super.initState();
    final shift = widget.shift;

    _nameController = TextEditingController(text: shift?.name ?? '');
    _absentValueController = TextEditingController(
      text: shift == null ? '0' : shift.absentDeductionValue.toString(),
    );
    _delayController = TextEditingController(
      text: shift == null ? '0' : shift.delayDeductionPerMinute.toString(),
    );
    _earlyLeaveController = TextEditingController(
      text: shift == null ? '0' : shift.earlyLeaveDeductionPerMinute.toString(),
    );
    _gapController = TextEditingController(
      text: shift == null ? '0' : shift.gapDeductionPerMinute.toString(),
    );
    _allowedDelayController = TextEditingController(
      text: '${shift?.allowedDelayMinutesPerDay ?? 0}',
    );
    _allowedEarlyLeaveController = TextEditingController(
      text: '${shift?.allowedEarlyLeaveMinutesPerDay ?? 0}',
    );
    _allowedGapController = TextEditingController(
      text: '${shift?.allowedGapMinutesPerDay ?? 0}',
    );
    _divisorController = TextEditingController(
      text: '${shift?.dailyRateDivisor ?? 30}',
    );
    _workHoursController = TextEditingController(
      text: '${shift?.workHoursPerDay ?? 8}',
    );
    _overtimeController = TextEditingController(
      text: shift?.overtimePayPerMinute?.toString() ?? '',
    );

    _absentType = shift?.absentDeductionType ?? AbsentDeductionType.none;
    _penaltyBasis = shift?.minutePenaltyBasis ?? MinutePenaltyBasis.fixedAmount;

    for (final day in shift?.days ?? const <WorkShiftDayModel>[]) {
      _days[day.dayOfWeek] = (start: day.startTime, end: day.endTime);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _absentValueController.dispose();
    _delayController.dispose();
    _earlyLeaveController.dispose();
    _gapController.dispose();
    _allowedDelayController.dispose();
    _allowedEarlyLeaveController.dispose();
    _allowedGapController.dispose();
    _divisorController.dispose();
    _workHoursController.dispose();
    _overtimeController.dispose();
    super.dispose();
  }

  Future<void> _pickDayTime(ApiDayOfWeek day, {required bool isStart}) async {
    final current = _days[day];

    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? current?.start : current?.end) ??
          TimeOfDay(hour: isStart ? 9 : 17, minute: 0),
    );
    if (picked == null) return;

    setState(() {
      _days[day] = (
        start: isStart ? picked : current?.start,
        end: isStart ? current?.end : picked,
      );
    });
  }

  void _toggleDay(ApiDayOfWeek day, bool on) {
    setState(() {
      if (on) {
        _days[day] = (
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 17, minute: 0),
        );
      } else {
        _days.remove(day);
      }
    });
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  int _int(TextEditingController controller, {int fallback = 0}) =>
      int.tryParse(controller.text.trim()) ?? fallback;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // The API refuses a shift with no days at all, and rightly: it would be a
    // rule that never applies to anybody.
    if (_days.isEmpty) return;

    final overtimeText = _overtimeController.text.trim();

    Navigator.of(context).pop(
      SaveWorkShiftRequestModel(
        name: _nameController.text.trim(),
        days: [
          for (final entry in _days.entries)
            WorkShiftDayModel(
              dayOfWeek: entry.key,
              startTime: entry.value.start,
              endTime: entry.value.end,
            ),
        ],
        absentDeductionType: _absentType,
        absentDeductionValue: _number(_absentValueController),
        minutePenaltyBasis: _penaltyBasis,
        delayDeductionPerMinute: _number(_delayController),
        earlyLeaveDeductionPerMinute: _number(_earlyLeaveController),
        gapDeductionPerMinute: _number(_gapController),
        allowedDelayMinutesPerDay: _int(_allowedDelayController),
        allowedEarlyLeaveMinutesPerDay: _int(_allowedEarlyLeaveController),
        allowedGapMinutesPerDay: _int(_allowedGapController),
        dailyRateDivisor: _int(_divisorController, fallback: 30),
        workHoursPerDay: _number(_workHoursController),
        // Empty means overtime is not paid on this shift at all — a different
        // statement from a rate of zero.
        overtimePayPerMinute: overtimeText.isEmpty
            ? null
            : double.tryParse(overtimeText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final impact = widget.impact;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.shift == null ? 'إضافة وردية' : 'تعديل الوردية',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),

              if (impact != null && !impact.isEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: glass.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.glass),
                  ),
                  child: Text(
                    'تعديل القواعد يؤثر على ${impact.employeeIds.length} موظف، '
                    'ولديهم حضور مسجّل من ${ApiTime.formatDate(impact.from!)} '
                    'حتى ${ApiTime.formatDate(impact.to!)}. '
                    'ستُسأل عن إعادة الحساب بعد الحفظ.',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.warning,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              AppTextFormField(
                controller: _nameController,
                hintText: 'اسم الوردية',
                prefixIcon: Icon(
                  Icons.schedule_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم مطلوب'
                    : null,
              ),

              const SizedBox(height: AppSpacing.lg),
              const _GroupLabel('أيام العمل'),
              for (final day in ApiDayOfWeek.values)
                _DayRow(
                  label: WeekDays.labelOf(day.value),
                  times: _days[day],
                  onToggle: (on) => _toggleDay(day, on),
                  onPickStart: () => _pickDayTime(day, isStart: true),
                  onPickEnd: () => _pickDayTime(day, isStart: false),
                ),
              if (_days.isEmpty)
                Text(
                  'اختر يوم عمل واحداً على الأقل',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.error,
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),
              const _GroupLabel('الغياب'),
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
                const SizedBox(height: AppSpacing.sm),
                AppTextFormField(
                  controller: _absentValueController,
                  hintText: _absentType == AbsentDeductionType.fixedAmount
                      ? 'المبلغ المخصوم عن يوم الغياب'
                      : 'عدد أضعاف الأجر اليومي',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (_) => null,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              const _GroupLabel('خصومات الدقائق'),
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
                    // The rates below stop mattering: the server works the
                    // per-minute figure out of the employee's own salary.
                    'ستُحتسب قيمة الدقيقة من راتب الموظف نفسه، ولن تُستخدم القيم أدناه',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              if (!_penaltyBasis.isDerived) ...[
                const SizedBox(height: AppSpacing.sm),
                _NumberField(
                  controller: _delayController,
                  label: 'خصم دقيقة التأخير',
                ),
                _NumberField(
                  controller: _earlyLeaveController,
                  label: 'خصم دقيقة الخروج المبكر',
                ),
                _NumberField(
                  controller: _gapController,
                  label: 'خصم دقيقة الانقطاع',
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              const _GroupLabel('السماح اليومي (بالدقائق)'),
              _NumberField(
                controller: _allowedDelayController,
                label: 'سماح التأخير',
                isInteger: true,
              ),
              _NumberField(
                controller: _allowedEarlyLeaveController,
                label: 'سماح الخروج المبكر',
                isInteger: true,
              ),
              _NumberField(
                controller: _allowedGapController,
                label: 'سماح الانقطاع',
                isInteger: true,
              ),

              const SizedBox(height: AppSpacing.lg),
              const _GroupLabel('الاحتساب'),
              _NumberField(
                controller: _divisorController,
                label: 'عدد أيام قسمة الراتب الشهري',
                isInteger: true,
              ),
              _NumberField(
                controller: _workHoursController,
                label: 'ساعات العمل اليومية',
              ),
              _NumberField(
                controller: _overtimeController,
                label: 'أجر دقيقة العمل الإضافي (اتركه فارغاً إن لم يُحتسب)',
              ),

              const SizedBox(height: AppSpacing.lg),
              CustomButtonWidget(
                buttonText: 'حفظ',
                onPressed: _days.isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.times,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final String label;

  /// Null means the day is not worked.
  final ({TimeOfDay? start, TimeOfDay? end})? times;

  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isOn = times != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Row(
              children: [
                Checkbox(
                  value: isOn,
                  onChanged: (value) => onToggle(value ?? false),
                ),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: isOn ? glass.onGlass : glass.onGlassMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isOn) ...[
            Expanded(
              child: TextButton(
                onPressed: onPickStart,
                child: Text(ApiTime.displayTime(times!.start)),
              ),
            ),
            Text('—', style: AppTextStyles.font12RegularHint),
            Expanded(
              child: TextButton(
                onPressed: onPickEnd,
                child: Text(ApiTime.displayTime(times!.end)),
              ),
            ),
          ] else
            Expanded(
              child: Text(
                'عطلة أسبوعية',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.isInteger = false,
  });

  final TextEditingController controller;
  final String label;
  final bool isInteger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppTextFormField(
        controller: controller,
        hintText: label,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
        validator: (_) => null,
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.font14MediumText.copyWith(
          color: context.glass.onGlass,
        ),
      ),
    );
  }
}
