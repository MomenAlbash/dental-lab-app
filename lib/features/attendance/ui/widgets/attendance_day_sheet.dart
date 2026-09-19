import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/daily_attendance_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/punch_model.dart';
import 'package:dental_lab_app/features/attendance/data/repos/attendance_repo.dart';
import 'package:dental_lab_app/features/attendance/logic/daily_attendance/daily_attendance_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One employee's day in full: the spans the server derived, and the raw
/// punches underneath them.
///
/// The two are not the same thing and the sheet keeps them apart. A *session*
/// is a computed in/out span — read-only, because it is a consequence. A
/// *punch* is the stamp itself, and that is what can be added, moved or
/// removed; the sessions above redraw themselves when it is.
Future<void> showAttendanceDaySheet(
  BuildContext context, {
  required DailyAttendanceModel row,
  required DateTime date,
  required bool canEdit,
}) {
  final cubit = context.read<DailyAttendanceCubit>();

  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _AttendanceDaySheet(row: row, date: date, canEdit: canEdit),
    ),
  );
}

class _AttendanceDaySheet extends StatefulWidget {
  const _AttendanceDaySheet({
    required this.row,
    required this.date,
    required this.canEdit,
  });

  final DailyAttendanceModel row;
  final DateTime date;
  final bool canEdit;

  @override
  State<_AttendanceDaySheet> createState() => _AttendanceDaySheetState();
}

class _AttendanceDaySheetState extends State<_AttendanceDaySheet> {
  List<PunchModel>? _punches;

  @override
  void initState() {
    super.initState();
    _loadPunches();
  }

  /// The punches are their own read: the day row carries the *derived*
  /// sessions, and nothing in it names the individual stamps an edit targets.
  Future<void> _loadPunches() async {
    final result = await getIt<AttendanceRepo>().getPunchesForDay(
      employeeId: widget.row.employeeId,
      date: widget.date,
    );
    if (!mounted) return;

    setState(() {
      _punches = result.fold((_) => const [], (punches) => punches);
    });
  }

  /// Pins a wall-clock time onto the day being shown — a punch belongs to the
  /// date the sheet is open on, not to today.
  DateTime _onThisDay(TimeOfDay time) => DateTime(
    widget.date.year,
    widget.date.month,
    widget.date.day,
    time.hour,
    time.minute,
  );

