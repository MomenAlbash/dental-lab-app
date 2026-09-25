import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/payroll/data/models/payroll_enums.dart';

/// One spell of an employee's pay configuration (`EmployeeSalarySystemDto`).
///
/// A dated history, exactly like the shift assignment: a raise closes the old
/// spell and opens a new one, so a statement for last March is still computed
/// against March's rate rather than today's.
///
/// **All the money lives here** — the pay itself and what a minute of delay,
/// early leave, gap or a day's absence costs. The shift only holds the week
/// and the grace minutes those are judged against, which is why two people on
/// the same shift can be docked completely differently.
class EmployeeSalarySystemModel {
  const EmployeeSalarySystemModel({
    required this.id,
    required this.employeeId,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.payType,
    this.payPeriod,
    this.payRate = 0,
    this.currencyId,
    this.currencyCode,
    this.absentDeductionType = AbsentDeductionType.none,
    this.absentDeductionValue = 0,
    this.minutePenaltyBasis = MinutePenaltyBasis.fixedAmount,
    this.delayDeductionPerMinute = 0,
    this.earlyLeaveDeductionPerMinute = 0,
    this.gapDeductionPerMinute = 0,
    this.dailyRateDivisor = 30,
    this.workHoursPerDay = 8,
    this.overtimePayPerMinute,
    this.includeStagePay = false,
    this.note,
  });

  final String id;
  final String employeeId;
  final DateTime? startDate;

  /// Null on the open spell.
  final DateTime? endDate;

  final bool isActive;
  final PayType? payType;
  final PayPeriod? payPeriod;

  /// The figure itself — [payType] says what it means (a monthly salary, a
  /// price per tooth, a percentage).
  final double payRate;

  final String? currencyId;
  final String? currencyCode;

  final AbsentDeductionType absentDeductionType;
  final double absentDeductionValue;

  final MinutePenaltyBasis minutePenaltyBasis;
  final double delayDeductionPerMinute;
  final double earlyLeaveDeductionPerMinute;
  final double gapDeductionPerMinute;

  /// How many days a month's salary is divided into to get a daily rate — 26
  /// and 30 are both common, and they are not the same answer.
  final int dailyRateDivisor;

  final double workHoursPerDay;

  /// Null means overtime is not paid at all — different from a rate of zero,
  /// which is a lab that decided an extra minute is worth nothing.
  final double? overtimePayPerMinute;

  /// Stage earnings are added on top of this pay.
  final bool includeStagePay;

  final String? note;

  /// `1,200.00 USD`. The currency is never dropped: this app is multi-currency
  /// and a bare rate is ambiguous the moment two are in play.
  String get rateLabel =>
      '${payRate.toStringAsFixed(2)}${currencyCode == null ? '' : ' $currencyCode'}';

  String get periodLabel {
    final start = startDate == null ? '—' : ApiTime.formatDate(startDate!);
    final end = endDate == null ? 'حتى الآن' : ApiTime.formatDate(endDate!);
    return '$start — $end';
  }

