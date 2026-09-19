import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';

/// One span of a day and what it was (`AttendanceSessionDto`).
class AttendanceSessionModel {
  const AttendanceSessionModel({
    required this.id,
    this.sequenceNo = 0,
    this.type,
    this.from,
    this.to,
    this.leaveId,
    this.note,
  });

  final String id;
  final int sequenceNo;
  final AttendanceSegmentType? type;
  final DateTime? from;

  /// Null on a span still running — the employee is inside it right now.
  final DateTime? to;

  /// Which leave excused this span, on a leave segment.
  final String? leaveId;

  /// The leave's reason, on a leave segment.
  final String? note;

  int get minutes {
    final start = from;
    final end = to;
    if (start == null || end == null) return 0;
    return end.difference(start).inMinutes;
  }

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      id: json['id'] as String? ?? '',
      sequenceNo: json['sequenceNo'] as int? ?? 0,
      type: AttendanceSegmentType.fromValue(json['type'] as int?),
      from: DateTime.tryParse(json['from'] as String? ?? ''),
      to: DateTime.tryParse(json['to'] as String? ?? ''),
      leaveId: json['leaveId'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// One employee's day (`DailyAttendanceDto`).
///
/// Every figure here is **computed**, not entered: the server reads the day's
/// punches against the employee's shift and any approved leave. Which is why
/// editing a punch, a leave or a holiday has to be followed by a recalculation
/// — the read model does not update itself.
class DailyAttendanceModel {
  const DailyAttendanceModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.date,
    this.checkIn,
    this.checkOut,
    this.status,
    this.delayMinutes = 0,
    this.earlyLeaveMinutes = 0,
    this.workedMinutes = 0,
    this.gapMinutes = 0,
    this.leaveMinutes = 0,
    this.overtimeMinutes = 0,
    this.notes,
    this.hasWorkSystem = false,
    this.sessions = const [],
    this.draftSalaryPeriodStart,
    this.draftSalaryPeriodEnd,
  });

  final String id;
  final String employeeId;
  final String? employeeName;
  final DateTime? date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DailyAttendanceStatus? status;

  final int delayMinutes;
  final int earlyLeaveMinutes;
  final int workedMinutes;
  final int gapMinutes;

  /// Minutes of the expected shift excused by an approved leave — kept apart
  /// from the penalty totals, since an excused hour is not a late hour.
  final int leaveMinutes;

  final int overtimeMinutes;
  final String? notes;

  /// Whether a work system was in effect on this date.
  ///
  /// False beside a real status (they punched anyway) means the badge is true
  /// but there is nothing to measure their lateness against. False alongside
  /// [DailyAttendanceStatus.noWorkSystem] means the row was never computed at
  /// all — there was nothing safe to judge, present or absent.
  final bool hasWorkSystem;

  final List<AttendanceSessionModel> sessions;

  /// Set when this day already sits inside a **draft** salary statement.
  ///
  /// The statement was generated before this edit and will not pick it up on
  /// its own — so the screen has to offer regenerating it rather than leaving
  /// a payslip that quietly disagrees with the attendance behind it. Null
  /// means no statement covers the day, or the one that does is already
  /// approved/paid (in which case the edit would have been refused upstream).
  final DateTime? draftSalaryPeriodStart;
  final DateTime? draftSalaryPeriodEnd;

  bool get affectsDraftSalary => draftSalaryPeriodStart != null;

  /// Any penalty at all on this day — what the row highlights.
  bool get hasPenalty =>
      delayMinutes > 0 || earlyLeaveMinutes > 0 || gapMinutes > 0;

  /// `08:57` in the device's own zone — these are wall-clock moments to the
  /// person reading them, and a UTC figure beside a wall clock reads as a bug.
  static String _clock(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get checkInLabel => _clock(checkIn);

  String get checkOutLabel => _clock(checkOut);

  factory DailyAttendanceModel.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      date: ApiTime.parseDate(json['date'] as String?),
      checkIn: DateTime.tryParse(json['checkIn'] as String? ?? ''),
      checkOut: DateTime.tryParse(json['checkOut'] as String? ?? ''),
      status: DailyAttendanceStatus.fromValue(json['status'] as int?),
      delayMinutes: json['delayMinutes'] as int? ?? 0,
      earlyLeaveMinutes: json['earlyLeaveMinutes'] as int? ?? 0,
      workedMinutes: json['workedMinutes'] as int? ?? 0,
      gapMinutes: json['gapMinutes'] as int? ?? 0,
      leaveMinutes: json['leaveMinutes'] as int? ?? 0,
      overtimeMinutes: json['overtimeMinutes'] as int? ?? 0,
      notes: json['notes'] as String?,
      hasWorkSystem: json['hasWorkSystem'] as bool? ?? false,
      sessions: [
        for (final session in json['sessions'] as List<dynamic>? ?? const [])
          AttendanceSessionModel.fromJson(session as Map<String, dynamic>),
      ],
      draftSalaryPeriodStart: ApiTime.parseDate(
        json['draftSalaryPeriodStart'] as String?,
      ),
      draftSalaryPeriodEnd: ApiTime.parseDate(
        json['draftSalaryPeriodEnd'] as String?,
      ),
    );
  }
}

