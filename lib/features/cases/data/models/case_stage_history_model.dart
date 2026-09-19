/// One entry in the case's stage timeline (`ClinicCaseStatusHistoryDto`).
///
/// The names are **snapshots**, written at the moment of the move. Render
/// them, never a join back to the live catalogue: a lab that renames a stage
/// next month must not rewrite what last month's timeline says the case went
/// through, and a deleted stage still has to draw.
class CaseStageHistoryModel {
  final String? stageId;
  final String? previousStageId;

  /// The stage's name as it was when the move happened.
  final String? stageName;
  final String? stageNameAr;

  /// True when the move went backwards — this is what colours an entry as a
  /// rejection rather than as progress.
  final bool isReturn;

  /// Which pass at this stage the move belongs to.
  final int attempt;

  final int orderNum;

  /// Required text on stages that demand it.
  final String? reason;

  final String? changedByName;
  final String? note;
  final DateTime? changedAt;

  const CaseStageHistoryModel({
    this.stageId,
    this.previousStageId,
    this.stageName,
    this.stageNameAr,
    this.isReturn = false,
    this.attempt = 1,
    this.orderNum = 0,
    this.reason,
    this.changedByName,
    this.note,
    this.changedAt,
  });

  /// Arabic first, English as the fallback, empty when neither was recorded.
  String get stageLabel {
    final ar = stageNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return stageName?.trim() ?? '';
  }

  factory CaseStageHistoryModel.fromJson(Map<String, dynamic> json) {
    return CaseStageHistoryModel(
      stageId: json['stageId'] as String?,
      previousStageId: json['previousStageId'] as String?,
      stageName: json['stageName'] as String?,
      stageNameAr: json['stageNameAr'] as String?,
      isReturn: json['isReturn'] as bool? ?? false,
      attempt: json['attempt'] as int? ?? 1,
      orderNum: json['orderNum'] as int? ?? 0,
      reason: json['reason'] as String?,
      changedByName: json['changedByName'] as String?,
      note: json['note'] as String?,
      changedAt: json['changedAt'] != null
          ? DateTime.tryParse(json['changedAt'] as String)
          : null,
    );
  }
}
