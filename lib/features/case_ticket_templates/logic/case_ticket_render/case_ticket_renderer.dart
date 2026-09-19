import 'dart:convert';
import 'dart:typed_data';

import 'package:dental_lab_app/core/printing/tspl_bitmap_text.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_row_align.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_kind.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:flutter/painting.dart';

/// A prepared piece of a line — its final height (known synchronously,
/// before any byte is written) and how to emit it once the y it lands at is
/// known. [emit] is async only for the bitmap path (rasterizing); the ASCII
/// path resolves immediately.
typedef _Prepared = ({int height, Future<void> Function(BytesBuilder, int, int) emit});

/// One printable line, already sized — kept separate from emitting its TSPL
/// so the total ticket height (needed on the `SIZE` command, before any line
/// can be written) is known before the first byte goes out.
class _Line {
  const _Line({required this.heightDots, required this.emit});

  final int heightDots;

  /// Writes this line's TSPL commands at the given top-left y.
  final Future<void> Function(BytesBuilder builder, int y) emit;
}

/// Merges a [CaseTicketTemplateModel] with the case data it prints
/// (`GET /Cases/{id}/print-ticket`) into a TSPL command stream, ready for
/// [LabelPrinterService.printBytes].
///
/// A pure function on purpose — the doc this feature follows is explicit
/// that live preview and the real print must share one merge function, so
/// there is exactly one place that decides what a row kind resolves to.
///
/// **Coordinates are in dots at 8 dots/mm (203dpi)**, the same convention
/// [LabelPrinterService.buildCaseLabel] uses. Any line containing non-ASCII
/// text (Arabic, in practice) is rasterized through [TsplBitmapText] rather
/// than sent as TSPL `TEXT` — confirmed on real hardware that this
/// printer's built-in font has no Arabic glyphs and prints unrelated
/// symbols when sent Arabic bytes directly. ASCII-only lines (case numbers,
/// dates) stay on the plain `TEXT` command, which is far cheaper to
/// transmit over BLE.
class CaseTicketRenderer {
  const CaseTicketRenderer._();

  static const _dotsPerMm = 8;

  /// The built-in layout used when a laboratory has not saved a template of
  /// its own yet — printing a case ticket must never be blocked on first
  /// having designed one.
  static const defaultTemplate = CaseTicketTemplateModel(
    id: 'default',
    name: 'التصميم الافتراضي',
    rows: [
      CaseTicketTemplateRowModel(
        id: 'default-masthead',
        kind: CaseTicketTemplateRowKind.masthead,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-qr',
        kind: CaseTicketTemplateRowKind.qr,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-case-number',
        kind: CaseTicketTemplateRowKind.caseNumber,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-reference-number',
        kind: CaseTicketTemplateRowKind.referenceNumber,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-divider-1',
        kind: CaseTicketTemplateRowKind.divider,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-patient',
        kind: CaseTicketTemplateRowKind.patient,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-doctor',
        kind: CaseTicketTemplateRowKind.doctor,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-location',
        kind: CaseTicketTemplateRowKind.location,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-priority',
        kind: CaseTicketTemplateRowKind.priority,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-impression-method',
        kind: CaseTicketTemplateRowKind.impressionMethod,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-received-at',
        kind: CaseTicketTemplateRowKind.receivedAt,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-expected-completion',
        kind: CaseTicketTemplateRowKind.expectedCompletion,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-divider-2',
        kind: CaseTicketTemplateRowKind.divider,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-restorations',
        kind: CaseTicketTemplateRowKind.restorationsTable,
      ),
      CaseTicketTemplateRowModel(
        id: 'default-notes',
        kind: CaseTicketTemplateRowKind.notes,
      ),
    ],
  );

