/// One case's outcome from the bulk "تم التسليم" call
/// (`ClinicDeliverDirectlyResultDto`) — one row per requested id, in the order
/// they were sent.
class DeliverDirectlyResultModel {
  const DeliverDirectlyResultModel({
    required this.caseId,
    this.caseNumber,
    this.delivered = false,
    this.error,
  });

  /// The API's cap on one bulk request: every case is a full walk through its
  /// route, one saved step at a time.
  static const maxCasesPerRequest = 200;

  final String caseId;

  /// Null only when the case could not be found at all.
  final String? caseNumber;

  /// True once the case is delivered — including one that already was.
  final bool delivered;

  /// Why the case stopped short. It stays on the last step that succeeded.
  final String? error;

  factory DeliverDirectlyResultModel.fromJson(Map<String, dynamic> json) {
    return DeliverDirectlyResultModel(
      caseId: json['caseId'] as String? ?? '',
      caseNumber: json['caseNumber'] as String?,
      delivered: json['delivered'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}
