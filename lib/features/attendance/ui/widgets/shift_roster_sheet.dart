import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/attendance/data/models/employee_work_system_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:dental_lab_app/features/attendance/logic/work_shifts/work_shifts_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/work_shifts/work_shifts_state.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Who is on this shift, and putting more people on it.
///
/// Assigning does not overwrite anything: it **closes** whatever spell each
/// employee is currently on and opens a new one dated today. Somebody moved
/// from the morning shift to the evening one keeps a readable history of when
/// that happened, which is what payroll for a past month depends on.
Future<void> showShiftRosterSheet(
  BuildContext context, {
  required WorkShiftModel shift,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ShiftRosterCubit>()..load(shift)),
        BlocProvider(create: (_) => getIt<EmployeesCubit>()..getEmployees()),
      ],
      child: _ShiftRosterSheet(shift: shift),
    ),
  );
}

class _ShiftRosterSheet extends StatelessWidget {
  const _ShiftRosterSheet({required this.shift});

  final WorkShiftModel shift;

  Future<void> _addMembers(
    BuildContext context,
    List<EmployeeWorkSystemModel> current,
  ) async {
    final cubit = context.read<ShiftRosterCubit>();
    final employeesState = context.read<EmployeesCubit>().state;
    final employees = employeesState is EmployeesLoaded
        ? employeesState.employees
        : const [];

    final alreadyOn = {for (final member in current) member.employeeId};

    final picked = await showDialog<List<String>>(
      context: context,
      builder: (_) => _PickEmployeesDialog(
        employees: [
          for (final employee in employees)
            if (!alreadyOn.contains(employee.id))
              (id: employee.id, name: employee.fullName),
        ],
      ),
    );
    if (picked == null || picked.isEmpty) return;

    await cubit.assign(employeeIds: picked);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.attendance,
    );

    return BlocConsumer<ShiftRosterCubit, ShiftRosterState>(
      listenWhen: (previous, current) =>
          current is ShiftRosterActionSuccess ||
          current is ShiftRosterActionError,
      listener: (context, state) {
        switch (state) {
          case ShiftRosterActionSuccess(:final message):
            showToast(message: message, state: ToastState.success);
          case ShiftRosterActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! ShiftRosterActionSuccess &&
          current is! ShiftRosterActionError,
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shift.displayName,
                      style: AppTextStyles.font18MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ),
                  if (canEdit && state is ShiftRosterLoaded)
                    TextButton.icon(
                      onPressed: () => _addMembers(context, state.members),
                      icon: const Icon(Icons.person_add_alt, size: 16),
                      label: const Text('إضافة'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              switch (state) {
                ShiftRosterLoaded(:final members) =>
                  members.isEmpty
                      ? Text(
                          'لا يوجد موظفون على هذه الوردية',
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        )
                      : Column(
                          children: [
                            for (final member in members)
                              _MemberRow(
                                member: member,
                                onRemove: canEdit
                                    ? () => context
                                          .read<ShiftRosterCubit>()
                                          .removeFromShift(member.employeeId)
                                    : null,
                              ),
                          ],
                        ),
                ShiftRosterError(:final message) => Text(
                  message,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.error,
                  ),
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

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, this.onRemove});

  final EmployeeWorkSystemModel member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: glass.onGlassMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.employeeName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  member.periodLabel,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              // Not a deletion: it opens a spell with no shift, which is a
              // real arrangement and keeps the history intact.
              tooltip: 'إخراج من الوردية',
              icon: const Icon(Icons.logout, size: 18),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _PickEmployeesDialog extends StatefulWidget {
  const _PickEmployeesDialog({required this.employees});

  final List<({String id, String name})> employees;

  @override
  State<_PickEmployeesDialog> createState() => _PickEmployeesDialogState();
}

class _PickEmployeesDialogState extends State<_PickEmployeesDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة موظفين', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: widget.employees.isEmpty
            ? Center(
                child: Text(
                  'كل الموظفين معيّنون على هذه الوردية',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: context.glass.onGlassMuted,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: widget.employees.length,
                itemBuilder: (context, index) {
                  final employee = widget.employees[index];
                  return CheckboxListTile(
                    value: _selected.contains(employee.id),
                    title: Text(employee.name),
                    onChanged: (value) => setState(() {
                      if (value ?? false) {
                        _selected.add(employee.id);
                      } else {
                        _selected.remove(employee.id);
                      }
                    }),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.toList()),
          child: const Text('تعيين'),
        ),
      ],
    );
  }
}