  factory EmployeeSalarySystemModel.fromJson(Map<String, dynamic> json) {
    return EmployeeSalarySystemModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? false,
      payType: PayType.fromValue(json['payType'] as int?),
      payPeriod: PayPeriod.fromValue(json['payPeriod'] as int?),
      payRate: (json['payRate'] as num?)?.toDouble() ?? 0,
      currencyId: json['currencyId'] as String?,
      currencyCode: json['currencyCode'] as String?,
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
      dailyRateDivisor: json['dailyRateDivisor'] as int? ?? 30,
      workHoursPerDay: (json['workHoursPerDay'] as num?)?.toDouble() ?? 8,
      overtimePayPerMinute: (json['overtimePayPerMinute'] as num?)?.toDouble(),
      includeStagePay: json['includeStagePay'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}

/// `SaveEmployeeSalarySystemRequest` — opens a new pay spell.
class SaveEmployeeSalarySystemRequestModel {
  const SaveEmployeeSalarySystemRequestModel({
    required this.employeeId,
    required this.currencyId,
    this.payType = PayType.attendance,
    this.payPeriod = PayPeriod.monthly,
    this.payRate = 0,
    this.absentDeductionType = AbsentDeductionType.none,
    this.absentDeductionValue = 0,
    this.minutePenaltyBasis = MinutePenaltyBasis.fixedAmount,
    this.delayDeductionPerMinute = 0,
    this.earlyLeaveDeductionPerMinute = 0,
    this.gapDeductionPerMinute = 0,
    this.dailyRateDivisor = 30,
    this.workHoursPerDay = 8,
    this.overtimePayPerMinute,
    this.includeStagePay = false,
    this.note,
    this.startDate,
  });

  final String employeeId;
  final String currencyId;
  final PayType payType;
  final PayPeriod payPeriod;
  final double payRate;
  final AbsentDeductionType absentDeductionType;
  final double absentDeductionValue;
  final MinutePenaltyBasis minutePenaltyBasis;
  final double delayDeductionPerMinute;
  final double earlyLeaveDeductionPerMinute;
  final double gapDeductionPerMinute;
  final int dailyRateDivisor;
  final double workHoursPerDay;
  final double? overtimePayPerMinute;
  final bool includeStagePay;
  final String? note;

  /// Null dates it now; back-dating records an arrangement already in effect.
  final DateTime? startDate;

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'currencyId': currencyId,
    'payType': payType.value,
    'payPeriod': payPeriod.value,
    'payRate': payRate,
    'absentDeductionType': absentDeductionType.value,
    'absentDeductionValue': absentDeductionValue,
    'minutePenaltyBasis': minutePenaltyBasis.value,
    'delayDeductionPerMinute': delayDeductionPerMinute,
    'earlyLeaveDeductionPerMinute': earlyLeaveDeductionPerMinute,
    'gapDeductionPerMinute': gapDeductionPerMinute,
    'dailyRateDivisor': dailyRateDivisor,
    'workHoursPerDay': workHoursPerDay,
    // Sent even when null: null is "overtime is not paid", which a missing key
    // would leave to the server's default instead.
    'overtimePayPerMinute': overtimePayPerMinute,
    'includeStagePay': includeStagePay,
    'note': ?note,
    'startDate': ?startDate?.toIso8601String(),
  };
}

/// One generated payslip (`SalaryStatementDto`).
///
/// Every figure is the server's arithmetic over the period's attendance — the
/// app renders it and never recomputes any of it, which is also why editing a
/// day inside a draft period has to trigger a regeneration rather than a patch.
class SalaryStatementModel {
  const SalaryStatementModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.periodStart,
    this.periodEnd,
    this.payType,
    this.currency,
    this.grossAmount = 0,
    this.absentDays = 0,
    this.delayMinutesTotal = 0,
    this.earlyLeaveMinutesTotal = 0,
    this.gapMinutesTotal = 0,
    this.overtimeMinutesTotal = 0,
    this.absentDeduction = 0,
    this.delayDeduction = 0,
    this.earlyLeaveDeduction = 0,
    this.gapDeduction = 0,
    this.overtimePay = 0,
    this.exceptionAdjustmentTotal = 0,
    this.netAmount = 0,
    this.status,
    this.approvedByUserId,
    this.paidAt,
    this.notes,
    this.canDelete = false,
    this.deleteMessage,
  });

  final String id;
  final String employeeId;
  final String? employeeName;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final PayType? payType;
  final CurrencyModel? currency;

  final double grossAmount;

  final int absentDays;
  final int delayMinutesTotal;
  final int earlyLeaveMinutesTotal;
  final int gapMinutesTotal;
  final int overtimeMinutesTotal;

  final double absentDeduction;
  final double delayDeduction;
  final double earlyLeaveDeduction;
  final double gapDeduction;
  final double overtimePay;

  /// Net of any standing salary exceptions active during the period — one
  /// figure, since an increase and a decrease in the same month cancel out.
  final double exceptionAdjustmentTotal;

  final double netAmount;
  final SalaryStatementStatus? status;
  final String? approvedByUserId;
  final DateTime? paidAt;
  final String? notes;

  final bool canDelete;
  final String? deleteMessage;

  bool get isDraft => status?.isDraft ?? false;

  double get totalDeductions =>
      absentDeduction + delayDeduction + earlyLeaveDeduction + gapDeduction;

  /// Always with its currency code attached — see [EmployeeSalarySystemModel].
  String format(double amount) =>
      currency?.format(amount) ?? amount.toStringAsFixed(2);

  String get periodLabel {
    final start = periodStart == null ? '—' : ApiTime.formatDate(periodStart!);
    final end = periodEnd == null ? '—' : ApiTime.formatDate(periodEnd!);
    return '$start — $end';
  }

  factory SalaryStatementModel.fromJson(Map<String, dynamic> json) {
    return SalaryStatementModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      periodStart: ApiTime.parseDate(json['periodStart'] as String?),
      periodEnd: ApiTime.parseDate(json['periodEnd'] as String?),
      payType: PayType.fromValue(json['payType'] as int?),
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0,
      absentDays: json['absentDays'] as int? ?? 0,
      delayMinutesTotal: json['delayMinutesTotal'] as int? ?? 0,
      earlyLeaveMinutesTotal: json['earlyLeaveMinutesTotal'] as int? ?? 0,
      gapMinutesTotal: json['gapMinutesTotal'] as int? ?? 0,
      overtimeMinutesTotal: json['overtimeMinutesTotal'] as int? ?? 0,
      absentDeduction: (json['absentDeduction'] as num?)?.toDouble() ?? 0,
      delayDeduction: (json['delayDeduction'] as num?)?.toDouble() ?? 0,
      earlyLeaveDeduction:
          (json['earlyLeaveDeduction'] as num?)?.toDouble() ?? 0,
      gapDeduction: (json['gapDeduction'] as num?)?.toDouble() ?? 0,
      overtimePay: (json['overtimePay'] as num?)?.toDouble() ?? 0,
      exceptionAdjustmentTotal:
          (json['exceptionAdjustmentTotal'] as num?)?.toDouble() ?? 0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
      status: SalaryStatementStatus.fromValue(json['status'] as int?),
      approvedByUserId: json['approvedByUserId'] as String?,
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? ''),
      notes: json['notes'] as String?,
      canDelete: json['canDelete'] as bool? ?? false,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}

