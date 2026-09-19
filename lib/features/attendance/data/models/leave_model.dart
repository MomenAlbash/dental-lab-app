import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:flutter/material.dart';

/// One leave (`LeaveDto`) — requested, approved or refused.
class LeaveModel {
  const LeaveModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.startDate,
    this.endDate,
    this.durationType = LeaveDurationType.daily,
    this.startTime,
    this.endTime,
    this.reason,
    this.status,
    this.approvedByUserId,
    this.draftSalaryPeriodStart,
    this.draftSalaryPeriodEnd,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String employeeId;
  final String? employeeName;
  final DateTime? startDate;
  final DateTime? endDate;
  final LeaveDurationType durationType;

  /// The excused window on an hourly leave; null on a daily one.
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  final String? reason;
  final LeaveStatus? status;
  final String? approvedByUserId;

  /// Set when a day this leave touches already sits inside a **draft** salary
  /// statement — that statement was generated before the leave took effect and
  /// will not reflect it until payroll is regenerated.
  final DateTime? draftSalaryPeriodStart;
  final DateTime? draftSalaryPeriodEnd;

  final bool canDelete;
  final String? deleteMessage;

  bool get isPending => status?.isPending ?? false;

  bool get affectsDraftSalary => draftSalaryPeriodStart != null;

  /// `2026-03-01 → 2026-03-03`, or a single date when it is one day.
  String get periodLabel {
    final start = startDate;
    final end = endDate;
    if (start == null) return '—';
    if (end == null || _isSameDay(start, end)) return ApiTime.formatDate(start);
    return '${ApiTime.formatDate(start)} → ${ApiTime.formatDate(end)}';
  }

  /// The hours taken out of each day, on an hourly leave.
  String? get windowLabel => durationType.isHourly
      ? '${ApiTime.displayTime(startTime)} — ${ApiTime.displayTime(endTime)}'
      : null;

  /// How many days the leave spans, counting both ends.
  int get dayCount {
    final start = startDate;
    final end = endDate;
    if (start == null) return 0;
    if (end == null) return 1;
    return end.difference(start).inDays + 1;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      startDate: ApiTime.parseDate(json['startDate'] as String?),
      endDate: ApiTime.parseDate(json['endDate'] as String?),
      durationType:
          LeaveDurationType.fromValue(json['durationType'] as int?) ??
          LeaveDurationType.daily,
      startTime: ApiTime.parseTime(json['startTime'] as String?),
      endTime: ApiTime.parseTime(json['endTime'] as String?),
      reason: json['reason'] as String?,
      status: LeaveStatus.fromValue(json['status'] as int?),
      approvedByUserId: json['approvedByUserId'] as String?,
      draftSalaryPeriodStart: ApiTime.parseDate(
        json['draftSalaryPeriodStart'] as String?,
      ),
      draftSalaryPeriodEnd: ApiTime.parseDate(
        json['draftSalaryPeriodEnd'] as String?,
      ),
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}

/// `CreateLeaveRequest` — an administrator recording a leave for someone.
class CreateLeaveRequestModel {
  const CreateLeaveRequestModel({
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    this.durationType = LeaveDurationType.daily,
    this.startTime,
    this.endTime,
    this.reason,
    this.approve = false,
  });

  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final LeaveDurationType durationType;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? reason;

  /// Records it as already approved rather than pending.
  ///
  /// An admin entering a leave that has already happened is not waiting on
  /// their own decision — and without this, back-filling a leave would leave
  /// the absences it excuses standing until somebody went and pressed approve.
  final bool approve;

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'startDate': ApiTime.formatDate(startDate),
    'endDate': ApiTime.formatDate(endDate),
    'durationType': durationType.value,
    'startTime': durationType.isHourly && startTime != null
        ? ApiTime.formatTime(startTime!)
        : null,
    'endTime': durationType.isHourly && endTime != null
        ? ApiTime.formatTime(endTime!)
        : null,
    'reason': ?reason,
    'approve': approve,
  };
}

/// `UpdateLeaveRequest` / `RequestLeaveRequest` — the same body, minus the
/// employee (the self-service route takes it from the token, and an edit never
/// moves a leave to a different person).
class SaveLeaveRequestModel {
  const SaveLeaveRequestModel({
    required this.startDate,
    required this.endDate,
    this.durationType = LeaveDurationType.daily,
    this.startTime,
    this.endTime,
    this.reason,
  });

  final DateTime startDate;
  final DateTime endDate;
  final LeaveDurationType durationType;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'startDate': ApiTime.formatDate(startDate),
    'endDate': ApiTime.formatDate(endDate),
    'durationType': durationType.value,
    'startTime': durationType.isHourly && startTime != null
        ? ApiTime.formatTime(startTime!)
        : null,
    'endTime': durationType.isHourly && endTime != null
        ? ApiTime.formatTime(endTime!)
        : null,
    'reason': ?reason,
  };
}

/// One holiday (`HolidayDto`) — a day the lab, or some of it, does not work.
class HolidayModel {
  const HolidayModel({
    required this.id,
    this.laboratoryId,
    this.employeeId,
    this.employeeIds = const [],
    this.allEmployees = false,
    this.date,
    this.name,
    this.draftSalaryPeriodStart,
    this.draftSalaryPeriodEnd,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String? laboratoryId;

  /// The legacy single-employee shape; [employeeIds] is the current one.
  final String? employeeId;

  final List<String> employeeIds;

  /// A lab-wide closure rather than a few people's day off.
  final bool allEmployees;

  final DateTime? date;
  final String? name;

  /// Set when at least one affected employee already has a draft salary
  /// statement covering this date — it was generated before the holiday
  /// existed and will not account for it on its own.
  final DateTime? draftSalaryPeriodStart;
  final DateTime? draftSalaryPeriodEnd;

  final bool canDelete;
  final String? deleteMessage;

  bool get affectsDraftSalary => draftSalaryPeriodStart != null;

  /// How many people it covers, for the row's subtitle. Lab-wide holidays say
  /// so instead of counting.
  int get employeeCount =>
      employeeIds.isNotEmpty ? employeeIds.length : (employeeId == null ? 0 : 1);

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'] as String? ?? '',
      laboratoryId: json['laboratoryId'] as String?,
      employeeId: json['employeeId'] as String?,
      employeeIds: [
        for (final id in json['employeeIds'] as List<dynamic>? ?? const [])
          if (id is String) id,
      ],
      allEmployees: json['allEmployees'] as bool? ?? false,
      date: ApiTime.parseDate(json['date'] as String?),
      name: json['name'] as String?,
      draftSalaryPeriodStart: ApiTime.parseDate(
        json['draftSalaryPeriodStart'] as String?,
      ),
      draftSalaryPeriodEnd: ApiTime.parseDate(
        json['draftSalaryPeriodEnd'] as String?,
      ),
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}

/// `SaveHolidayRequest`.
class SaveHolidayRequestModel {
  const SaveHolidayRequestModel({
    required this.name,
    required this.date,
    this.employeeIds = const [],
    this.allEmployees = false,
  });

  final String name;
  final DateTime date;

  /// Ignored when [allEmployees] is set — a lab-wide closure needs no list,
  /// and sending one would only invite the two to disagree.
  final List<String> employeeIds;

  final bool allEmployees;

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': ApiTime.formatDate(date),
    'allEmployees': allEmployees,
    'employeeIds': allEmployees ? const <String>[] : employeeIds,
  };
}
