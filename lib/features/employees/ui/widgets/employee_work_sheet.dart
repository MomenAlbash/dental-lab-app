import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/attendance/data/models/fingerprint_device_model.dart';
import 'package:dental_lab_app/features/employees/logic/employee_work/employee_work_cubit.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_salary_dialog.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// How one employee works and is paid: their shift, their rate, the standing
/// adjustments on them, and the terminal codes they punch on.
///
/// The first two are **dated histories**, not fields. Assigning either closes
/// the running spell and opens a new one, so a payslip for a past month is
/// still computed against the arrangement that applied then — which is why
/// this shows a list with one marked row rather than a dropdown that forgets.
Future<void> showEmployeeWorkSheet(
  BuildContext context, {
  required String employeeId,
  required String employeeName,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<EmployeeWorkCubit>()..load(employeeId),
      child: _EmployeeWorkSheet(employeeName: employeeName),
    ),
  );
}

class _EmployeeWorkSheet extends StatelessWidget {
  const _EmployeeWorkSheet({required this.employeeName});

  final String employeeName;

  Future<void> _assignShift(
    BuildContext context,
    EmployeeWorkLoaded state,
  ) async {
    final cubit = context.read<EmployeeWorkCubit>();

    final picked = await showDialog<String?>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('تعيين وردية', style: AppTextStyles.font18MediumText),
        children: [
          for (final shift in state.shifts)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(shift.id),
              child: Text(shift.displayName),
            ),
          const Divider(),
          SimpleDialogOption(
            // Null is a real arrangement — a day labourer, somebody on call —
            // not a way of cancelling the dialog.
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('بلا وردية'),
          ),
        ],
      ),
    );
    if (picked == null) return;

    await cubit.assignShift(picked.isEmpty ? null : picked);
  }

  Future<void> _saveSalary(
    BuildContext context,
    EmployeeWorkLoaded state,
  ) async {
    final cubit = context.read<EmployeeWorkCubit>();

    final request = await showEmployeeSalaryDialog(
      context,
      employeeId: _employeeIdOf(state),
      current: state.activeSalary,
    );
    if (request == null) return;

    await cubit.saveSalary(request);
  }

  Future<void> _addException(
    BuildContext context,
    EmployeeWorkLoaded state,
  ) async {
    final cubit = context.read<EmployeeWorkCubit>();

    final request = await showSalaryExceptionDialog(
      context,
      employeeId: _employeeIdOf(state),
    );
    if (request == null) return;

    await cubit.addException(request);
  }

  Future<void> _deactivate(
    BuildContext context,
    SalaryExceptionModel exception,
  ) async {
    final cubit = context.read<EmployeeWorkCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'إلغاء تفعيل الاستثناء',
      message:
          'لن يُطبَّق على كشوف الرواتب القادمة، ويبقى مسجّلاً في السجل.',
      confirmText: 'إلغاء التفعيل',
    );
    if (confirmed != true) return;

    await cubit.deactivateException(exception.id);
  }

  Future<void> _deleteEnrollment(
    BuildContext context,
    FingerprintEnrollmentModel enrollment,
  ) async {
    final cubit = context.read<EmployeeWorkCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'إلغاء ربط البصمة',
      message: enrollment.punchCount > 0
          // The count is the point: past attendance stores the resolved
          // employee, so it survives — but somebody deleting a code with
          // history behind it should know that history exists.
          ? 'على هذا الرقم ${enrollment.punchCount} بصمة مسجّلة. '
                'الحضور السابق يبقى كما هو، لكن لن تُسجَّل بصمات جديدة عليه.'
          : 'لن تُسجَّل بصمات جديدة على هذا الرقم.',
      confirmText: 'إلغاء الربط',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.deleteEnrollment(enrollment.id);
  }

  /// The employee whose sheet this is, taken from any row that names them —
  /// the cubit holds it, but the dialogs need it up front.
  String _employeeIdOf(EmployeeWorkLoaded state) {
    for (final spell in state.shiftHistory) {
      if (spell.employeeId.isNotEmpty) return spell.employeeId;
    }
    for (final spell in state.salaryHistory) {
      if (spell.employeeId.isNotEmpty) return spell.employeeId;
    }
    for (final exception in state.exceptions) {
      if (exception.employeeId.isNotEmpty) return exception.employeeId;
    }
    for (final enrollment in state.enrollments) {
      if (enrollment.employeeId.isNotEmpty) return enrollment.employeeId;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final permissions = getIt<SessionCubit>().state;
    final canEditAttendance = permissions.canEdit(PermissionName.attendance);
    final canEditPayroll = permissions.canEdit(PermissionName.payroll);

    return BlocConsumer<EmployeeWorkCubit, EmployeeWorkState>(
      listenWhen: (previous, current) =>
          current is EmployeeWorkActionSuccess ||
          current is EmployeeWorkActionError,
      listener: (context, state) {
        switch (state) {
          case EmployeeWorkActionSuccess(:final message):
            showToast(message: message, state: ToastState.success);
          case EmployeeWorkActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! EmployeeWorkActionSuccess &&
          current is! EmployeeWorkActionError,
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الدوام والراتب',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              Text(
                employeeName,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              switch (state) {
                EmployeeWorkError(:final message) => Text(
                  message,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.error,
                  ),
                ),
                final EmployeeWorkLoaded loaded => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      title: 'الوردية',
                      onAdd: canEditAttendance
                          ? () => _assignShift(context, loaded)
                          : null,
                      addLabel: 'تعيين',
                      emptyText: 'لم تُسند وردية لهذا الموظف بعد',
                      children: [
                        for (final spell in loaded.shiftHistory)
                          _SpellRow(
                            title: spell.shiftLabel,
                            subtitle: spell.periodLabel,
                            note: spell.note,
                            isActive: spell.isActive,
                          ),
                      ],
                    ),

                    _Section(
                      title: 'نظام الراتب',
                      onAdd: canEditPayroll
                          ? () => _saveSalary(context, loaded)
                          : null,
                      addLabel: 'تعديل',
                      emptyText: 'لم يُحدَّد نظام راتب لهذا الموظف بعد',
                      children: [
                        for (final spell in loaded.salaryHistory)
                          _SpellRow(
                            title: [
                              spell.rateLabel,
                              if (spell.payType != null) spell.payType!.label,
                              if (spell.payPeriod != null)
                                spell.payPeriod!.label,
                            ].join(' · '),
                            subtitle: spell.periodLabel,
                            note: spell.note,
                            isActive: spell.isActive,
                          ),
                      ],
                    ),

                    _Section(
                      title: 'استثناءات الراتب',
                      onAdd: canEditPayroll
                          ? () => _addException(context, loaded)
                          : null,
                      addLabel: 'إضافة',
                      emptyText: 'لا توجد استثناءات على راتب هذا الموظف',
                      children: [
                        for (final exception in loaded.exceptions)
                          _ExceptionRow(
                            exception: exception,
                            onDeactivate: canEditPayroll && exception.isActive
                                ? () => _deactivate(context, exception)
                                : null,
                          ),
                      ],
                    ),

                    _Section(
                      title: 'أرقام البصمة',
                      emptyText: 'لم يُربط هذا الموظف بأي جهاز بصمة',
                      children: [
                        for (final enrollment in loaded.enrollments)
                          _EnrollmentRow(
                            enrollment: enrollment,
                            onDelete: canEditAttendance
                                ? () => _deleteEnrollment(context, enrollment)
                                : null,
                          ),
                      ],
                    ),
                  ],
                ),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
    required this.emptyText,
    this.onAdd,
    this.addLabel = 'إضافة',
  });

  final String title;
  final List<Widget> children;
  final String emptyText;
  final VoidCallback? onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              if (onAdd != null)
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(addLabel),
                ),
            ],
          ),
          if (children.isEmpty)
            Text(
              emptyText,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

/// One dated spell — the active one outlined rather than merely first, since
/// a history read top-down has no other way to say which is in force.
class _SpellRow extends StatelessWidget {
  const _SpellRow({
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.note,
  });

  final String title;
  final String subtitle;
  final bool isActive;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(
          color: isActive ? accent : glass.strokeColor,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                if (note?.trim().isNotEmpty ?? false)
                  Text(
                    note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'الحالي',
                style: AppTextStyles.font12RegularHint.copyWith(color: accent),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExceptionRow extends StatelessWidget {
  const _ExceptionRow({required this.exception, this.onDeactivate});

  final SalaryExceptionModel exception;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${exception.kind?.label ?? '—'} · ${exception.valueLabel}',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: exception.isActive
                        ? glass.onGlass
                        : glass.onGlassMuted,
                  ),
                ),
                Text(
                  [
                    if (exception.startDate != null)
                      ApiTime.formatDate(exception.startDate!),
                    // A standing exception has no end — worth saying, since
                    // it keeps applying until somebody stops it.
                    if (exception.isStanding)
                      'مستمر'
                    else if (exception.endDate != null)
                      ApiTime.formatDate(exception.endDate!),
                    if (!exception.isActive) 'غير مفعّل',
                    if (exception.isSettled) 'احتُسب في كشف سابق',
                  ].join(' · '),
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                if (exception.reason?.trim().isNotEmpty ?? false)
                  Text(
                    exception.reason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (onDeactivate != null)
            IconButton(
              tooltip: 'إلغاء التفعيل',
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              onPressed: onDeactivate,
            ),
        ],
      ),
    );
  }
}

class _EnrollmentRow extends StatelessWidget {
  const _EnrollmentRow({required this.enrollment, this.onDelete});

  final FingerprintEnrollmentModel enrollment;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.fingerprint, size: 18, color: glass.onGlassMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrollment.deviceUserId ?? '—',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  [
                    if (enrollment.deviceName?.trim().isNotEmpty ?? false)
                      enrollment.deviceName!,
                    '${enrollment.punchCount} بصمة',
                  ].join(' · '),
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'إلغاء الربط',
              icon: Icon(Icons.link_off, size: 18, color: glass.error),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