  static Future<Uint8List> render({
    required CaseTicketTemplateModel template,
    required CasePrintTicketModel ticket,
  }) async {
    final widthDots = (template.paperWidthMm * _dotsPerMm).round();
    const margin = 20;
    const topMargin = 24;
    const bottomMargin = 24;

    final lines = <_Line>[];
    for (final row in template.rows) {
      if (!row.visible) continue;
      final line = _lineFor(row, ticket, template, widthDots, margin);
      if (line != null) lines.add(line);
    }

    final contentHeight = lines.fold<int>(0, (sum, l) => sum + l.heightDots);
    final heightDots = topMargin + contentHeight + bottomMargin;
    final heightMm = heightDots / _dotsPerMm;

    final builder = BytesBuilder()
      ..add(
        ascii.encode(
          'SIZE ${template.paperWidthMm} mm,${heightMm.toStringAsFixed(1)} mm\r\n',
        ),
      )
      ..add(ascii.encode('GAP 0 mm,0 mm\r\n'))
      ..add(ascii.encode('DIRECTION 1\r\n'))
      ..add(ascii.encode('CLS\r\n'));

    var y = topMargin;
    for (final line in lines) {
      await line.emit(builder, y);
      y += line.heightDots;
    }

    builder.add(ascii.encode('PRINT 1,1\r\n'));
    return builder.toBytes();
  }

  static _Line? _lineFor(
    CaseTicketTemplateRowModel row,
    CasePrintTicketModel ticket,
    CaseTicketTemplateModel template,
    int widthDots,
    int margin,
  ) {
    switch (row.kind) {
      case CaseTicketTemplateRowKind.masthead:
        final value = ticket.laboratoryName?.trim();
        if (value == null || value.isEmpty) return null;
        return _textLine(
          value,
          widthDots: widthDots,
          margin: margin,
          fontSize: row.fontSize ?? template.baseFontSizePx + 4,
          bold: row.bold ?? true,
          align: row.align ?? CaseTicketRowAlign.center,
        );

      case CaseTicketTemplateRowKind.qr:
        final payload = ticket.qrPayload?.trim();
        if (payload == null || payload.isEmpty) return null;
        return _qrLine(
          payload,
          widthDots: widthDots,
          sizeMm: row.qrSizeMm ?? 25,
          align: row.align ?? CaseTicketRowAlign.center,
        );

      case CaseTicketTemplateRowKind.divider:
        return _dividerLine(widthDots: widthDots, margin: margin);

      case CaseTicketTemplateRowKind.restorationsTable:
        if (ticket.restorations.isEmpty) return null;
        return _restorationsLine(
          ticket.restorations,
          widthDots: widthDots,
          margin: margin,
          fontSize: row.fontSize ?? template.baseFontSizePx,
          showTeeth: row.showTeeth ?? true,
          showShade: row.showShade ?? true,
          showNotes: row.showNotes ?? true,
        );

      case CaseTicketTemplateRowKind.customLabel:
        final value = row.text?.trim();
        if (value == null || value.isEmpty) return null;
        return _textLine(
          value,
          widthDots: widthDots,
          margin: margin,
          fontSize: row.fontSize ?? template.baseFontSizePx,
          bold: row.bold ?? false,
          align: row.align ?? CaseTicketRowAlign.start,
        );

      default:
        final value = _boundValue(row.kind, ticket);
        if (value == null || value.isEmpty) return null;
        final caption = row.label?.trim().isNotEmpty ?? false
            ? row.label!.trim()
            : row.kind.arabicLabel;
        return _textLine(
          '$caption: $value',
          widthDots: widthDots,
          margin: margin,
          fontSize: row.fontSize ?? template.baseFontSizePx,
          bold: row.bold ?? false,
          align: row.align ?? CaseTicketRowAlign.start,
        );
    }
  }

