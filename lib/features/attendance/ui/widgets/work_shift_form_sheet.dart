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

/// Draws a shift: which days, which hours, and how much slack each day allows.
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
  late final TextEditingController _allowedDelayController;
  late final TextEditingController _allowedEarlyLeaveController;
  late final TextEditingController _allowedGapController;
  late final TextEditingController _overtimeCapController;

  /// Whether a day's overtime is capped. Off sends a null cap — "unlimited" —
  /// which is not the same as a cap of zero.
  late bool _isOvertimeCapped;

  /// The week, editable in place. A day with no times is simply not worked —
  /// which is how a five-day shift is expressed.
  final Map<ApiDayOfWeek, ({TimeOfDay? start, TimeOfDay? end})> _days = {};

  @override
  void initState() {
    super.initState();
    final shift = widget.shift;

    _nameController = TextEditingController(text: shift?.name ?? '');
    _allowedDelayController = TextEditingController(
      text: '${shift?.allowedDelayMinutesPerDay ?? 0}',
    );
    _allowedEarlyLeaveController = TextEditingController(
      text: '${shift?.allowedEarlyLeaveMinutesPerDay ?? 0}',
    );
    _allowedGapController = TextEditingController(
      text: '${shift?.allowedGapMinutesPerDay ?? 0}',
    );
    _overtimeCapController = TextEditingController(
      text: shift?.maxOvertimeMinutesPerDay?.toString() ?? '',
    );
    _isOvertimeCapped = shift?.maxOvertimeMinutesPerDay != null;

    for (final day in shift?.days ?? const <WorkShiftDayModel>[]) {
      _days[day.dayOfWeek] = (start: day.startTime, end: day.endTime);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allowedDelayController.dispose();
    _allowedEarlyLeaveController.dispose();
    _allowedGapController.dispose();
    _overtimeCapController.dispose();
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

  int _int(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // The API refuses a shift with no days at all, and rightly: it would be a
    // rule that never applies to anybody.
    if (_days.isEmpty) return;

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
        allowedDelayMinutesPerDay: _int(_allowedDelayController),
        allowedEarlyLeaveMinutesPerDay: _int(_allowedEarlyLeaveController),
        allowedGapMinutesPerDay: _int(_allowedGapController),
        maxOvertimeMinutesPerDay: _isOvertimeCapped
            ? _int(_overtimeCapController)
            : null,
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
              const _GroupLabel('السماح اليومي (بالدقائق)'),
              _NumberField(
                controller: _allowedDelayController,
                label: 'سماح التأخير',
              ),
              _NumberField(
                controller: _allowedEarlyLeaveController,
                label: 'سماح الخروج المبكر',
              ),
              _NumberField(
                controller: _allowedGapController,
                label: 'سماح الانقطاع',
              ),

              const SizedBox(height: AppSpacing.lg),
              const _GroupLabel('العمل الإضافي'),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('غير محدود')),
                  ButtonSegment(value: true, label: Text('بحد أقصى')),
                ],
                selected: {_isOvertimeCapped},
                onSelectionChanged: (selection) =>
                    setState(() => _isOvertimeCapped = selection.first),
              ),
              if (_isOvertimeCapped) ...[
                const SizedBox(height: AppSpacing.sm),
                _NumberField(
                  controller: _overtimeCapController,
                  label: 'أقصى دقائق إضافي في اليوم',
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  // Where the money went: the rates moved to each employee's
                  // own salary, so nobody goes looking for them here.
                  'قيم الخصم وأجر الإضافي تُضبط من نظام راتب كل موظف',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
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
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppTextFormField(
        controller: controller,
        hintText: label,
        keyboardType: TextInputType.number,
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
