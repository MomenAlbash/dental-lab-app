import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/daily_attendance_model.dart';
import 'package:dental_lab_app/features/attendance/logic/daily_attendance/daily_attendance_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/daily_attendance/daily_attendance_state.dart';
import 'package:dental_lab_app/features/attendance/ui/widgets/attendance_day_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Everybody's day, one row per employee.
///
/// Every figure on the row is the server's arithmetic over that day's punches,
/// the employee's shift and any approved leave — this screen renders them and
/// computes none of it, which is also why editing anything here is followed by
/// a reload rather than a local adjustment.
class DailyAttendanceTab extends StatelessWidget {
  const DailyAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.attendance,
    );

    return BlocConsumer<DailyAttendanceCubit, DailyAttendanceState>(
      listenWhen: (previous, current) =>
          current is DailyAttendanceActionSuccess ||
          current is DailyAttendanceActionError,
      listener: (context, state) {
        switch (state) {
          case DailyAttendanceActionSuccess(:final message):
            showToast(message: message, state: ToastState.success);
          case DailyAttendanceActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! DailyAttendanceActionSuccess &&
          current is! DailyAttendanceActionError,
      builder: (context, state) {
        final cubit = context.read<DailyAttendanceCubit>();

        return Column(
          children: [
            _DayBar(date: cubit.date),
            if (state is DailyAttendanceLoaded) _Summary(state: state),
            Expanded(
              child: switch (state) {
                DailyAttendanceLoaded(:final rows) =>
                  rows.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          onRefresh: () => cubit.load(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            itemCount: rows.length,
                            itemBuilder: (context, index) => _AttendanceRow(
                              row: rows[index],
                              onOpen: () => showAttendanceDaySheet(
                                context,
                                row: rows[index],
                                date: cubit.date,
                                canEdit: canEdit,
                              ),
                            ),
                          ),
                        ),
                DailyAttendanceError(:final message) => Center(
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
                _ => const Center(
                  child: CustomCircleProgressIndiacatorWidget(),
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

/// The day being shown, with a step either side and a jump to any date.
class _DayBar extends StatelessWidget {
  const _DayBar({required this.date});

  final DateTime date;

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<DailyAttendanceCubit>();

    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(date.year - 3),
      // Tomorrow is allowed: a day the server marks `Future` is a legitimate
      // thing to look at when checking who is expected in.
      lastDate: DateTime.now().add(const Duration(days: 31)),
    );
    if (picked != null) await cubit.goToDay(picked);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cubit = context.read<DailyAttendanceCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'اليوم السابق',
            icon: const Icon(Icons.chevron_right),
            onPressed: cubit.previousDay,
          ),
          Expanded(
            child: InkWell(
              onTap: () => _pick(context),
              borderRadius: BorderRadius.circular(AppRadius.glass),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    Text(
                      ApiTime.formatDate(date),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font16MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                    Text(
                      WeekDays.labelOf(WeekDays.fromDateTime(date)),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'اليوم التالي',
            icon: const Icon(Icons.chevron_left),
            onPressed: cubit.nextDay,
          ),
        ],
      ),
    );
  }
}

/// How the day came out, at a glance.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final DailyAttendanceLoaded state;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final present = state.countWhere(
      (row) =>
          row.status == DailyAttendanceStatus.present ||
          row.status == DailyAttendanceStatus.late$,
    );
    final absent = state.countWhere(
      (row) => row.status == DailyAttendanceStatus.absent,
    );
    final onLeave = state.countWhere(
      (row) =>
          row.status == DailyAttendanceStatus.onLeave ||
          row.status == DailyAttendanceStatus.holiday,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Shown at zero rather than hidden: "nobody was absent" is the
              // best news this screen can carry, and it only reads if the
              // counter is there to say it.
              _Stat(label: 'حاضر', value: present, color: glass.success),
              _Stat(label: 'غائب', value: absent, color: glass.error),
              _Stat(label: 'إجازة/عطلة', value: onLeave, color: glass.info),
            ],
          ),
          if (state.touchesDraftSalary)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                // The payslip was generated before today's edits and will not
                // pick them up on its own.
                'بعض أيام هذه الفترة داخل مسودة كشف راتب — أعد توليد الرواتب بعد التعديل',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTextStyles.font20BoldText.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.row, required this.onOpen});

  final DailyAttendanceModel row;
  final VoidCallback onOpen;

  Color _statusColor(GlassTokens glass, BuildContext context) =>
      switch (row.status) {
        DailyAttendanceStatus.present => glass.success,
        DailyAttendanceStatus.late$ => glass.warning,
        DailyAttendanceStatus.absent => glass.error,
        DailyAttendanceStatus.onLeave ||
        DailyAttendanceStatus.holiday => glass.info,
        // Nothing was judged at all — grey, not red: the employee is not
        // being accused of anything.
        DailyAttendanceStatus.noWorkSystem ||
        DailyAttendanceStatus.future ||
        null => glass.onGlassMuted,
      };

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final statusColor = _statusColor(glass, context);
    final radius = BorderRadius.circular(AppRadius.glass);

    final marks = <String>[
      if (row.delayMinutes > 0) 'تأخير ${row.delayMinutes}د',
      if (row.earlyLeaveMinutes > 0) 'خروج مبكر ${row.earlyLeaveMinutes}د',
      if (row.gapMinutes > 0) 'انقطاع ${row.gapMinutes}د',
      if (row.overtimeMinutes > 0) 'إضافي ${row.overtimeMinutes}د',
      if (row.leaveMinutes > 0) 'إجازة ${row.leaveMinutes}د',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onOpen,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: glass.surfaceGradient,
              borderRadius: radius,
              border: Border.all(color: glass.strokeColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.employeeName ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font14MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                      Text(
                        marks.isEmpty
                            ? '${row.checkInLabel} — ${row.checkOutLabel}'
                            : marks.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: row.hasPenalty
                              ? glass.warning
                              : glass.onGlassMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  row.status?.label ?? '—',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
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
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: glass.onGlassMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد سجلات حضور في هذا اليوم',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'قد يكون اليوم عطلة، أو لم يُسجَّل أي موظف على نظام عمل بعد',
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
