import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';

/// One priority's allowance for one doctor, this month
/// (`ClinicPriorityQuotaLineDto`).
class PriorityQuotaLineModel {
  const PriorityQuotaLineModel({
    required this.priorityId,
    this.priorityName,
    this.priorityNameAr,
    this.isUnlimited = false,
    this.freePerMonth = 0,
    this.bonusFree = 0,
    this.usedThisMonth = 0,
    this.remainingFree = 0,
    this.surcharge = 0,
    this.currency,
    this.isOverridden = false,
  });

  final String priorityId;
  final String? priorityName;
  final String? priorityNameAr;

  /// No monthly cap; [freePerMonth] is moot.
  final bool isUnlimited;

  /// Cases this doctor may file at this priority per month at no charge.
  final int freePerMonth;

  /// A one-time top-up for **this period only**, on top of [freePerMonth].
  /// Gone again next period — which is exactly why it is reported separately
  /// rather than folded into the standing figure.
  final int bonusFree;

  final int usedThisMonth;
  final int remainingFree;

  /// Charged once the free allowance is spent.
  final double surcharge;

  /// Which currency [surcharge] is in. Never dropped: this app is
  /// multi-currency and a bare surcharge is ambiguous the moment two labs or
  /// two levels price differently.
  final CurrencyModel? currency;

  /// `12.00 USD`, or a bare figure only when the server sent no currency.
  String get surchargeLabel =>
      currency?.format(surcharge) ?? surcharge.toStringAsFixed(2);

  /// Everything free this period — the standing allowance plus any bonus.
  int get totalFree => freePerMonth + bonusFree;

  /// Whether this doctor has their own figure, rather than the laboratory's
  /// default for the priority. The distinction is the whole feature: the same
  /// numbers mean different things depending on which one they came from.
  final bool isOverridden;

  String get priorityLabel {
    final ar = priorityNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return priorityName?.trim() ?? '';
  }

