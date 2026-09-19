import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';

/// A laboratory-declared option that can gate route stages (`CaseOptionDto`).
///
/// A stage with a `requiredOptionId` is only cut onto cases that selected that
/// option — so answering these at intake is what decides which stages the case
/// actually runs, alongside the impression method.
class CaseOptionModel {
  const CaseOptionModel({
    required this.id,
    this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.scope,
    this.defaultValue = false,
    this.displayOrder = 0,
    this.isActive = true,
    this.restorationTypeIds = const [],
    this.gatedStageCount = 0,
  });

  final String id;
  final String? name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final CaseOptionScope? scope;

  /// Whether the option starts selected on a new case.
  final bool defaultValue;

  final int displayOrder;
  final bool isActive;

  /// Restoration types this option is offered for. Empty means all of them.
  final List<String> restorationTypeIds;

  /// How many stages this option gates. Worth showing: an option that gates
  /// nothing changes no route, and the user is entitled to know that before
  /// agonising over it.
  final int gatedStageCount;

  String get label {
    final ar = nameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return name?.trim() ?? '';
  }

  String get descriptionLabel {
    final ar = descriptionAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return description?.trim() ?? '';
  }

  /// Whether this option is offered for [restorationTypeId]. An empty
  /// [restorationTypeIds] means the lab did not scope it, so it applies to
  /// everything.
  bool appliesToRestorationType(String restorationTypeId) =>
      restorationTypeIds.isEmpty ||
      restorationTypeIds.contains(restorationTypeId);

  factory CaseOptionModel.fromJson(Map<String, dynamic> json) {
    return CaseOptionModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      scope: CaseOptionScope.fromValue(json['scope'] as int?),
      defaultValue: json['defaultValue'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      restorationTypeIds:
          (json['restorationTypeIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      gatedStageCount: json['gatedStageCount'] as int? ?? 0,
    );
  }
}

/// A restoration's answer to one option (`ClinicRestorationOptionRequest`).
class RestorationOptionSelectionModel {
  const RestorationOptionSelectionModel({
    required this.caseOptionId,
    required this.selected,
  });

  final String caseOptionId;
  final bool selected;

  Map<String, dynamic> toJson() => {
    'caseOptionId': caseOptionId,
    'selected': selected,
  };
}
