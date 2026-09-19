import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Records a leave on somebody's behalf.
///
/// Defaults to **already approved**: an administrator entering a leave that has
/// already happened is not waiting on their own decision, and without it the
/// absences those days already carry would stand until somebody went back and
/// pressed approve. Left unticked, it files an ordinary pending request.
Future<CreateLeaveRequestModel?> showLeaveFormSheet(BuildContext context) {
  return showGlassBottomSheet<CreateLeaveRequestModel>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<EmployeesCubit>()..getEmployees(),
      child: const _LeaveFormSheet(),
    ),
  );
}

class _LeaveFormSheet extends StatefulWidget {
  const _LeaveFormSheet();

  @override
  State<_LeaveFormSheet> createState() => _LeaveFormSheetState();
}

class _LeaveFormSheetState extends State<_LeaveFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _employeeId;
  DateTime _startDate = _today;
  DateTime _endDate = _today;
  LeaveDurationType _durationType = LeaveDurationType.daily;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _approve = true;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;

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
        // A range that ends before it starts is not a shape the server will
        // take, so the end follows the start rather than being left invalid.
        if (_endDate.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  bool get _isValid {
    if (_employeeId == null) return false;
    // An hourly leave with no window excuses nothing — the server rejects it,
    // and the button says so first.
    if (_durationType.isHourly && (_startTime == null || _endTime == null)) {
      return false;
    }
    return true;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isValid) return;

    final reason = _reasonController.text.trim();

    Navigator.of(context).pop(
      CreateLeaveRequestModel(
        employeeId: _employeeId!,
        startDate: _startDate,
        endDate: _endDate,
        durationType: _durationType,
        startTime: _startTime,
        endTime: _endTime,
        reason: reason.isEmpty ? null : reason,
        approve: _approve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

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
                'تسجيل إجازة',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              BlocBuilder<EmployeesCubit, EmployeesState>(
                builder: (context, state) {
                  final employees = state is EmployeesLoaded
                      ? state.employees
                      : const [];

                  return CaseLookupDropdown(
                    value: _employeeId,
                    icon: Icons.badge_outlined,
                    hintText: 'الموظف',
                    items: [
                      for (final employee in employees)
                        DropdownMenuItem(
                          value: employee.id,
                          child: Text(employee.fullName),
                        ),
                    ],
                    onChanged: (value) => setState(() => _employeeId = value),
                  );
                },
              ),
              if (_employeeId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'اختر الموظف',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.error,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),
              SegmentedButton<LeaveDurationType>(
                segments: [
                  for (final type in LeaveDurationType.values)
                    ButtonSegment(value: type, label: Text(type.label)),
                ],
                selected: {_durationType},
                onSelectionChanged: (selection) =>
                    setState(() => _durationType = selection.first),
              ),

              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      label: 'من تاريخ',
                      value: ApiTime.formatDate(_startDate),
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PickerTile(
                      label: 'إلى تاريخ',
                      value: ApiTime.formatDate(_endDate),
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),

              if (_durationType.isHourly) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        label: 'من الساعة',
                        value: ApiTime.displayTime(_startTime),
                        icon: Icons.schedule,
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _PickerTile(
                        label: 'إلى الساعة',
                        value: ApiTime.displayTime(_endTime),
                        icon: Icons.schedule,
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'هذه النافذة تُستقطع من كل يوم ضمن الفترة',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              AppTextFormField(
                controller: _reasonController,
                hintText: 'السبب (اختياري)',
                maxLines: 2,
                validator: (_) => null,
              ),

              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _approve,
                onChanged: (value) => setState(() => _approve = value),
                title: Text(
                  'تسجيلها كموافَق عليها',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                subtitle: Text(
                  'اتركها مفعّلة عند إدخال إجازة حصلت فعلاً، لتُحتسب مباشرة في الحضور',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              CustomButtonWidget(
                buttonText: 'حفظ',
                onPressed: _isValid ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.glass),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.glass),
          border: Border.all(color: glass.strokeColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: glass.onGlassMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
