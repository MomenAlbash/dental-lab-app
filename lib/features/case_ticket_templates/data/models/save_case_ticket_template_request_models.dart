import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_model.dart';

/// `POST /CaseTicketTemplates` — a new template starts with an empty row
/// list; rows are added afterward through [UpdateCaseTicketTemplateRequestModel].
class CreateCaseTicketTemplateRequestModel {
  const CreateCaseTicketTemplateRequestModel({required this.name})
    : assert(
        name.length > 0 && name.length <= 200,
        'Template name must be 1-200 characters.',
      );

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}

/// `PUT /CaseTicketTemplates/{id}` — a full replace of the layout, the
/// editor's "Save" action, not an incremental patch: the whole [rows] list
/// sent here is what gets saved, matching
/// `SaveLaboratoryReportTemplateRequest.Elements`'s convention.
class UpdateCaseTicketTemplateRequestModel {
  const UpdateCaseTicketTemplateRequestModel({
    required this.name,
    this.paperWidthMm,
    this.baseFontSizePx,
    this.fontFamily,
    this.rows,
  }) : assert(
         rows == null || rows.length <= 60,
         'A template holds at most 60 rows.',
       );

  final String name;
  final double? paperWidthMm;
  final double? baseFontSizePx;
  final String? fontFamily;
  final List<CaseTicketTemplateRowModel>? rows;

  Map<String, dynamic> toJson() => {
    'name': name,
    'paperWidthMm': paperWidthMm,
    'baseFontSizePx': baseFontSizePx,
    'fontFamily': fontFamily,
    'rows': rows?.map((r) => r.toJson()).toList(),
  };
}
