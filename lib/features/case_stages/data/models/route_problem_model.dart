/// One thing wrong with a workflow (`RouteProblemDto`) — shared shape between
/// `GET /case-statuses/validate` (the case workflow) and a restoration
/// type's own route validation.
///
/// Every row this endpoint returns describes a case or unit that would
/// silently stop — the server names the offending stage rather than only the
/// rule, so the editor can mark that row instead of listing the problem at
/// the bottom. There is no severity on the wire: everything reported here is
/// a real defect, not a style suggestion.
class RouteProblemModel {
  const RouteProblemModel({
    this.code,
    this.message,
    this.messageAr,
    this.stageId,
  });

  final String? code;
  final String? message;
  final String? messageAr;

  /// The stage it belongs to, so the board can mark that node rather than
  /// only listing the problem at the bottom.
  final String? stageId;

  /// Arabic first, English as the fallback, the code as a last resort so a
  /// row is never blank.
  String get displayMessage {
    final ar = messageAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    final en = message?.trim();
    if (en != null && en.isNotEmpty) return en;
    return code?.trim() ?? '';
  }

  factory RouteProblemModel.fromJson(Map<String, dynamic> json) {
    return RouteProblemModel(
      code: json['code'] as String?,
      message: json['message'] as String?,
      messageAr: json['messageAr'] as String?,
      stageId: json['stageId'] as String?,
    );
  }
}