  static String? _boundValue(
    CaseTicketTemplateRowKind kind,
    CasePrintTicketModel ticket,
  ) {
    String? clean(String? value) {
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }

    return switch (kind) {
      CaseTicketTemplateRowKind.caseNumber => clean(ticket.caseNumber),
      CaseTicketTemplateRowKind.referenceNumber => clean(
        ticket.referenceNumber,
      ),
      CaseTicketTemplateRowKind.patient => clean(ticket.patientName),
      CaseTicketTemplateRowKind.doctor => clean(ticket.doctorName),
      CaseTicketTemplateRowKind.location => clean(ticket.locationLabel),
      CaseTicketTemplateRowKind.priority => clean(ticket.priorityLabel),
      CaseTicketTemplateRowKind.impressionMethod => clean(
        ticket.impressionMethodLabelAr,
      ),
      CaseTicketTemplateRowKind.createdAt => _formatDate(ticket.createdAt),
      CaseTicketTemplateRowKind.receivedAt => _formatDate(ticket.receivedAt),
      CaseTicketTemplateRowKind.expectedCompletion => _formatDate(
        ticket.expectedCompletionAt,
      ),
      CaseTicketTemplateRowKind.notes => clean(ticket.notes),
      _ => null,
    };
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  /// TSPL's built-in bitmap fonts come in fixed sizes, not arbitrary pixel
  /// values — this buckets a requested size into the nearest one. Only used
  /// on the ASCII (native `TEXT`) path.
  static String _fontFor(double fontSizePx) {
    if (fontSizePx <= 9) return '1';
    if (fontSizePx <= 13) return '2';
    if (fontSizePx <= 18) return '3';
    return '4';
  }

  static int _lineHeightFor(double fontSizePx, {bool bold = false}) {
    final base = (fontSizePx * 3).round();
    return (bold ? (base * 1.6) : base.toDouble()).round().clamp(24, 200);
  }

  /// No text-measurement command exists in TSPL — this estimates printed
  /// width from character count so start/center/end alignment has something
  /// to work with on the ASCII path. Digits and Latin letters are close
  /// enough to fixed-width in the printer's built-in font for this to hold.
  static int _estimatedWidth(String text, String font, int mult) {
    final perChar = switch (font) {
      '1' => 10,
      '2' => 14,
      '3' => 18,
      _ => 24,
    };
    return text.length * perChar * mult;
  }

  /// Builds an ASCII-or-bitmap piece for one line of text within a
  /// [boxWidth]-wide content box. The ASCII path keeps the old estimated
  /// width + explicit x math; the bitmap path renders across the full box
  /// and lets Flutter's own [TextAlign] place it, which is also what makes
  /// multi-line wrapping (a long note, a long name) come out positioned
  /// correctly instead of running off the paper.
  static _Prepared _prepareText(
    String text, {
    required int boxWidth,
    required double fontSize,
    required bool bold,
    required CaseTicketRowAlign align,
  }) {
    final sanitized = _sanitize(text);

    if (TsplBitmapText.isAsciiSafe(sanitized)) {
      final font = _fontFor(fontSize);
      final mult = bold ? 2 : 1;
      final height = _lineHeightFor(fontSize, bold: bold);
      final estWidth = _estimatedWidth(sanitized, font, mult);
      final x = switch (align) {
        CaseTicketRowAlign.center => ((boxWidth - estWidth) / 2)
            .round()
            .clamp(0, boxWidth),
        CaseTicketRowAlign.end => (boxWidth - estWidth).clamp(0, boxWidth),
        CaseTicketRowAlign.start => 0,
      };
      return (
        height: height,
        emit: (builder, boxX, y) async => builder.add(
          ascii.encode(
            'TEXT ${boxX + x},$y,"$font",0,$mult,$mult,"$sanitized"\r\n',
          ),
        ),
      );
    }

    final painter = TextPainter(
      text: TextSpan(
        text: sanitized,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: const Color(0xFF000000),
        ),
      ),
      textAlign: switch (align) {
        CaseTicketRowAlign.center => TextAlign.center,
        CaseTicketRowAlign.end => TextAlign.right,
        CaseTicketRowAlign.start => TextAlign.left,
      },
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: boxWidth.toDouble());

    final height = painter.height.ceil().clamp(1, 4000);
    return (
      height: height,
      emit: (builder, boxX, y) async {
        final packed = await TsplBitmapText.rasterize(
          painter: painter,
          width: boxWidth,
          height: height,
        );
        TsplBitmapText.writeBitmapCommand(
          builder,
          x: boxX,
          y: y,
          width: boxWidth,
          height: height,
          packed: packed,
        );
      },
    );
  }