/// One employee's standing against the **current** period for their own pay
/// cycle (`PayrollCoverageEntryDto`) — "has payroll been run for them yet".
///
/// Distinct from a statement: this exists for employees who may not have one
/// at all, which is exactly the list somebody needs before running payroll.
class PayrollCoverageEntryModel {
  const PayrollCoverageEntryModel({
    required this.employeeId,
    this.employeeName,
    this.payPeriod,
    this.periodStart,
    this.periodEnd,
    this.hasStatement = false,
  });

  final String employeeId;
  final String? employeeName;
  final PayPeriod? payPeriod;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final bool hasStatement;

  String get periodLabel {
    final start = periodStart == null ? '—' : ApiTime.formatDate(periodStart!);
    final end = periodEnd == null ? '—' : ApiTime.formatDate(periodEnd!);
    return '$start — $end';
  }

  factory PayrollCoverageEntryModel.fromJson(Map<String, dynamic> json) {
    return PayrollCoverageEntryModel(
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      payPeriod: PayPeriod.fromValue(json['payPeriod'] as int?),
      periodStart: ApiTime.parseDate(json['periodStart'] as String?),
      periodEnd: ApiTime.parseDate(json['periodEnd'] as String?),
      hasStatement: json['hasStatement'] as bool? ?? false,
    );
  }
}

/// `GeneratePayrollRequest`.
///
/// There is no date *range*: payroll always runs for whatever standard period
/// each employee's own cycle resolves to around [anchorDate], so a weekly and
/// a monthly employee generated together get different windows from one call.
class GeneratePayrollRequestModel {
  const GeneratePayrollRequestModel({
    required this.anchorDate,
    this.employeeIds,
  });

  final DateTime anchorDate;

  /// Null means every employee with an active salary system in this lab.
  final List<String>? employeeIds;

  Map<String, dynamic> toJson() => {
    'anchorDate': ApiTime.formatDate(anchorDate),
    'employeeIds': employeeIds,
  };
}

/// A standing payroll adjustment (`SalaryExceptionDto`).
class SalaryExceptionModel {
  const SalaryExceptionModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.kind,
    this.value = 0,
    this.currencyId,
    this.currency,
    this.startDate,
    this.endDate,
    this.reason,
    this.createdAt,
    this.isActive = true,
    this.salaryStatementId,
  });

  final String id;
  final String employeeId;
  final String? employeeName;
  final SalaryExceptionKind? kind;

  /// A count of days/minutes on an override kind, an amount on the two money
  /// kinds — [kind] is what says which.
  final double value;

  final String? currencyId;
  final CurrencyModel? currency;

  final DateTime? startDate;

  /// Null means standing until somebody deactivates it — how an open-ended
  /// raise or cut is expressed.
  final DateTime? endDate;

  final String? reason;
  final DateTime? createdAt;
  final bool isActive;

  /// Set once payroll has actually folded this into a statement — only ever
  /// on a bounded exception, never a standing one. Lets the row say "already
  /// settled" instead of leaving that silent.
  final String? salaryStatementId;

  bool get isStanding => endDate == null;
  bool get isSettled => salaryStatementId != null;

  /// The value with its unit: money carries a currency, an override does not.
  String get valueLabel {
    if (kind?.needsCurrency ?? false) {
      return currency?.format(value) ?? value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(0);
  }

  factory SalaryExceptionModel.fromJson(Map<String, dynamic> json) {
    return SalaryExceptionModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      kind: SalaryExceptionKind.fromValue(json['kind'] as int?),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      currencyId: json['currencyId'] as String?,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      startDate: ApiTime.parseDate(json['startDate'] as String?),
      endDate: ApiTime.parseDate(json['endDate'] as String?),
      reason: json['reason'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? true,
      salaryStatementId: json['salaryStatementId'] as String?,
    );
  }
}

/// `SaveSalaryExceptionRequest`.
class SaveSalaryExceptionRequestModel {
  const SaveSalaryExceptionRequestModel({
    required this.employeeId,
    required this.kind,
    required this.value,
    required this.startDate,
    required this.reason,
    this.currencyId,
    this.endDate,
  });

  final String employeeId;
  final SalaryExceptionKind kind;
  final double value;
  final DateTime startDate;

  /// A reason is required by the API, and rightly: an adjustment nobody can
  /// account for later is the one thing payroll cannot afford.
  final String reason;

  final String? currencyId;

  /// Null = standing until deactivated.
  final DateTime? endDate;

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'kind': kind.value,
    'value': value,
    'currencyId': kind.needsCurrency ? currencyId : null,
    'startDate': ApiTime.formatDate(startDate),
    'endDate': endDate == null ? null : ApiTime.formatDate(endDate!),
    'reason': reason,
  };
}
