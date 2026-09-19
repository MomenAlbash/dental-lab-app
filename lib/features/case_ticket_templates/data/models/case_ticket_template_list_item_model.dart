/// One row of a laboratory's saved-templates list
/// (`CaseTicketTemplateListItemDto`) — no row content, since the list screen
/// only needs enough to pick, rename, delete or set a default.
class CaseTicketTemplateListItemModel {
  const CaseTicketTemplateListItemModel({
    required this.id,
    this.name,
    this.isDefault = false,
    this.paperWidthMm = 80,
    this.updatedAt,
  });

  final String id;
  final String? name;
  final bool isDefault;
  final double paperWidthMm;
  final DateTime? updatedAt;

  factory CaseTicketTemplateListItemModel.fromJson(Map<String, dynamic> json) {
    return CaseTicketTemplateListItemModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      paperWidthMm: (json['paperWidthMm'] as num?)?.toDouble() ?? 80,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
