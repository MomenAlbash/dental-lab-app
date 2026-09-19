/// What a day came out as (`DailyAttendanceStatus`).
///
/// Computed by the server from the punches, the employee's shift and any
/// approved leave — never stored as an opinion, which is why editing a punch
/// or a leave has to be followed by a recalculation before this means anything
/// again.
enum DailyAttendanceStatus {
  present(1, 'حاضر'),
  late$(2, 'متأخر'),
  absent(3, 'غائب'),
  onLeave(4, 'إجازة'),
  holiday(5, 'عطلة'),

  /// No work system was in effect that day, so there was nothing to judge the
  /// employee against — not the same as absent, and the row says so rather
  /// than accusing anyone.
  noWorkSystem(6, 'بلا نظام عمل'),

  /// A day that has not happened yet — drawn on the calendar as a placeholder
  /// rather than as an absence waiting to be excused.
  future(7, 'لاحقاً');

  const DailyAttendanceStatus(this.value, this.label);

  final int value;
  final String label;

  static DailyAttendanceStatus? fromValue(int? value) {
    for (final status in DailyAttendanceStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// What one span of a day's timeline was (`AttendanceSegmentType`).
///
/// A day is several of these, not one status: an employee can arrive late,
/// work, step out, come back and stay past closing, and the row's headline
/// status is only the loudest of them.
enum AttendanceSegmentType {
  work(1, 'عمل'),
  leave(2, 'إجازة'),
  delay(3, 'تأخير'),
  gap(4, 'انقطاع'),
  earlyLeave(5, 'خروج مبكر'),
  overtime(6, 'وقت إضافي'),
  absence(7, 'غياب');

  const AttendanceSegmentType(this.value, this.label);

  final int value;
  final String label;

  static AttendanceSegmentType? fromValue(int? value) {
    for (final type in AttendanceSegmentType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Whether a leave takes whole days or a window out of each day
/// (`LeaveDurationType`).
enum LeaveDurationType {
  daily(1, 'يوم كامل'),
  hourly(2, 'ساعات');

  const LeaveDurationType(this.value, this.label);

  final int value;
  final String label;

  bool get isHourly => this == LeaveDurationType.hourly;

  static LeaveDurationType? fromValue(int? value) {
    for (final type in LeaveDurationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Where a leave request stands (`LeaveStatus`).
enum LeaveStatus {
  pending(1, 'بانتظار القرار'),
  approved(2, 'مقبولة'),
  rejected(3, 'مرفوضة');

  const LeaveStatus(this.value, this.label);

  final int value;
  final String label;

  bool get isPending => this == LeaveStatus.pending;

  static LeaveStatus? fromValue(int? value) {
    for (final status in LeaveStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// How a day of absence is charged (`AbsentDeductionType`).
enum AbsentDeductionType {
  none(1, 'بلا خصم'),
  fixedAmount(2, 'مبلغ ثابت'),

  /// A multiple of the daily rate, itself the salary divided by the shift's
  /// own `dailyRateDivisor` — so a lab that counts a month as 26 working days
  /// charges a different day than one that counts 30.
  multiplierOfDailyRate(3, 'مضاعف الأجر اليومي');

  const AbsentDeductionType(this.value, this.label);

  final int value;
  final String label;

  static AbsentDeductionType? fromValue(int? value) {
    for (final type in AbsentDeductionType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Whether per-minute penalties are a flat figure or worked out from the
/// employee's own pay (`MinutePenaltyBasis`).
enum MinutePenaltyBasis {
  fixedAmount(1, 'مبلغ ثابت للدقيقة'),
  derivedFromSalary(2, 'محسوب من الراتب');

  const MinutePenaltyBasis(this.value, this.label);

  final int value;
  final String label;

  bool get isDerived => this == MinutePenaltyBasis.derivedFromSalary;

  static MinutePenaltyBasis? fromValue(int? value) {
    for (final basis in MinutePenaltyBasis.values) {
      if (basis.value == value) return basis;
    }
    return null;
  }
}

/// The API's `DayOfWeek`: 0–6 starting at Sunday (.NET's own numbering), which
/// is also how the week reads in Arabic.
///
/// Named apart from Dart's [DateTime.weekday], which runs 1–7 from Monday —
/// see `WeekDays.fromDateTime` for the conversion.
enum ApiDayOfWeek {
  sunday(0),
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6);

  const ApiDayOfWeek(this.value);

  final int value;

  static ApiDayOfWeek? fromValue(int? value) {
    for (final day in ApiDayOfWeek.values) {
      if (day.value == value) return day;
    }
    return null;
  }
}
