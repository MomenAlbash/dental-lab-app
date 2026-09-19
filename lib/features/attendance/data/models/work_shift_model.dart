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

/// A work shift (`WorkShiftDto`) — the hours an employee is expected to keep,
/// and what it costs them when they don't.
///
/// The shift carries the **rules**, not the money: what an employee is paid
/// lives on their own salary-system spell. That split is why the same shift can
/// be shared by a technician and a driver on completely different pay.
class WorkShiftModel {
  const WorkShiftModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.days = const [],
    this.absentDeductionType = AbsentDeductionType.none,
    this.absentDeductionValue = 0,
    this.minutePenaltyBasis = MinutePenaltyBasis.fixedAmount,
    this.delayDeductionPerMinute = 0,
    this.earlyLeaveDeductionPerMinute = 0,
    this.gapDeductionPerMinute = 0,
    this.allowedGapMinutesPerDay = 0,
    this.allowedDelayMinutesPerDay = 0,
    this.allowedEarlyLeaveMinutesPerDay = 0,
    this.dailyRateDivisor = 30,
    this.workHoursPerDay = 8,
    this.overtimePayPerMinute,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String? laboratoryId;
  final String? name;
  final List<WorkShiftDayModel> days;

  final AbsentDeductionType absentDeductionType;
  final double absentDeductionValue;

  final MinutePenaltyBasis minutePenaltyBasis;
  final double delayDeductionPerMinute;
  final double earlyLeaveDeductionPerMinute;
  final double gapDeductionPerMinute;

  /// Grace, in minutes per day, before the matching penalty starts counting.
  final int allowedGapMinutesPerDay;
  final int allowedDelayMinutesPerDay;
  final int allowedEarlyLeaveMinutesPerDay;

  /// How many days a month's salary is divided into to get a daily rate — 26
  /// and 30 are both common, and they are not the same answer.
  final int dailyRateDivisor;

  final double workHoursPerDay;

  /// Null means overtime is not paid on this shift at all — different from a
  /// rate of zero, which is a lab that decided it is worth nothing.
  final double? overtimePayPerMinute;

  final bool canDelete;
  final String? deleteMessage;

  String get displayName => name?.trim().isNotEmpty ?? false ? name! : '—';

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
      absentDeductionType:
          AbsentDeductionType.fromValue(json['absentDeductionType'] as int?) ??
          AbsentDeductionType.none,
      absentDeductionValue:
          (json['absentDeductionValue'] as num?)?.toDouble() ?? 0,
      minutePenaltyBasis:
          MinutePenaltyBasis.fromValue(json['minutePenaltyBasis'] as int?) ??
          MinutePenaltyBasis.fixedAmount,
      delayDeductionPerMinute:
          (json['delayDeductionPerMinute'] as num?)?.toDouble() ?? 0,
      earlyLeaveDeductionPerMinute:
          (json['earlyLeaveDeductionPerMinute'] as num?)?.toDouble() ?? 0,
      gapDeductionPerMinute:
          (json['gapDeductionPerMinute'] as num?)?.toDouble() ?? 0,
      allowedGapMinutesPerDay: json['allowedGapMinutesPerDay'] as int? ?? 0,
      allowedDelayMinutesPerDay: json['allowedDelayMinutesPerDay'] as int? ?? 0,
      allowedEarlyLeaveMinutesPerDay:
          json['allowedEarlyLeaveMinutesPerDay'] as int? ?? 0,
      dailyRateDivisor: json['dailyRateDivisor'] as int? ?? 30,
      workHoursPerDay: (json['workHoursPerDay'] as num?)?.toDouble() ?? 8,
      overtimePayPerMinute: (json['overtimePayPerMinute'] as num?)?.toDouble(),
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
    this.absentDeductionType = AbsentDeductionType.none,
    this.absentDeductionValue = 0,
    this.minutePenaltyBasis = MinutePenaltyBasis.fixedAmount,
    this.delayDeductionPerMinute = 0,
    this.earlyLeaveDeductionPerMinute = 0,
    this.gapDeductionPerMinute = 0,
    this.allowedGapMinutesPerDay = 0,
    this.allowedDelayMinutesPerDay = 0,
    this.allowedEarlyLeaveMinutesPerDay = 0,
    this.dailyRateDivisor = 30,
    this.workHoursPerDay = 8,
    this.overtimePayPerMinute,
  });

  final String name;
  final List<WorkShiftDayModel> days;
  final AbsentDeductionType absentDeductionType;
  final double absentDeductionValue;
  final MinutePenaltyBasis minutePenaltyBasis;
  final double delayDeductionPerMinute;
  final double earlyLeaveDeductionPerMinute;
  final double gapDeductionPerMinute;
  final int allowedGapMinutesPerDay;
  final int allowedDelayMinutesPerDay;
  final int allowedEarlyLeaveMinutesPerDay;
  final int dailyRateDivisor;
  final double workHoursPerDay;
  final double? overtimePayPerMinute;

  Map<String, dynamic> toJson() => {
    'name': name,
    'days': [for (final day in days) day.toJson()],
    'absentDeductionType': absentDeductionType.value,
    'absentDeductionValue': absentDeductionValue,
    'minutePenaltyBasis': minutePenaltyBasis.value,
    'delayDeductionPerMinute': delayDeductionPerMinute,
    'earlyLeaveDeductionPerMinute': earlyLeaveDeductionPerMinute,
    'gapDeductionPerMinute': gapDeductionPerMinute,
    'allowedGapMinutesPerDay': allowedGapMinutesPerDay,
    'allowedDelayMinutesPerDay': allowedDelayMinutesPerDay,
    'allowedEarlyLeaveMinutesPerDay': allowedEarlyLeaveMinutesPerDay,
    'dailyRateDivisor': dailyRateDivisor,
    'workHoursPerDay': workHoursPerDay,
    'overtimePayPerMinute': overtimePayPerMinute,
  };

  /// Seeds the editor from an existing shift.
  factory SaveWorkShiftRequestModel.from(WorkShiftModel shift) {
    return SaveWorkShiftRequestModel(
      name: shift.name ?? '',
      days: shift.days,
      absentDeductionType: shift.absentDeductionType,
      absentDeductionValue: shift.absentDeductionValue,
      minutePenaltyBasis: shift.minutePenaltyBasis,
      delayDeductionPerMinute: shift.delayDeductionPerMinute,
      earlyLeaveDeductionPerMinute: shift.earlyLeaveDeductionPerMinute,
      gapDeductionPerMinute: shift.gapDeductionPerMinute,
      allowedGapMinutesPerDay: shift.allowedGapMinutesPerDay,
      allowedDelayMinutesPerDay: shift.allowedDelayMinutesPerDay,
      allowedEarlyLeaveMinutesPerDay: shift.allowedEarlyLeaveMinutesPerDay,
      dailyRateDivisor: shift.dailyRateDivisor,
      workHoursPerDay: shift.workHoursPerDay,
      overtimePayPerMinute: shift.overtimePayPerMinute,
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
