import 'dart:convert';

import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_row_align.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_kind.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_render/case_ticket_renderer.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ticket = CasePrintTicketModel(
    caseNumber: 'CS-100',
    qrPayload: 'CS-100',
    referenceNumber: 'REF-9',
    patientName: 'مريض تجريبي',
    doctorName: 'د. أحمد',
    doctorCountry: 'سوريا',
    doctorCity: 'دمشق',
    laboratoryName: 'مخبر الأسنان',
    priorityNameAr: 'عاجل',
    impressionMethodLabelAr: 'مسح ضوئي',
    notes: 'يرجى الانتباه للون',
    restorations: [
      PrintTicketRestorationModel(
        restorationNumber: 'CS-100-01',
        typeNameAr: 'تاج زيركون',
        quantity: 2,
        teeth: [11, 12],
        shadeSystem: 1,
        shadeCervical: 2,
        shadeMiddle: 2,
        shadeIncisal: 1,
        notes: 'حافة رقيقة',
      ),
    ],
  );

  /// The ASCII-only slice of the byte stream that TSPL commands live in —
  /// Arabic lines are rasterized to BITMAP now and no longer appear as
  /// literal text, so assertions on them check structure (a BITMAP command
  /// exists, the line isn't skipped) rather than byte content. Latin1
  /// decoding is safe here since ASCII command text and raw bitmap bytes
  /// never collide with each other in a way that changes byte counts.
  String asLatin1(List<int> bytes) => latin1.decode(bytes, allowInvalid: true);

  test(
    'the default template renders every bound field it carries',
    () async {
      final bytes = await CaseTicketRenderer.render(
        template: CaseTicketRenderer.defaultTemplate,
        ticket: ticket,
      );
      final tspl = asLatin1(bytes);

      expect(tspl, contains('SIZE'));
      expect(tspl, contains('CLS'));
      expect(tspl, contains('PRINT 1,1'));
      expect(tspl, contains('QRCODE'));
      expect(tspl, contains('CS-100'));
      expect(tspl, contains('BAR'));
      // Every Arabic-bearing row (masthead, patient, doctor, location,
      // priority, impression method, notes, restorations header) rasterizes
      // to its own BITMAP command — one per row is the minimum bound.
      final bitmapCount = 'BITMAP'.allMatches(tspl).length;
      expect(bitmapCount, greaterThanOrEqualTo(8));
    },
  );

  test('a bound row with no data on the ticket prints no line', () async {
    const template = CaseTicketTemplateModel(
      id: 't1',
      rows: [
        CaseTicketTemplateRowModel(
          id: 'r1',
          kind: CaseTicketTemplateRowKind.receivedAt,
        ),
      ],
    );

    final bytes = await CaseTicketRenderer.render(
      template: template,
      ticket: const CasePrintTicketModel(),
    );
    final tspl = asLatin1(bytes);

    expect(tspl, isNot(contains('TEXT')));
    expect(tspl, isNot(contains('BITMAP')));
  });

  test('an invisible row is skipped entirely', () async {
    const template = CaseTicketTemplateModel(
      id: 't1',
      rows: [
        CaseTicketTemplateRowModel(
          id: 'r1',
          kind: CaseTicketTemplateRowKind.patient,
          visible: false,
        ),
      ],
    );

    final bytes = await CaseTicketRenderer.render(
      template: template,
      ticket: ticket,
    );
    final tspl = asLatin1(bytes);

    expect(tspl, isNot(contains('BITMAP')));
  });

  test('a label override replaces the default caption', () async {
    const template = CaseTicketTemplateModel(
      id: 't1',
      rows: [
        CaseTicketTemplateRowModel(
          id: 'r1',
          kind: CaseTicketTemplateRowKind.patient,
          label: 'اسم المريض',
        ),
      ],
    );

    final withOverride = await CaseTicketRenderer.render(
      template: template,
      ticket: ticket,
    );
    const defaultTemplate = CaseTicketTemplateModel(
      id: 't2',
      rows: [
        CaseTicketTemplateRowModel(
          id: 'r1',
          kind: CaseTicketTemplateRowKind.patient,
        ),
      ],
    );
    final withDefault = await CaseTicketRenderer.render(
      template: defaultTemplate,
      ticket: ticket,
    );

    // Different caption text rasterizes to a different bitmap, so the raw
    // byte streams diverge even though neither shows the caption literally.
    expect(withOverride, isNot(equals(withDefault)));
  });

  test('a restorations table with no restorations prints no line', () async {
    const template = CaseTicketTemplateModel(
      id: 't1',
      rows: [
        CaseTicketTemplateRowModel(
          id: 'r1',
          kind: CaseTicketTemplateRowKind.restorationsTable,
        ),
      ],
    );

    final bytes = await CaseTicketRenderer.render(
      template: template,
      ticket: const CasePrintTicketModel(),
    );
    final tspl = asLatin1(bytes);

    expect(tspl, isNot(contains('BITMAP')));
  });

  test(
    'restorationsTable flags hide their matching sub-lines',
    () async {
      const fullTemplate = CaseTicketTemplateModel(
        id: 't1',
        rows: [
          CaseTicketTemplateRowModel(
            id: 'r1',
            kind: CaseTicketTemplateRowKind.restorationsTable,
          ),
        ],
      );
      const hiddenTemplate = CaseTicketTemplateModel(
        id: 't2',
        rows: [
          CaseTicketTemplateRowModel(
            id: 'r1',
            kind: CaseTicketTemplateRowKind.restorationsTable,
            showTeeth: false,
            showShade: false,
            showNotes: false,
          ),
        ],
      );

      final fullBytes = await CaseTicketRenderer.render(
        template: fullTemplate,
        ticket: ticket,
      );
      final hiddenBytes = await CaseTicketRenderer.render(
        template: hiddenTemplate,
        ticket: ticket,
      );

      // Hiding three of the four sub-lines per restoration must shrink the
      // rendered block — fewer BITMAP commands, and a smaller byte stream.
      final fullBitmapCount = 'BITMAP'.allMatches(asLatin1(fullBytes)).length;
      final hiddenBitmapCount = 'BITMAP'
          .allMatches(asLatin1(hiddenBytes))
          .length;
      expect(hiddenBitmapCount, lessThan(fullBitmapCount));
      expect(hiddenBytes.length, lessThan(fullBytes.length));
    },
  );

  test('an empty custom label row prints no line', () async {
    const template = CaseTicketTemplateModel(
      id: 't1',
      rows: [
        CaseTicketTemplateRowModel(
          id: 'r1',
          kind: CaseTicketTemplateRowKind.customLabel,
        ),
      ],
    );

    final bytes = await CaseTicketRenderer.render(
      template: template,
      ticket: const CasePrintTicketModel(),
    );
    final tspl = asLatin1(bytes);

    expect(tspl, isNot(contains('TEXT')));
    expect(tspl, isNot(contains('BITMAP')));
  });

  test('a custom label row with ASCII text stays on the TEXT command', () async {
    const template = CaseTicketTemplateModel(
      id: 't1',
      rows: [
        CaseTicketTemplateRowModel(
          id: 'r1',
          kind: CaseTicketTemplateRowKind.customLabel,
          text: 'Thank you',
          align: CaseTicketRowAlign.center,
        ),
      ],
    );

    final bytes = await CaseTicketRenderer.render(
      template: template,
      ticket: const CasePrintTicketModel(),
    );
    final tspl = asLatin1(bytes);

    expect(tspl, contains('TEXT'));
    expect(tspl, contains('Thank you'));
    expect(tspl, isNot(contains('BITMAP')));
  });

  test(
    'a custom label row with Arabic text rasterizes to a bitmap',
    () async {
      const template = CaseTicketTemplateModel(
        id: 't1',
        rows: [
          CaseTicketTemplateRowModel(
            id: 'r1',
            kind: CaseTicketTemplateRowKind.customLabel,
            text: 'شكراً لثقتكم',
            align: CaseTicketRowAlign.center,
          ),
        ],
      );

      final bytes = await CaseTicketRenderer.render(
        template: template,
        ticket: const CasePrintTicketModel(),
      );
      final tspl = asLatin1(bytes);

      expect(tspl, contains('BITMAP'));
      expect(tspl, isNot(contains('شكراً')));
    },
  );

  test(
    'a template with no printable rows still emits a valid header/footer',
    () async {
      const template = CaseTicketTemplateModel(id: 't1', rows: []);

      final bytes = await CaseTicketRenderer.render(
        template: template,
        ticket: const CasePrintTicketModel(),
      );
      final tspl = asLatin1(bytes);

      expect(tspl, contains('SIZE'));
      expect(tspl, contains('PRINT 1,1'));
    },
  );
}
