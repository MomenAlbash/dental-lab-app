/// What an employee's rate actually means (`PayType`).
///
/// Only [attendance] is judged against a shift's hours; the rest are paid on
/// output or on a share of something, which is why the attendance screens can
/// show a row with no lateness to measure and still be correct.
enum PayType {
  attendance(1, 'حسب الدوام'),
  pieceRate(2, 'حسب المراحل'),
  perTooth(3, 'بالسن'),
  weekly(4, 'أسبوعي'),
  scannerSessionRate(5, 'بجلسة السكانر'),
  salesPercentage(6, 'نسبة من المبيعات'),
  hourly(7, 'بالساعة');

  const PayType(this.value, this.label);

  final int value;
  final String label;

  static PayType? fromValue(int? value) {
    for (final type in PayType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// How often payroll runs for this employee (`PayPeriod`).
///
/// Each employee's own period decides the window payroll covers — there is no
/// caller-supplied date range anywhere in this module, only an anchor date the
/// server resolves against each person's period.
enum PayPeriod {
  monthly(1, 'شهري'),
  weekly(2, 'أسبوعي');

  const PayPeriod(this.value, this.label);

  final int value;
  final String label;

  static PayPeriod? fromValue(int? value) {
    for (final period in PayPeriod.values) {
      if (period.value == value) return period;
    }
    return null;
  }
}

/// Where a salary statement stands (`SalaryStatementStatus`).
enum SalaryStatementStatus {
  /// Still recomputable — and the only state that can be deleted.
  draft(1, 'مسودة'),

  /// Signed off. The days it covers are closed: a punch landing on one of
  /// them is refused rather than quietly changing an approved payslip.
  approved(2, 'معتمد'),

  paid(3, 'مدفوع');

  const SalaryStatementStatus(this.value, this.label);

  final int value;
  final String label;

  bool get isDraft => this == SalaryStatementStatus.draft;
  bool get isPaid => this == SalaryStatementStatus.paid;

  static SalaryStatementStatus? fromValue(int? value) {
    for (final status in SalaryStatementStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// A standing payroll adjustment (`SalaryExceptionKind`).
///
/// Two families in one enum: the first five **override** a measured figure for
/// the period (an employee excused their lateness, say), while the last two
/// move money directly. The difference decides whether [needsCurrency] — a
/// count of minutes has no currency, an amount does.
enum SalaryExceptionKind {
  absentDaysOverride(1, 'تعديل أيام الغياب'),
  delayMinutesOverride(2, 'تعديل دقائق التأخير'),
  earlyLeaveMinutesOverride(3, 'تعديل دقائق الخروج المبكر'),
  gapMinutesOverride(4, 'تعديل دقائق الانقطاع'),
  overtimeMinutesOverride(5, 'تعديل دقائق العمل الإضافي'),
  salaryIncrease(6, 'زيادة على الراتب'),
  salaryDecrease(7, 'خصم من الراتب');

  const SalaryExceptionKind(this.value, this.label);

  final int value;
  final String label;

  /// Only the two money kinds carry a currency; an override is a count.
  bool get needsCurrency =>
      this == SalaryExceptionKind.salaryIncrease ||
      this == SalaryExceptionKind.salaryDecrease;

  static SalaryExceptionKind? fromValue(int? value) {
    for (final kind in SalaryExceptionKind.values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}
