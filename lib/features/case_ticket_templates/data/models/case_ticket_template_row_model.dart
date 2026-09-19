import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_row_align.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_kind.dart';

/// One row of a saved thermal-ticket template (`CaseTicketTemplateRowDto`) —
/// a fixed field the renderer resolves per case, the whole restorations
/// table, or a free-typed static line.
class CaseTicketTemplateRowModel {
  const CaseTicketTemplateRowModel({
    required this.id,
    required this.kind,
    this.visible = true,
    this.label,
    this.fontSize,
    this.bold,
    this.align,
    this.qrSizeMm,
    this.showTeeth,
    this.showShade,
    this.showNotes,
    this.text,
  });

  /// Client-assigned, stable across reorders and saves — generated once when
  /// a row is added so a drag/reorder edit updates the same row instead of
  /// duplicating it.
  final String id;

  final CaseTicketTemplateRowKind kind;
  final bool visible;

  /// Caption override for [CaseTicketTemplateRowKind.hasEditableLabel] rows.
  /// Null keeps the renderer's own default caption.
  final String? label;

  final double? fontSize;
  final bool? bold;
  final CaseTicketRowAlign? align;

  /// [CaseTicketTemplateRowKind.qr] only.
  final double? qrSizeMm;

  /// [CaseTicketTemplateRowKind.restorationsTable] only — which
  /// per-restoration detail lines print.
  final bool? showTeeth;
  final bool? showShade;
  final bool? showNotes;

  /// [CaseTicketTemplateRowKind.customLabel] only — the free-typed text
  /// itself, as opposed to [label], which overrides a bound row's caption.
  final String? text;

  factory CaseTicketTemplateRowModel.fromJson(Map<String, dynamic> json) {
    return CaseTicketTemplateRowModel(
      id: json['id'] as String? ?? '',
      kind:
          CaseTicketTemplateRowKind.fromApi(json['kind'] as String?) ??
          CaseTicketTemplateRowKind.customLabel,
      visible: json['visible'] as bool? ?? true,
      label: json['label'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      bold: json['bold'] as bool?,
      align: CaseTicketRowAlign.fromApi(json['align'] as String?),
      qrSizeMm: (json['qrSizeMm'] as num?)?.toDouble(),
      showTeeth: json['showTeeth'] as bool?,
      showShade: json['showShade'] as bool?,
      showNotes: json['showNotes'] as bool?,
      text: json['text'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.apiValue,
    'visible': visible,
    'label': label,
    'fontSize': fontSize,
    'bold': bold,
    'align': align?.apiValue,
    'qrSizeMm': qrSizeMm,
    'showTeeth': showTeeth,
    'showShade': showShade,
    'showNotes': showNotes,
    'text': text,
  };

  CaseTicketTemplateRowModel copyWith({
    CaseTicketTemplateRowKind? kind,
    bool? visible,
    String? label,
    bool clearLabel = false,
    double? fontSize,
    bool? bold,
    CaseTicketRowAlign? align,
    double? qrSizeMm,
    bool? showTeeth,
    bool? showShade,
    bool? showNotes,
    String? text,
  }) {
    return CaseTicketTemplateRowModel(
      id: id,
      kind: kind ?? this.kind,
      visible: visible ?? this.visible,
      label: clearLabel ? null : (label ?? this.label),
      fontSize: fontSize ?? this.fontSize,
      bold: bold ?? this.bold,
      align: align ?? this.align,
      qrSizeMm: qrSizeMm ?? this.qrSizeMm,
      showTeeth: showTeeth ?? this.showTeeth,
      showShade: showShade ?? this.showShade,
      showNotes: showNotes ?? this.showNotes,
      text: text ?? this.text,
    );
  }
}
