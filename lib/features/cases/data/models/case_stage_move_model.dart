/// Why a move is offered: forward through the route, or back for rework.
enum CaseStageMoveKind {
  normal(1),
  rework(2);

  const CaseStageMoveKind(this.apiValue);

  final int apiValue;

  bool get isRework => this == CaseStageMoveKind.rework;

  /// The API serialises this one as a **string** on the DTO (`"Normal"` /
  /// `"Rework"`) even though the enum itself is numeric elsewhere, so both
  /// shapes are accepted. An unknown value reads as a forward move: showing a
  /// rework as ordinary progress is recoverable, the reverse is alarming.
  static CaseStageMoveKind fromApi(dynamic value) {
    if (value is int) return value == 2 ? rework : normal;
    final text = value?.toString().trim().toLowerCase();
    return text == 'rework' || text == '2' ? rework : normal;
  }
}

/// One move the server says this case may make right now
/// (`CaseStageMoveDto`).
///
/// Server-resolved on purpose: the rules that decide it — the running order,
/// the parallel step, the production barrier, the declared rework target —
/// live on the server, and a client that recomputed them would disagree with
/// it the moment a lab edits its workflow.
class CaseStageMoveModel {
  const CaseStageMoveModel({
    required this.toStageId,
    this.toStageName,
    this.toStageNameAr,
    this.kind = CaseStageMoveKind.normal,
    this.requiresReason = false,
    this.blockedReason,
    this.displayOrder = 0,
  });

  final String toStageId;
  final String? toStageName;
  final String? toStageNameAr;
  final CaseStageMoveKind kind;

  /// The move refuses an empty reason — the sheet must ask for one.
  final bool requiresReason;

  /// Why the move is barred **right now** (most often the production barrier:
  /// restorations still running). Non-null means show the option disabled with
  /// this text rather than hiding it — a case that offers nothing and explains
  /// nothing reads as broken.
  final String? blockedReason;

  final int displayOrder;

  bool get isBlocked => blockedReason != null && blockedReason!.isNotEmpty;

  /// Arabic first, English as the fallback, never a placeholder: the lab wrote
  /// these names itself.
  String get displayName {
    final ar = toStageNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return toStageName?.trim() ?? '';
  }

  factory CaseStageMoveModel.fromJson(Map<String, dynamic> json) {
    return CaseStageMoveModel(
      toStageId: json['toStageId'] as String? ?? '',
      toStageName: json['toStageName'] as String?,
      toStageNameAr: json['toStageNameAr'] as String?,
      kind: CaseStageMoveKind.fromApi(json['kind']),
      requiresReason: json['requiresReason'] as bool? ?? false,
      blockedReason: json['blockedReason'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}
