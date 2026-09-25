import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:flutter/material.dart';

/// One working day of a shift (`WorkShiftDayDto`).
///
/// Times are wall-clock, not instants: "09:00 to 17:00 on Tuesdays" carries no
/// date and no zone, so they are [TimeOfDay] rather than [DateTime] — parsing
/// them as timestamps would staple today's date and the device's offset onto a
/// rule that has neither.
class WorkShiftDayModel {
  const WorkShiftDayModel({
    this.id,
    required this.dayOfWeek,
    this.startTime,
    this.endTime,
  });

  final String? id;
  final ApiDayOfWeek dayOfWeek;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  String get dayLabel => WeekDays.labelOf(dayOfWeek.value);

  /// `09:00 — 17:00`, or a dash when either end is missing.
  String get rangeLabel =>
      '${ApiTime.displayTime(startTime)} — ${ApiTime.displayTime(endTime)}';

  /// How long the day is, in minutes. A shift that ends before it starts runs
  /// past midnight, so the span wraps rather than reading as negative.
  int get spanMinutes {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return 0;

    final minutes = ApiTime.minutesOf(end) - ApiTime.minutesOf(start);
    return minutes >= 0 ? minutes : minutes + 24 * 60;
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek.value,
    'startTime': startTime == null ? null : ApiTime.formatTime(startTime!),
    'endTime': endTime == null ? null : ApiTime.formatTime(endTime!),
  };

  factory WorkShiftDayModel.fromJson(Map<String, dynamic> json) {
    return WorkShiftDayModel(
      id: json['id'] as String?,
      dayOfWeek:
          ApiDayOfWeek.fromValue(json['dayOfWeek'] as int?) ??
          ApiDayOfWeek.sunday,
      startTime: ApiTime.parseTime(json['startTime'] as String?),
      endTime: ApiTime.parseTime(json['endTime'] as String?),
    );
  }
}

/// A work shift (`WorkShiftDto`) — the hours an employee is expected to keep.
///
/// **Schedule only, no money.** The shift holds the week and the grace minutes
/// before a delay, early leave or gap counts against the day; what any of that
/// costs lives on the employee's own salary spell. That split is why the same
/// shift can be shared by a technician and a driver on completely different
/// deduction rules.
class WorkShiftModel {
  const WorkShiftModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.days = const [],
    this.allowedGapMinutesPerDay = 0,
    this.allowedDelayMinutesPerDay = 0,
    this.allowedEarlyLeaveMinutesPerDay = 0,
    this.maxOvertimeMinutesPerDay,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String? laboratoryId;
  final String? name;
  final List<WorkShiftDayModel> days;

  /// Grace, in minutes per day, before the matching penalty starts counting.
  final int allowedGapMinutesPerDay;
  final int allowedDelayMinutesPerDay;
  final int allowedEarlyLeaveMinutesPerDay;

  /// The most overtime a day can count. Null means unlimited — different from
  /// zero, which is a shift where no overtime counts at all.
  final int? maxOvertimeMinutesPerDay;

  final bool canDelete;
  final String? deleteMessage;

  String get displayName => name?.trim().isNotEmpty ?? false ? name! : '—';

  bool get hasUnlimitedOvertime => maxOvertimeMinutesPerDay == null;

  /// The days worked, in week order, so the summary line never reads Friday
  /// before Monday because of how the rows came back.
  List<WorkShiftDayModel> get orderedDays =>
      [...days]..sort((a, b) => a.dayOfWeek.value.compareTo(b.dayOfWeek.value));

  factory WorkShiftModel.fromJson(Map<String, dynamic> json) {
    return WorkShiftModel(
      id: json['id'] as String? ?? '',
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      days: [
        for (final day in json['days'] as List<dynamic>? ?? const [])
          WorkShiftDayModel.fromJson(day as Map<String, dynamic>),
      ],
      allowedGapMinutesPerDay: json['allowedGapMinutesPerDay'] as int? ?? 0,
      allowedDelayMinutesPerDay: json['allowedDelayMinutesPerDay'] as int? ?? 0,
      allowedEarlyLeaveMinutesPerDay:
          json['allowedEarlyLeaveMinutesPerDay'] as int? ?? 0,
      maxOvertimeMinutesPerDay: json['maxOvertimeMinutesPerDay'] as int?,
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}

/// `SaveWorkShiftRequest` — create and update take the same shape.
class SaveWorkShiftRequestModel {
  const SaveWorkShiftRequestModel({
    required this.name,
    this.days = const [],
    this.allowedGapMinutesPerDay = 0,
    this.allowedDelayMinutesPerDay = 0,
    this.allowedEarlyLeaveMinutesPerDay = 0,
    this.maxOvertimeMinutesPerDay,
  });

  final String name;
  final List<WorkShiftDayModel> days;
  final int allowedGapMinutesPerDay;
  final int allowedDelayMinutesPerDay;
  final int allowedEarlyLeaveMinutesPerDay;
  final int? maxOvertimeMinutesPerDay;

  Map<String, dynamic> toJson() => {
    'name': name,
    'days': [for (final day in days) day.toJson()],
    'allowedGapMinutesPerDay': allowedGapMinutesPerDay,
    'allowedDelayMinutesPerDay': allowedDelayMinutesPerDay,
    'allowedEarlyLeaveMinutesPerDay': allowedEarlyLeaveMinutesPerDay,
    // Sent even when null: null is "unlimited", and an update that dropped the
    // key could not lift a cap that was set before.
    'maxOvertimeMinutesPerDay': maxOvertimeMinutesPerDay,
  };

  /// Seeds the editor from an existing shift.
  factory SaveWorkShiftRequestModel.from(WorkShiftModel shift) {
    return SaveWorkShiftRequestModel(
      name: shift.name ?? '',
      days: shift.days,
      allowedGapMinutesPerDay: shift.allowedGapMinutesPerDay,
      allowedDelayMinutesPerDay: shift.allowedDelayMinutesPerDay,
      allowedEarlyLeaveMinutesPerDay: shift.allowedEarlyLeaveMinutesPerDay,
      maxOvertimeMinutesPerDay: shift.maxOvertimeMinutesPerDay,
    );
  }
}

/// What editing a shift's rules would disturb (`WorkShiftAttendanceImpactDto`).
///
/// Read **before** saving: the employees on the shift and the span of their
/// existing attendance. Those days were judged against the old rules, so the
/// editor warns first and knows what range to recalculate afterwards. Empty
/// means nobody is on the shift, or nobody on it has any attendance yet —
/// "nothing to warn about".
class WorkShiftAttendanceImpactModel {
  const WorkShiftAttendanceImpactModel({
    this.employeeIds = const [],
    this.from,
    this.to,
  });

  final List<String> employeeIds;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty => employeeIds.isEmpty || from == null || to == null;

  factory WorkShiftAttendanceImpactModel.fromJson(Map<String, dynamic> json) {
    return WorkShiftAttendanceImpactModel(
      employeeIds: [
        for (final id in json['employeeIds'] as List<dynamic>? ?? const [])
          if (id is String) id,
      ],
      from: ApiTime.parseDate(json['from'] as String?),
      to: ApiTime.parseDate(json['to'] as String?),
    );
  }
}
