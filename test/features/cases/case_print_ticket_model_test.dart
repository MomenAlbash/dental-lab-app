import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CasePrintTicketModel', () {
    test('parses the full ticket, priorityLabel prefers Arabic', () {
      final ticket = CasePrintTicketModel.fromJson(const {
        'caseNumber': 'LAB-000123',
        'qrPayload': 'LAB-000123',
        'referenceNumber': 'REF-9',
        'patientName': 'Ahmed Ali',
        'doctorNumber': 42,
        'doctorName': 'Dr. Sara',
        'doctorCountry': 'مصر',
        'doctorCity': 'القاهرة',
        'doctorArea': 'مدينة نصر',
        'laboratoryName': 'مخبر M2',
        'priorityName': 'Rush',
        'priorityNameAr': 'مستعجل',
        'impressionMethodLabelAr': 'بصمة تقليدية',
        'createdAt': '2026-09-02T10:00:00Z',
        'expectedCompletionAt': '2026-09-05T00:00:00Z',
        'notes': 'handle with care',
      });

      expect(ticket.priorityLabel, 'مستعجل');
      expect(ticket.locationLabel, 'مصر / القاهرة / مدينة نصر');
      expect(ticket.receivedAt, isNull);
      expect(ticket.createdAt, DateTime.parse('2026-09-02T10:00:00Z'));
    });

    test('a bare ticket has no location line, not an empty one', () {
      final ticket = CasePrintTicketModel.fromJson(const {
        'caseNumber': 'LAB-000123',
      });

      expect(ticket.locationLabel, isNull);
      expect(ticket.priorityLabel, isNull);
      expect(ticket.restorations, isEmpty);
    });

    test('priorityLabel falls back to English when Arabic is missing', () {
      final ticket = CasePrintTicketModel.fromJson(const {
        'priorityName': 'Rush',
      });

      expect(ticket.priorityLabel, 'Rush');
    });
  });

  group('PrintTicketRestorationModel', () {
    test('resolves shade codes to Vita labels through ShadeCodes', () {
      final restoration = PrintTicketRestorationModel.fromJson(const {
        'restorationNumber': 'LAB-000123-01',
        'typeNameAr': 'تاج',
        'quantity': 1,
        'teeth': [14, 15],
        'shadeSystem': 1, // Vita Classical
        'shadeCervical': 2, // A3
        'shadeMiddle': 2, // A3
        'shadeIncisal': 1, // A2
        'baseShade': 3, // A3.5
      });

      expect(restoration.displayName, 'تاج');
      expect(restoration.teeth, [14, 15]);
      expect(restoration.shadeCervicalLabel, 'A3');
      expect(restoration.shadeIncisalLabel, 'A2');
      expect(restoration.baseShadeLabel, 'A3.5');
      expect(restoration.shadeSummary, 'A3 / A3 / A2');
    });

    test('no shade set at all reads as an empty summary', () {
      final restoration = PrintTicketRestorationModel.fromJson(const {
        'restorationNumber': 'LAB-000123-01',
      });

      expect(restoration.shadeSummary, isEmpty);
      expect(restoration.shadeCervicalLabel, isNull);
    });
  });
}
