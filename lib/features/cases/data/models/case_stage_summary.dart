/// The stage fields the server denormalises onto every case row and detail.
///
/// This is a *summary* — the name of the lowest-ordered live stage, for a list
/// row or a hero pill. It is not the workflow: a case can have several stages
/// live at once, and only `GET /Cases/{id}/plan` says which. Never build a
/// board from these fields.
///
/// Replaces the old `caseStatus` int, which the API no longer sends.
class CaseStageSummary {
  final String? stageId;
  final String? stageName;
  final String? stageNameAr;

  /// A design-token name, resolved through `badgeVariantColor`.
  final String? stageBadgeVariant;

  final String? stageCategoryId;
  final String? stageCategoryName;
  final String? stageCategoryNameAr;

  /// True when no case stage is live because the restorations are running
  /// their own routes. Distinct from an unrouted case, which also has no live
  /// stage — the two need different screens.
  final bool isInProduction;

  /// Out of the building — pauses the turnaround clock. Only meaningful
  /// alongside [productionStageId]: it describes *that* stage, not the case's
  /// own.
  final bool stageIsExternal;

  /// One representative restoration's current stage, while the case is mid-
  /// production. **Not the whole picture** — a case can have several
  /// restorations on several different stages at once, and this is only the
  /// lowest-ordered one the server picked to summarise with. It exists for a
  /// one-line "بالتصميم" under the phase badge, not for a per-restoration
  /// breakdown — [productionOtherStagesCount] only counts how many are
  /// elsewhere. `CaseListItemModel.restorationBreakdown` says *where*, and
  /// arrives on the same row.
  final String? productionStageId;
  final String? productionStageName;
  final String? productionStageNameAr;

  /// Which restoration type [productionStageName] belongs to — a case row
  /// with a crown and a denture needs to say which one is "بالتصميم".
  final String? productionRestorationTypeName;
  final String? productionRestorationTypeNameAr;

  /// How many of the case's *other* restorations are on some other stage.
  /// Zero means every restoration shares [productionStageId], not that there
  /// is only one restoration.
  final int productionOtherStagesCount;

  final bool isLate;
  final String? expectedCompletionAt;

  const CaseStageSummary({
    this.stageId,
    this.stageName,
    this.stageNameAr,
    this.stageBadgeVariant,
    this.stageCategoryId,
    this.stageCategoryName,
    this.stageCategoryNameAr,
    this.isInProduction = false,
    this.stageIsExternal = false,
    this.productionStageId,
    this.productionStageName,
    this.productionStageNameAr,
    this.productionRestorationTypeName,
    this.productionRestorationTypeNameAr,
    this.productionOtherStagesCount = 0,
    this.isLate = false,
    this.expectedCompletionAt,
  });

  static const empty = CaseStageSummary();

  /// Arabic first, English as the fallback. Empty — never a default stage
  /// name — when the server sent nothing. Inventing one here is exactly the
  /// bug this model exists to fix: the old enum defaulted every case to
  /// "Created" the moment the field disappeared.
  String get label {
    final ar = stageNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return stageName?.trim() ?? '';
  }

  String get categoryLabel {
    final ar = stageCategoryNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return stageCategoryName?.trim() ?? '';
  }

  /// Arabic first, English as the fallback; empty when the case is not
  /// carrying a production-stage summary at all.
  String get productionStageLabel {
    final ar = productionStageNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return productionStageName?.trim() ?? '';
  }

  String get productionRestorationTypeLabel {
    final ar = productionRestorationTypeNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return productionRestorationTypeName?.trim() ?? '';
  }

  /// Whether there is a production-stage summary worth drawing at all.
  /// Gated on both flags per MOBILE-SPEC §15.3: `isInProduction` alone can be
  /// true with no stage yet resolved.
  bool get hasProductionSummary =>
      isInProduction && productionStageLabel.isNotEmpty;

  /// Reads the flat fields off a case row or a case detail — both carry the
  /// same set, so it is parsed once here instead of twice.
  factory CaseStageSummary.fromCaseJson(Map<String, dynamic> json) {
    return CaseStageSummary(
      stageId: json['stageId'] as String?,
      stageName: json['stageName'] as String?,
      stageNameAr: json['stageNameAr'] as String?,
      stageBadgeVariant: json['stageBadgeVariant'] as String?,
      stageCategoryId: json['stageCategoryId'] as String?,
      stageCategoryName: json['stageCategoryName'] as String?,
      stageCategoryNameAr: json['stageCategoryNameAr'] as String?,
      isInProduction: json['isInProduction'] as bool? ?? false,
      stageIsExternal: json['stageIsExternal'] as bool? ?? false,
      productionStageId: json['productionStageId'] as String?,
      productionStageName: json['productionStageName'] as String?,
      productionStageNameAr: json['productionStageNameAr'] as String?,
      productionRestorationTypeName:
          json['productionRestorationTypeName'] as String?,
      productionRestorationTypeNameAr:
          json['productionRestorationTypeNameAr'] as String?,
      productionOtherStagesCount:
          json['productionOtherStagesCount'] as int? ?? 0,
      isLate: json['isLate'] as bool? ?? false,
      expectedCompletionAt: json['expectedCompletionAt'] as String?,
    );
  }
}
