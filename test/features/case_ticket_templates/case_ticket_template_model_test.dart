import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_kind.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseTicketTemplateModel', () {
    test('parses full detail with its rows', () {
      final template = CaseTicketTemplateModel.fromJson(const {
        'id': 't1',
        'name': 'طابعة الاستقبال',
        'isDefault': true,
        'paperWidthMm': 125,
        'baseFontSizePx': 12,
        'rows': [
          {'id': 'r1', 'kind': 'masthead'},
          {'id': 'r2', 'kind': 'qr', 'qrSizeMm': 30},
        ],
      });

      expect(template.name, 'طابعة الاستقبال');
      expect(template.isDefault, isTrue);
      expect(template.paperWidthMm, 125);
      expect(template.rows, hasLength(2));
    });

    test('a bare template defaults to 80mm/24px and no rows', () {
      final template = CaseTicketTemplateModel.fromJson(const {'id': 't1'});

      expect(template.paperWidthMm, 80);
      expect(template.baseFontSizePx, 24);
      expect(template.rows, isEmpty);
      expect(template.isDefault, isFalse);
    });
  });

  group('CaseTicketTemplateListItemModel', () {
    test('parses a list row with no content', () {
      final item = CaseTicketTemplateListItemModel.fromJson(const {
        'id': 't1',
        'name': 'طابعة الاستقبال',
        'isDefault': false,
        'paperWidthMm': 58,
        'updatedAt': '2026-09-01T00:00:00Z',
      });

      expect(item.name, 'طابعة الاستقبال');
      expect(item.paperWidthMm, 58);
      expect(item.updatedAt, DateTime.parse('2026-09-01T00:00:00Z'));
    });
  });

  group('CreateCaseTicketTemplateRequestModel', () {
    test('sends the name', () {
      final json = const CreateCaseTicketTemplateRequestModel(
        name: 'طابعة جديدة',
      ).toJson();

      expect(json, {'name': 'طابعة جديدة'});
    });

    test('refuses an empty name', () {
      expect(
        () => CreateCaseTicketTemplateRequestModel(name: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('refuses a name past the API cap', () {
      expect(
        () => CreateCaseTicketTemplateRequestModel(name: 'x' * 201),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('UpdateCaseTicketTemplateRequestModel', () {
    test('sends the whole row list — a full replace, not a patch', () {
      final json = UpdateCaseTicketTemplateRequestModel(
        name: 'طابعة الاستقبال',
        paperWidthMm: 125,
        baseFontSizePx: 12,
        rows: const [],
      ).toJson();

      expect(json['name'], 'طابعة الاستقبال');
      expect(json['paperWidthMm'], 125);
      expect(json['rows'], isEmpty);
    });

    test(
      'a null row list omits rows from the JSON value, not an empty one',
      () {
        final json = const UpdateCaseTicketTemplateRequestModel(
          name: 'طابعة الاستقبال',
        ).toJson();

        expect(json['rows'], isNull);
      },
    );

    test('refuses more than 60 rows', () {
      const row = CaseTicketTemplateRowModel(
        id: 'r1',
        kind: CaseTicketTemplateRowKind.divider,
      );

      expect(
        () => UpdateCaseTicketTemplateRequestModel(
          name: 'طابعة الاستقبال',
          rows: List.filled(61, row),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
