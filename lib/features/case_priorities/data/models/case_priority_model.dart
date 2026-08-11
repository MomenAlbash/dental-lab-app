/// A case priority as configured by the laboratory (`CasePriorityDto`).
///
/// Priorities used to be a fixed `1..4` enum in the app. They are now a
/// lookup entity the lab owns: rows can be added, renamed, reordered and
/// deactivated, and each carries its own monthly free quota and surcharge.
class CasePriorityModel {
  final String id;
  final String? name;
  final String? nameAr;
  final String? description;
  final int displayOrder;

  /// The one preselected on a new case. At most one row has it.
  final bool isDefault;

  /// When true the priority has no monthly cap, and [freePerMonth] is moot.
  final bool isUnlimited;
  final int freePerMonth;

  /// Charged once a doctor is past their free allowance for the month.
  final double surcharge;

  /// Server-chosen colour name for the badge (see `badgeVariantColor`).
  final String? badgeVariant;
  final bool isActive;

  /// Whether any case already references it — such a row cannot be deleted.
  final bool isInUse;

  const CasePriorityModel({
    required this.id,
    this.name,
    this.nameAr,
    this.description,
    this.displayOrder = 0,
    this.isDefault = false,
    this.isUnlimited = false,
    this.freePerMonth = 0,
    this.surcharge = 0,
    this.badgeVariant,
    this.isActive = true,
    this.isInUse = false,
  });

  /// Arabic first, since the whole UI is Arabic; the English name is the
  /// fallback because `nameAr` is optional on the API.
  String get displayName {
    final ar = nameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    final en = name?.trim();
    if (en != null && en.isNotEmpty) return en;
    return '—';
  }

  factory CasePriorityModel.fromJson(Map<String, dynamic> json) {
    return CasePriorityModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      isUnlimited: json['isUnlimited'] as bool? ?? false,
      freePerMonth: json['freePerMonth'] as int? ?? 0,
      surcharge: (json['surcharge'] as num?)?.toDouble() ?? 0,
      badgeVariant: json['badgeVariant'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isInUse: json['isInUse'] as bool? ?? false,
    );
  }
}
