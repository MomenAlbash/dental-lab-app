/// One (stage, restoration type) group among a case's restorations
/// (`ClinicCaseRestorationBreakdownDto`).
///
/// Called a *group*, not a restoration: it is several pieces of the same type
/// sitting on the same stage, carrying a [count] rather than an identity. The
/// per-restoration route, each with its own number, is the case detail's
/// "تقدم الحالة" tab — this is the list row's own expander.
///
/// Independent of the case's own phase: a restoration starts walking its route
/// the moment its plan is cut, so "where is each unit right now" is a fair
/// question even on a case that has not been received yet.
class CaseRestorationBreakdownGroup {
  const CaseRestorationBreakdownGroup({
    this.restorationTypeId,
    this.restorationTypeName,
    this.restorationTypeNameAr,
    this.stageId,
    this.stageName,
    this.stageNameAr,
    this.count = 0,
  });

  final String? restorationTypeId;
  final String? restorationTypeName;
  final String? restorationTypeNameAr;

  /// **Null is a meaning, not a failure.** The server sends no stage when this
  /// group has not reached a live one yet — a restoration joins its route's
  /// first step only once its plan has been cut. Read as "not started", never
  /// as a stage the client failed to resolve.
  final String? stageId;

  final String? stageName;
  final String? stageNameAr;

  /// How many restorations of this type sit on this stage.
  final int count;

  /// Arabic first, English as the fallback. Empty — never an invented name —
  /// when the server sent neither, so callers can say "—" rather than print a
  /// placeholder that reads like a real type.
  String get restorationTypeLabel {
    final ar = restorationTypeNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return restorationTypeName?.trim() ?? '';
  }

  String get stageLabel {
    final ar = stageNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return stageName?.trim() ?? '';
  }

  /// Whether this group is actually on a stage.
  ///
  /// Requires a name as well as an id: a group carrying a stage id the server
  /// could not name would otherwise render a blank where a stage should be,
  /// which reads as a rendering fault rather than as information. Saying "لم
  /// تبدأ" is wrong there too, but it is wrong in a way the user can see and
  /// ask about.
  bool get hasStarted =>
      (stageId?.trim().isNotEmpty ?? false) && stageLabel.isNotEmpty;

  factory CaseRestorationBreakdownGroup.fromJson(Map<String, dynamic> json) {
    return CaseRestorationBreakdownGroup(
      restorationTypeId: json['restorationTypeId'] as String?,
      restorationTypeName: json['restorationTypeName'] as String?,
      restorationTypeNameAr: json['restorationTypeNameAr'] as String?,
      stageId: json['stageId'] as String?,
      stageName: json['stageName'] as String?,
      stageNameAr: json['stageNameAr'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }

  /// Reads the breakdown off a case row, the way [CaseStageSummary] reads the
  /// flat stage fields off the same object.
  ///
  /// **Never casts.** `restorationBreakdown` is nullable and undeclared-required
  /// in the API, and this parse runs inside the cases-list mapping — an `as
  /// List` on an unexpected shape would throw, failing every row in the
  /// response and blanking the screen. A cosmetic expander must not be able to
  /// take the cases list down, so anything that is not a list of objects is
  /// dropped rather than raised.
  static List<CaseRestorationBreakdownGroup> listFromCaseJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['restorationBreakdown'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CaseRestorationBreakdownGroup.fromJson)
        .toList(growable: false);
  }
}
