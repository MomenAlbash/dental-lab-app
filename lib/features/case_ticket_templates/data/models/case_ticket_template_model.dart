import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_model.dart';

/// Full detail of one saved thermal-ticket template (`CaseTicketTemplateDto`)
/// — as read/edited by the template editor and as resolved at print time.
class CaseTicketTemplateModel {
  const CaseTicketTemplateModel({
    required this.id,
    this.name,
    this.isDefault = false,
    this.paperWidthMm = 80,
    this.baseFontSizePx = 24,
    this.fontFamily,
    this.rows = const [],
  });

  final String id;
  final String? name;

  /// Exactly one `true` per laboratory (server-enforced) — used when the
  /// operator doesn't pick a template explicitly.
  final bool isDefault;

  /// The roll width as the lab types it — 58, 80, or custom. Not the
  /// printable width; the renderer computes that separately.
  final double paperWidthMm;

  final double baseFontSizePx;

  /// Null falls back to the renderer's own default.
  final String? fontFamily;

  final List<CaseTicketTemplateRowModel> rows;

  factory CaseTicketTemplateModel.fromJson(Map<String, dynamic> json) {
    return CaseTicketTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      paperWidthMm: (json['paperWidthMm'] as num?)?.toDouble() ?? 80,
      baseFontSizePx: (json['baseFontSizePx'] as num?)?.toDouble() ?? 24,
      fontFamily: json['fontFamily'] as String?,
      rows:
          (json['rows'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(CaseTicketTemplateRowModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
