/// What a stage's price is multiplied by (`StagePayBasis`).
enum StagePayBasis {
  perTooth(1, 'لكل سن'),
  perRestoration(2, 'لكل تعويض');

  const StagePayBasis(this.value, this.label);

  final int value;
  final String label;

  static StagePayBasis? fromValue(int? value) {
    for (final basis in StagePayBasis.values) {
      if (basis.value == value) return basis;
    }
    return null;
  }
}

/// One stage of a restoration type and what finishing it pays
/// (`StagePayRateDto`).
class StagePayRateModel {
  const StagePayRateModel({
    required this.rootStageId,
    this.name,
    this.nameAr,
    this.order = 0,
    this.amount = 0,
    this.basis = StagePayBasis.perRestoration,
  });

  /// The key a price is saved under — shared by every version of the stage,
  /// so editing the stage's definition keeps its price.
  final String rootStageId;
  final String? name;
  final String? nameAr;
  final int order;

  /// Zero means the stage is not priced: finishing it pays nothing.
  final double amount;
  final StagePayBasis basis;

  String get displayName => nameAr ?? name ?? '—';

  bool get isPriced => amount > 0;

  factory StagePayRateModel.fromJson(Map<String, dynamic> json) {
    return StagePayRateModel(
      rootStageId: json['rootStageId'] as String? ?? '',
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      order: json['order'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      basis:
          StagePayBasis.fromValue(json['basis'] as int?) ??
          StagePayBasis.perRestoration,
    );
  }
}

/// One restoration type and the price of each of its current stages
/// (`StagePayRestorationTypeDto`).
class StagePayRestorationTypeModel {
  const StagePayRestorationTypeModel({
    required this.restorationTypeId,
    required this.laboratoryId,
    this.name,
    this.nameAr,
    this.stages = const [],
  });

  final String restorationTypeId;

  /// A save names the laboratory it writes to, so edits are grouped by this.
  final String laboratoryId;
  final String? name;
  final String? nameAr;

  /// In route order, however the rows arrived.
  final List<StagePayRateModel> stages;

  String get displayName => nameAr ?? name ?? '—';

  int get pricedCount => stages.where((s) => s.isPriced).length;

  factory StagePayRestorationTypeModel.fromJson(Map<String, dynamic> json) {
    return StagePayRestorationTypeModel(
      restorationTypeId: json['restorationTypeId'] as String? ?? '',
      laboratoryId: json['laboratoryId'] as String? ?? '',
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      stages: [
        for (final stage in json['stages'] as List<dynamic>? ?? const [])
          if (stage is Map<String, dynamic>) StagePayRateModel.fromJson(stage),
      ]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}

/// One stage's new price inside a [SaveStagePayRatesRequestModel].
class StagePayRateDraft {
  const StagePayRateDraft({required this.amount, required this.basis});

  final double amount;
  final StagePayBasis basis;
}

/// `SaveStagePayRatesRequest` — replaces the prices of the stages listed;
/// stages not listed keep theirs, and an amount of zero removes a price.
class SaveStagePayRatesRequestModel {
  const SaveStagePayRatesRequestModel({
    required this.laboratoryId,
    required this.rates,
  });

  final String laboratoryId;

  /// Keyed by root stage id.
  final Map<String, StagePayRateDraft> rates;

  Map<String, dynamic> toJson() => {
    'laboratoryId': laboratoryId,
    'rates': [
      for (final entry in rates.entries)
        {
          'rootStageId': entry.key,
          'amount': entry.value.amount,
          'basis': entry.value.basis.value,
        },
    ],
  };
}

/// One stage one employee finished, and what it paid
/// (`EmployeeStageEarningDto`).
class EmployeeStageEarningModel {
  const EmployeeStageEarningModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.caseId,
    this.caseNumber,
    this.restorationTypeName,
    this.restorationTypeNameAr,
    this.stageName,
    this.stageNameAr,
    this.basis = StagePayBasis.perRestoration,
    this.quantity = 0,
    this.unitAmount = 0,
    this.amount = 0,
    this.earnedAt,
    this.isVoided = false,
  });

  final String id;
  final String employeeId;
  final String? employeeName;
  final String? caseId;
  final String? caseNumber;
  final String? restorationTypeName;
  final String? restorationTypeNameAr;
  final String? stageName;
  final String? stageNameAr;
  final StagePayBasis basis;
  final int quantity;
  final double unitAmount;
  final double amount;
  final DateTime? earnedAt;

  /// Cancelled — e.g. by a breakage that sent the work back. Still listed so
  /// the history is honest, but it pays nothing.
  final bool isVoided;

  String get stageDisplayName => stageNameAr ?? stageName ?? '—';

  String get restorationTypeDisplayName =>
      restorationTypeNameAr ?? restorationTypeName ?? '—';

  factory EmployeeStageEarningModel.fromJson(Map<String, dynamic> json) {
    return EmployeeStageEarningModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      caseId: json['caseId'] as String?,
      caseNumber: json['caseNumber'] as String?,
      restorationTypeName: json['restorationTypeName'] as String?,
      restorationTypeNameAr: json['restorationTypeNameAr'] as String?,
      stageName: json['stageName'] as String?,
      stageNameAr: json['stageNameAr'] as String?,
      basis:
          StagePayBasis.fromValue(json['basis'] as int?) ??
          StagePayBasis.perRestoration,
      quantity: json['quantity'] as int? ?? 0,
      unitAmount: (json['unitAmount'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      earnedAt: DateTime.tryParse(json['earnedAt'] as String? ?? '')?.toLocal(),
      isVoided: json['isVoided'] as bool? ?? false,
    );
  }

  /// What a set of rows actually pays — voided rows excluded.
  static double totalOf(Iterable<EmployeeStageEarningModel> rows) =>
      rows.where((r) => !r.isVoided).fold(0, (sum, r) => sum + r.amount);
}

/// What sending a broken restoration back to a stage would throw away
/// (`LossPreviewDto`) — shown while recording the breakage, so whoever records
/// it can see the lost work before choosing who pays for it.
class LossPreviewModel {
  const LossPreviewModel({this.lostWorkValue = 0, this.lostEarnings = const []});

  final double lostWorkValue;

  /// The stage pay that would be redone — and whose it was.
  final List<EmployeeStageEarningModel> lostEarnings;

  factory LossPreviewModel.fromJson(Map<String, dynamic> json) {
    return LossPreviewModel(
      lostWorkValue: (json['lostWorkValue'] as num?)?.toDouble() ?? 0,
      lostEarnings: [
        for (final row in json['lostEarnings'] as List<dynamic>? ?? const [])
          if (row is Map<String, dynamic>)
            EmployeeStageEarningModel.fromJson(row),
      ],
    );
  }
}
