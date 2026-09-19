import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /Laboratories/{id}` — the full `LaboratoryDto`.
const _fullDto = {
  'id': 'lab-1',
  'name': 'مخبر الابتسامة',
  'address': 'دمشق',
  'phoneNumber': '0112223344',
  'isActive': true,
  'userCount': 5,
  'doctorCount': 8,
  'caseCount': 142,
  'maxMessageAttachmentsPerCase': 10,
  'maxMessageImageSizeMb': 5,
  'maxMessageVideoSizeMb': 50,
  'maxMessageAudioSizeMb': 8,
  'maxMessageFileSizeMb': 20,
  'controlDeliveryReminderHours': 24,
  'scanRetentionEnabled': true,
  'scanRetentionDays': 90,
  'scanRetentionOnlyClosedCases': false,
  'scanStorageBudgetGb': 100,
  'scanStorageWarnPercent': 80,
};

/// `GET /Laboratories/own` — the narrower `ClinicLaboratoryDto`: no counts, no
/// isActive, no scan settings.
const _ownDto = {
  'id': 'lab-1',
  'name': 'مخبر الابتسامة',
  'address': 'دمشق',
  'phoneNumber': '0112223344',
  'maxMessageAttachmentsPerCase': 10,
  'maxMessageImageSizeMb': 5,
  'maxMessageVideoSizeMb': 50,
  'maxMessageAudioSizeMb': 8,
  'maxMessageFileSizeMb': 20,
};

void main() {
  group('LaboratoryDto (list / by id)', () {
    test('parses the counts', () {
      final lab = LaboratoryModel.fromJson(_fullDto);

      expect(lab.userCount, 5);
      expect(lab.doctorCount, 8);
      expect(lab.caseCount, 142);
      expect(lab.isActive, isTrue);
      expect(lab.hasCounts, isTrue);
    });

    test('parses the message limits', () {
      final lab = LaboratoryModel.fromJson(_fullDto);

      expect(lab.maxMessageAttachmentsPerCase, 10);
      expect(lab.maxMessageImageSizeMb, 5);
      expect(lab.maxMessageVideoSizeMb, 50);
      expect(lab.maxMessageAudioSizeMb, 8);
      expect(lab.maxMessageFileSizeMb, 20);
      expect(lab.hasMessageLimits, isTrue);
    });

    test('parses the reminder and scan storage settings', () {
      final lab = LaboratoryModel.fromJson(_fullDto);

      expect(lab.controlDeliveryReminderHours, 24);
      expect(lab.scanRetentionEnabled, isTrue);
      expect(lab.scanRetentionDays, 90);
      expect(lab.scanRetentionOnlyClosedCases, isFalse);
      expect(lab.scanStorageBudgetGb, 100);
      expect(lab.scanStorageWarnPercent, 80);
      expect(lab.hasScanSettings, isTrue);
    });
  });

  group('ClinicLaboratoryDto (own)', () {
    test('leaves the counts null instead of reporting zero', () {
      final lab = LaboratoryModel.fromJson(_ownDto);

      expect(lab.userCount, isNull);
      expect(lab.doctorCount, isNull);
      expect(lab.caseCount, isNull);
      expect(lab.hasCounts, isFalse);
    });

    test('leaves isActive null instead of assuming active', () {
      final lab = LaboratoryModel.fromJson(_ownDto);

      expect(lab.isActive, isNull);
    });

    test('still carries the message limits', () {
      final lab = LaboratoryModel.fromJson(_ownDto);

      expect(lab.hasMessageLimits, isTrue);
      expect(lab.maxMessageVideoSizeMb, 50);
    });

    test('reports no scan settings', () {
      final lab = LaboratoryModel.fromJson(_ownDto);

      expect(lab.hasScanSettings, isFalse);
      expect(lab.scanRetentionDays, isNull);
    });
  });

  group('toJson', () {
    test('round-trips every field', () {
      final lab = LaboratoryModel.fromJson(_fullDto);
      final again = LaboratoryModel.fromJson(lab.toJson());

      expect(again.caseCount, 142);
      expect(again.scanStorageWarnPercent, 80);
      expect(again.maxMessageFileSizeMb, 20);
    });

    test('omits unreported fields so a cached copy cannot invent zeros', () {
      final lab = LaboratoryModel.fromJson(_ownDto);
      final json = lab.toJson();

      expect(json.containsKey('caseCount'), isFalse);
      expect(json.containsKey('isActive'), isFalse);
      expect(LaboratoryModel.fromJson(json).hasCounts, isFalse);
    });
  });
}
