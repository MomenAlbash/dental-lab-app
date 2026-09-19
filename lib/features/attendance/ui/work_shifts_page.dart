import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:dental_lab_app/features/attendance/logic/work_shifts/work_shifts_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/work_shifts/work_shifts_state.dart';
import 'package:dental_lab_app/features/attendance/ui/widgets/shift_roster_sheet.dart';
import 'package:dental_lab_app/features/attendance/ui/widgets/work_shift_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The hours the laboratory expects, and what missing them costs.
///
/// A shift carries rules, not money: the same shift can be shared by people on
/// completely different pay, because what they earn lives on their own salary
/// spell. That split is why this screen never shows an amount owed — only
/// deduction rates.
class WorkShiftsPage extends StatelessWidget {
  const WorkShiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WorkShiftsCubit>()..load(),
      child: const _WorkShiftsView(),
    );
  }
}

class _WorkShiftsView extends StatelessWidget {
  const _WorkShiftsView();

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<WorkShiftsCubit>();

    final request = await showWorkShiftFormSheet(context);
    if (request == null) return;

    await cubit.create(request);
  }

  /// Editing a shift's rules re-judges nothing on its own — the days already
  /// on the books keep the verdicts they were given. So the editor asks the
  /// server what would be affected, warns, and offers to recompute afterwards.
  Future<void> _edit(BuildContext context, WorkShiftModel shift) async {
    final cubit = context.read<WorkShiftsCubit>();

    final impact = await cubit.peekAttendanceImpact(shift.id);
    if (!context.mounted) return;

    final request = await showWorkShiftFormSheet(
      context,
      shift: shift,
      impact: impact,
    );
    if (request == null || !context.mounted) return;

    await cubit.update(id: shift.id, body: request);

    if (impact != null && !impact.isEmpty) {
      if (!context.mounted) return;

      final recalculate = await ConfirmDialogWidget.show(
        context,
        title: 'إعادة حساب الحضور',
        message:
            'تم تعديل قواعد الوردية. الأيام المسجّلة سابقاً ما زالت محسوبة '
            'بالقواعد القديمة — هل تريد إعادة حسابها الآن '
            '(${impact.employeeIds.length} موظف)؟',
        confirmText: 'إعادة الحساب',
      );
      if (recalculate == true && context.mounted) {
        await cubit.recalculateAfterEdit(impact);
      }
    }
  }

  Future<void> _delete(BuildContext context, WorkShiftModel shift) async {
    final cubit = context.read<WorkShiftsCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الوردية',
      message: 'سيبقى الموظفون المعيّنون عليها بلا نظام عمل حتى تُسند وردية أخرى.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.delete(shift.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.attendance,
    );

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.workShiftsScreen),
      appBar: GlassAppBar(
        title: Text(
          'ورديات العمل',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'إضافة وردية',
              isExtended: true,
              onPressed: () => _create(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<WorkShiftsCubit, WorkShiftsState>(
          listenWhen: (previous, current) =>
              current is WorkShiftsActionSuccess ||
              current is WorkShiftsActionError,
          listener: (context, state) {
            switch (state) {
              case WorkShiftsActionSuccess(:final message):
                showToast(message: message, state: ToastState.success);
              case WorkShiftsActionError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! WorkShiftsActionSuccess &&
              current is! WorkShiftsActionError,
          builder: (context, state) => switch (state) {
            WorkShiftsLoaded(:final shifts) =>
              shifts.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: () => context.read<WorkShiftsCubit>().load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        itemCount: shifts.length,
                        itemBuilder: (context, index) => _ShiftCard(
                          shift: shifts[index],
                          onEdit: canEdit
                              ? () => _edit(context, shifts[index])
                              : null,
                          onDelete: canEdit
                              ? () => _delete(context, shifts[index])
                              : null,
                          onRoster: () =>
                              showShiftRosterSheet(context, shift: shifts[index]),
                        ),
                      ),
                    ),
            WorkShiftsError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ),
            ),
            _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
          },
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.shift,
    required this.onRoster,
    this.onEdit,
    this.onDelete,
  });

  final WorkShiftModel shift;
  final VoidCallback onRoster;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final days = shift.orderedDays;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shift.displayName,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'تعديل',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: shift.canDelete
                      ? 'حذف'
                      : (shift.deleteMessage ?? 'لا يمكن الحذف'),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: glass.error,
                  ),
                  onPressed: shift.canDelete ? onDelete : null,
                ),
            ],
          ),
          if (days.isEmpty)
            Text(
              'لم تُحدَّد أيام عمل لهذه الوردية',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 4,
              children: [
                for (final day in days)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '${day.dayLabel} ${day.rangeLabel}',
                      style: AppTextStyles.font12RegularHint,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              'الغياب: ${shift.absentDeductionType.label}',
              'سماح تأخير ${shift.allowedDelayMinutesPerDay}د',
              'قسمة اليوم على ${shift.dailyRateDivisor}',
              if (shift.overtimePayPerMinute == null)
                'بلا أجر إضافي'
              else
                'إضافي ${shift.overtimePayPerMinute}/د',
            ].join(' · '),
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onRoster,
              icon: const Icon(Icons.group_outlined, size: 16),
              label: const Text('الموظفون على الوردية'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined, size: 48, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد ورديات بعد',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Without a shift there is nothing to judge attendance against,
              // and every day comes back as "no work system".
              'بدون وردية لا يمكن احتساب التأخير أو الغياب لأي موظف',
              textAlign: TextAlign.center,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
