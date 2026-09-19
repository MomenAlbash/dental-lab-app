import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_row_align.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_kind.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseTicketTemplateRowKind', () {
    test('round-trips every kind through its wire value', () {
      for (final kind in CaseTicketTemplateRowKind.values) {
        expect(CaseTicketTemplateRowKind.fromApi(kind.apiValue), kind);
      }
    });

    test('an unrecognised kind reads as null, not an error', () {
      expect(CaseTicketTemplateRowKind.fromApi('somethingNew'), isNull);
    });

    test('masthead and divider have no editable label', () {
      expect(CaseTicketTemplateRowKind.masthead.hasEditableLabel, isFalse);
      expect(CaseTicketTemplateRowKind.divider.hasEditableLabel, isFalse);
      expect(
        CaseTicketTemplateRowKind.restorationsTable.hasEditableLabel,
        isFalse,
      );
      expect(CaseTicketTemplateRowKind.qr.hasEditableLabel, isFalse);
    });

    test('a key/value row has an editable label', () {
      expect(CaseTicketTemplateRowKind.patient.hasEditableLabel, isTrue);
      expect(CaseTicketTemplateRowKind.doctor.hasEditableLabel, isTrue);
    });
  });

  group('CaseTicketTemplateRowModel', () {
    test('parses a full row and writes the same shape back', () {
      final row = CaseTicketTemplateRowModel.fromJson(const {
        'id': 'r1',
        'kind': 'qr',
        'visible': true,
        'qrSizeMm': 30,
        'align': 'center',
      });

      expect(row.kind, CaseTicketTemplateRowKind.qr);
      expect(row.qrSizeMm, 30);
      expect(row.align, CaseTicketRowAlign.center);

      final json = row.toJson();
      expect(json['kind'], 'qr');
      expect(json['align'], 'center');
      expect(json['qrSizeMm'], 30);
    });

    test('a bare row defaults to visible', () {
      final row = CaseTicketTemplateRowModel.fromJson(const {
        'id': 'r1',
        'kind': 'divider',
      });

      expect(row.visible, isTrue);
      expect(row.label, isNull);
    });

    test('copyWith can clear the label explicitly', () {
      const row = CaseTicketTemplateRowModel(
        id: 'r1',
        kind: CaseTicketTemplateRowKind.patient,
        label: 'المريض',
      );

      final cleared = row.copyWith(clearLabel: true);

      expect(cleared.label, isNull);
      // Nothing else moved.
      expect(cleared.kind, CaseTicketTemplateRowKind.patient);
    });
  });
}