  factory PriorityQuotaLineModel.fromJson(Map<String, dynamic> json) {
    return PriorityQuotaLineModel(
      priorityId: json['priorityId'] as String? ?? '',
      priorityName: json['priorityName'] as String?,
      priorityNameAr: json['priorityNameAr'] as String?,
      isUnlimited: json['isUnlimited'] as bool? ?? false,
      freePerMonth: json['freePerMonth'] as int? ?? 0,
      bonusFree: json['bonusFree'] as int? ?? 0,
      usedThisMonth: json['usedThisMonth'] as int? ?? 0,
      remainingFree: json['remainingFree'] as int? ?? 0,
      surcharge: (json['surcharge'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
      isOverridden: json['isOverridden'] as bool? ?? false,
    );
  }
}

/// A doctor's priority allowances for one month
/// (`ClinicDoctorPriorityQuotaDto`).
///
/// The quota resets monthly, which is why [year] and [month] come back with
/// it: "٣ مستعملة" without the month it belongs to is not a fact.
class DoctorPriorityQuotaModel {
  const DoctorPriorityQuotaModel({
    required this.doctorId,
    this.year = 0,
    this.month = 0,
    this.lines = const [],
  });

  final String doctorId;
  final int year;
  final int month;
  final List<PriorityQuotaLineModel> lines;

  PriorityQuotaLineModel? lineFor(String priorityId) {
    for (final line in lines) {
      if (line.priorityId == priorityId) return line;
    }
    return null;
  }

  factory DoctorPriorityQuotaModel.fromJson(Map<String, dynamic> json) {
    return DoctorPriorityQuotaModel(
      doctorId: json['doctorId'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      lines:
          (json['lines'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PriorityQuotaLineModel.fromJson)
              .toList() ??
          const [],
    );
  }
}

/// Body of `PUT /doctors/{doctorId}/priority-quota`
/// (`ClinicSetPriorityAllowanceRequest`).
///
/// Sets **one** priority's allowance for **one** doctor. Both figures are
/// nullable, and null is not zero: it clears this doctor's override and puts
/// them back on the laboratory's default for that priority. Sending zero would
/// instead mean "no free cases at all", which is the opposite of "no special
/// arrangement".
class SetPriorityAllowanceRequestModel {
  const SetPriorityAllowanceRequestModel({
    required this.priorityId,
    this.freePerMonth,
    this.surchargeAmount,
  }) : assert(
         freePerMonth == null || freePerMonth >= 0,
         'A free allowance cannot be negative.',
       );

  final String priorityId;

  /// Free cases per month. Null reverts to the laboratory's default.
  final int? freePerMonth;

  /// Charge past the free allowance. Null reverts to the default.
  final double? surchargeAmount;

  /// Whether this clears the doctor's override rather than setting one.
  bool get isReset => freePerMonth == null && surchargeAmount == null;

  Map<String, dynamic> toJson() => {
    'priorityId': priorityId,
    // Sent as explicit nulls: omitting them is how the server is told
    // "unchanged", and this request has no such mode — null *is* the reset.
    'freePerMonth': freePerMonth,
    'surchargeAmount': surchargeAmount,
  };
}

/// One row of the laboratory-wide quota overview
/// (`ClinicPriorityOverviewRowDto`) — one doctor and every level they stand on.
class PriorityOverviewRowModel {
  const PriorityOverviewRowModel({
    required this.doctorId,
    this.doctorName,
    this.doctorNumber = 0,
    this.clinicName,
    this.lines = const [],
  });

  final String doctorId;
  final String? doctorName;
  final int doctorNumber;
  final String? clinicName;
  final List<PriorityQuotaLineModel> lines;

  /// Whether anything about this doctor's terms differs from the lab default
  /// — what the row highlights, since a directory of identical rows is not
  /// worth reading.
  bool get hasOverride => lines.any((line) => line.isOverridden);

  /// Levels this doctor has already exhausted this period.
  int get exhaustedCount => lines
      .where((line) => !line.isUnlimited && line.remainingFree <= 0)
      .length;

  factory PriorityOverviewRowModel.fromJson(Map<String, dynamic> json) {
    return PriorityOverviewRowModel(
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String?,
      doctorNumber: json['doctorNumber'] as int? ?? 0,
      clinicName: json['clinicName'] as String?,
      lines: [
        for (final line in json['lines'] as List<dynamic>? ?? const [])
          PriorityQuotaLineModel.fromJson(line as Map<String, dynamic>),
      ],
    );
  }
}

/// Every doctor's rush-priority standing for one period
/// (`ClinicPriorityOverviewDto`).
///
/// One query for the whole laboratory rather than a round trip per doctor —
/// which is the difference between a usable "who has what" screen and one
/// nobody opens.
class PriorityOverviewModel {
  const PriorityOverviewModel({
    this.year = 0,
    this.month = 0,
    this.periodResetsAt,
    this.doctors = const [],
  });

  final int year;
  final int month;

  /// The day the **next** period starts — when every usage figure here goes
  /// back to zero. Shown because "٣ مستعملة" is not a fact without the window
  /// it belongs to.
  final DateTime? periodResetsAt;

  final List<PriorityOverviewRowModel> doctors;

  /// Doctors on negotiated terms rather than the laboratory default.
  int get overriddenCount =>
      doctors.where((doctor) => doctor.hasOverride).length;

  factory PriorityOverviewModel.fromJson(Map<String, dynamic> json) {
    return PriorityOverviewModel(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      periodResetsAt: DateTime.tryParse(
        json['periodResetsAt'] as String? ?? '',
      ),
      doctors: [
        for (final row in json['doctors'] as List<dynamic>? ?? const [])
          PriorityOverviewRowModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }
}

/// One doctor's negotiated terms at one level (`ClinicPriorityAllowanceDto`).
///
/// Only doctors who actually have an override come back. **The absence of a
/// row is the meaningful state** — "standard terms" — and materialising one
/// per doctor would turn a lab-wide default that follows later edits into
/// hundreds of frozen copies of whatever it said that day.
class PriorityAllowanceModel {
  const PriorityAllowanceModel({
    required this.doctorId,
    this.freePerMonth = 0,
    this.surchargeAmount,
    this.currencyId,
    this.currency,
  });

  final String doctorId;
  final int freePerMonth;

  /// Null means this doctor negotiated the allowance but not the price — the
  /// level's own surcharge still applies.
  final double? surchargeAmount;

  final String? currencyId;
  final CurrencyModel? currency;

  factory PriorityAllowanceModel.fromJson(Map<String, dynamic> json) {
    return PriorityAllowanceModel(
      doctorId: json['doctorId'] as String? ?? '',
      freePerMonth: json['freePerMonth'] as int? ?? 0,
      surchargeAmount: (json['surchargeAmount'] as num?)?.toDouble(),
      currencyId: json['currencyId'] as String?,
      currency: json['currency'] == null
          ? null
          : CurrencyModel.fromJson(json['currency'] as Map<String, dynamic>),
    );
  }
}

/// `ClinicBulkSetPriorityAllowanceRequest` — one level's terms, written onto a
/// set of doctors at once.
///
/// **Applies to the listed doctors only; it is not a replace.** A doctor not
/// in [doctorIds] keeps whatever they had. Deliberately unlike the price-tier
/// membership list, which does replace: that screen shows a tier's complete
/// membership, while this one is a filtered slice of the directory, and
/// treating everyone the filter hid as deselected would wipe their negotiated
/// terms.
class BulkSetPriorityAllowanceRequestModel {
  const BulkSetPriorityAllowanceRequestModel({
    required this.doctorIds,
    this.freePerMonth,
    this.surchargeAmount,
    this.currencyId,
  });

  final List<String> doctorIds;

  /// Null **clears** each listed doctor's override and returns them to the
  /// level's own default — the same meaning null carries for one doctor.
  final int? freePerMonth;

  final double? surchargeAmount;
  final String? currencyId;

  Map<String, dynamic> toJson() => {
    'doctorIds': doctorIds,
    'freePerMonth': freePerMonth,
    'surchargeAmount': surchargeAmount,
    'currencyId': currencyId,
  };
}

/// `ClinicIncreasePriorityAllowanceRequest` — bumps one doctor's allowance at
/// one level.
///
/// Two independent choices, which is why the form asks both:
/// - **permanent or this period only.** Permanent rewrites the standing
///   free-per-month; a bonus tops up the current period and is gone next.
/// - **free or paid.** Paid raises an ad-hoc invoice for [paidAmount]; free
///   just notifies the doctor of the new terms.
class IncreasePriorityAllowanceRequestModel {
  const IncreasePriorityAllowanceRequestModel({
    required this.permanent,
    this.newFreePerMonth,
    this.bonusFree,
    this.isPaid = false,
    this.paidAmount,
    this.currencyId,
  });

  final bool permanent;

  /// The new standing figure. Required when [permanent].
  final int? newFreePerMonth;

  /// Extra free cases for the current period only. Required when not
  /// [permanent].
  final int? bonusFree;

  final bool isPaid;

  /// The one-time fee — typed by the admin, **not** computed from the level's
  /// per-case surcharge, because this is a negotiated figure rather than an
  /// arithmetic one.
  final double? paidAmount;

  final String? currencyId;

  Map<String, dynamic> toJson() => {
    'permanent': permanent,
    'newFreePerMonth': permanent ? newFreePerMonth : null,
    'bonusFree': permanent ? null : bonusFree,
    'isPaid': isPaid,
    'paidAmount': isPaid ? paidAmount : null,
    'currencyId': isPaid ? currencyId : null,
  };
}