  static _Line _textLine(
    String text, {
    required int widthDots,
    required int margin,
    required double fontSize,
    required bool bold,
    required CaseTicketRowAlign align,
  }) {
    final boxWidth = (widthDots - margin * 2).clamp(1, widthDots);
    final prepared = _prepareText(
      text,
      boxWidth: boxWidth,
      fontSize: fontSize,
      bold: bold,
      align: align,
    );
    return _Line(
      heightDots: prepared.height,
      emit: (builder, y) => prepared.emit(builder, margin, y),
    );
  }

  static _Line _qrLine(
    String payload, {
    required int widthDots,
    required double sizeMm,
    required CaseTicketRowAlign align,
  }) {
    final sizeDots = (sizeMm * _dotsPerMm).round();
    // Same worst-case-module assumption `buildCaseLabel` documents: sized
    // generously so a longer payload does not run the code off the paper.
    final cellSize = (sizeDots / 33).round().clamp(1, 20);
    final qrSizeDots = cellSize * 33;

    final x = switch (align) {
      CaseTicketRowAlign.center => ((widthDots - qrSizeDots) / 2).round().clamp(
        0,
        widthDots,
      ),
      CaseTicketRowAlign.end => (widthDots - qrSizeDots).clamp(0, widthDots),
      CaseTicketRowAlign.start => 0,
    };

    return _Line(
      heightDots: qrSizeDots,
      emit: (builder, y) async => builder.add(
        ascii.encode(
          'QRCODE $x,$y,L,$cellSize,A,0,"${_sanitize(payload)}"\r\n',
        ),
      ),
    );
  }

  static _Line _dividerLine({required int widthDots, required int margin}) {
    const height = 16;
    final barWidth = (widthDots - margin * 2).clamp(0, widthDots);
    return _Line(
      heightDots: height,
      emit: (builder, y) async => builder.add(
        ascii.encode('BAR $margin,${y + height ~/ 2},$barWidth,2\r\n'),
      ),
    );
  }

  static _Line _restorationsLine(
    List<PrintTicketRestorationModel> restorations, {
    required int widthDots,
    required int margin,
    required double fontSize,
    required bool showTeeth,
    required bool showShade,
    required bool showNotes,
  }) {
    final boxWidth = (widthDots - margin * 2).clamp(1, widthDots);

    final entries = <String>[];
    for (final restoration in restorations) {
      final title = restoration.displayName.isEmpty
          ? 'تعويض'
          : restoration.displayName;
      entries.add(
        restoration.quantity > 1
            ? '- $title × ${restoration.quantity}'
            : '- $title',
      );
      if (showTeeth && restoration.teeth.isNotEmpty) {
        entries.add('  الأسنان: ${restoration.teeth.join(', ')}');
      }
      if (showShade && restoration.shadeSummary.isNotEmpty) {
        entries.add('  اللون: ${restoration.shadeSummary}');
      }
      if (showNotes && (restoration.notes?.trim().isNotEmpty ?? false)) {
        entries.add('  ملاحظة: ${restoration.notes!.trim()}');
      }
    }

    final header = _prepareText(
      'التعويضات',
      boxWidth: boxWidth,
      fontSize: fontSize,
      bold: true,
      align: CaseTicketRowAlign.start,
    );
    final entryPieces = [
      for (final entry in entries)
        _prepareText(
          entry,
          boxWidth: boxWidth,
          fontSize: fontSize * 0.85,
          bold: false,
          align: CaseTicketRowAlign.start,
        ),
    ];

    final totalHeight =
        header.height + entryPieces.fold<int>(0, (sum, p) => sum + p.height);

    return _Line(
      heightDots: totalHeight,
      emit: (builder, y) async {
        await header.emit(builder, margin, y);
        var lineY = y + header.height;
        for (final piece in entryPieces) {
          await piece.emit(builder, margin, lineY);
          lineY += piece.height;
        }
      },
    );
  }

  /// TSPL reads `"` as the end of a text field — same escaping
  /// [LabelPrinterService.buildCaseLabel] applies.
  static String _sanitize(String value) => value.replaceAll('"', "'");
}