  Future<void> _addPunch() async {
    final cubit = context.read<DailyAttendanceCubit>();

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    await cubit.addManualPunch(
      employeeId: widget.row.employeeId,
      timestamp: _onThisDay(time),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _editPunch(PunchModel punch) async {
    final cubit = context.read<DailyAttendanceCubit>();
    final current = punch.timestamp?.toLocal();

    final time = await showTimePicker(
      context: context,
      initialTime: current == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time == null) return;

    await cubit.updatePunch(id: punch.id, timestamp: _onThisDay(time));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deletePunch(PunchModel punch) async {
    final cubit = context.read<DailyAttendanceCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف البصمة',
      message:
          'سيُعاد حساب اليوم بدون هذه البصمة، وقد يتغيّر حالة الحضور والخصومات.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.deletePunch(punch.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _recalculate() async {
    final cubit = context.read<DailyAttendanceCubit>();
    await cubit.recalculate(widget.row.employeeId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final row = widget.row;
    final punches = _punches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            row.employeeName ?? '—',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          Text(
            '${ApiTime.formatDate(widget.date)} · ${row.status?.label ?? '—'}',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),

          if (!row.hasWorkSystem) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              // Not an accusation: without a shift there is nothing to judge
              // arrival or departure against, and the row says so plainly.
              'لا يوجد نظام عمل فعّال لهذا الموظف في هذا التاريخ — لا يمكن قياس التأخير أو الغياب',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            ),
          ],

          if (row.affectsDraftSalary) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'هذا اليوم ضمن مسودة كشف راتب — أعد توليد الرواتب بعد أي تعديل',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          _Totals(row: row),

          if (row.sessions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const _GroupLabel('مسار اليوم'),
            for (final session in row.sessions)
              _SessionRow(session: session),
          ],

          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(child: _GroupLabel('البصمات')),
              if (widget.canEdit)
                TextButton.icon(
                  onPressed: _addPunch,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('إضافة بصمة'),
                ),
            ],
          ),
          if (punches == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (punches.isEmpty)
            Text(
              'لا توجد بصمات مسجّلة في هذا اليوم',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          else
            for (final punch in punches)
              _PunchRow(
                punch: punch,
                onEdit: widget.canEdit ? () => _editPunch(punch) : null,
                onDelete: widget.canEdit ? () => _deletePunch(punch) : null,
              ),

          if (widget.canEdit) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _recalculate,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة حساب اليوم'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                // The read model is a cache of an answer: a shift edited
                // yesterday or a leave approved this morning leaves days
                // standing that were judged under the old facts.
                'استخدمها بعد تعديل الوردية أو الإجازات ليُحتسب اليوم من جديد',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.row});

  final DailyAttendanceModel row;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final entries = <({String label, String value, Color color})>[
      (label: 'الدخول', value: row.checkInLabel, color: glass.onGlass),
      (label: 'الخروج', value: row.checkOutLabel, color: glass.onGlass),
      (
        label: 'ساعات العمل',
        value: _hours(row.workedMinutes),
        color: glass.success,
      ),
      if (row.delayMinutes > 0)
        (
          label: 'تأخير',
          value: '${row.delayMinutes} د',
          color: glass.warning,
        ),
      if (row.earlyLeaveMinutes > 0)
        (
          label: 'خروج مبكر',
          value: '${row.earlyLeaveMinutes} د',
          color: glass.warning,
        ),
      if (row.gapMinutes > 0)
        (label: 'انقطاع', value: '${row.gapMinutes} د', color: glass.warning),
      if (row.overtimeMinutes > 0)
        (
          label: 'إضافي',
          value: '${row.overtimeMinutes} د',
          color: glass.info,
        ),
      if (row.leaveMinutes > 0)
        (
          label: 'إجازة',
          value: '${row.leaveMinutes} د',
          color: glass.info,
        ),
    ];

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.label,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              Text(
                entry.value,
                style: AppTextStyles.font14MediumText.copyWith(
                  color: entry.color,
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// `7:30` — hours and minutes, not a raw minute count nobody reads at a
  /// glance.
  static String _hours(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '$hours:${rest.toString().padLeft(2, '0')}';
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final AttendanceSessionModel session;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final color = switch (session.type) {
      AttendanceSegmentType.work => glass.success,
      AttendanceSegmentType.overtime => glass.info,
      AttendanceSegmentType.leave => glass.info,
      AttendanceSegmentType.delay ||
      AttendanceSegmentType.gap ||
      AttendanceSegmentType.earlyLeave => glass.warning,
      AttendanceSegmentType.absence => glass.error,
      null => glass.onGlassMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              session.type?.label ?? '—',
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
          Text(
            '${_clock(session.from)} — ${_clock(session.to)}',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }

  static String _clock(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _PunchRow extends StatelessWidget {
  const _PunchRow({required this.punch, this.onEdit, this.onDelete});

  final PunchModel punch;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            punch.isManual ? Icons.edit_note : Icons.fingerprint,
            size: 18,
            color: glass.onGlassMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              punch.timeLabel,
              style: AppTextStyles.font14MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
          if (punch.isManual)
            Text(
              'يدوية',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          if (onEdit != null)
            IconButton(
              tooltip: 'تعديل الوقت',
              icon: const Icon(Icons.schedule, size: 18),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'حذف البصمة',
              icon: Icon(Icons.delete_outline, size: 18, color: glass.error),
              onPressed: onDelete,
            ),
        ],
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
