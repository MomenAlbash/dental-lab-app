import 'package:dental_lab_app/features/scanner_sessions/data/models/digital_scan_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScannerSessionMessageModel', () {
    test('an unread message has no read date rather than a defaulted one', () {
      final message = ScannerSessionMessageModel.fromJson(const {
        'id': 'm1',
        'message': 'السكنر فاضي بكير',
      });

      expect(message.readAt, isNull);
      expect(message.isRead, isFalse);
    });

    test('a read receipt is carried through', () {
      final message = ScannerSessionMessageModel.fromJson(const {
        'id': 'm1',
        'readAt': '2026-09-12T10:00:00Z',
      });

      expect(message.isRead, isTrue);
    });

    test('isMine and isFromDoctor are independent', () {
      // A colleague's message: not mine, but still the lab's — drawing it on
      // the doctor's side would misattribute what the lab itself promised.
      final colleague = ScannerSessionMessageModel.fromJson(const {
        'id': 'm1',
        'isMine': false,
        'isFromDoctor': false,
      });

      expect(colleague.isMine, isFalse);
      expect(colleague.isFromDoctor, isFalse);
    });

    test('an edited message is marked as such in its time label', () {
      final edited = ScannerSessionMessageModel.fromJson(const {
        'id': 'm1',
        'sentAt': '2026-09-12T10:00:00Z',
        'editedAt': '2026-09-12T10:05:00Z',
      });

      expect(edited.wasEdited, isTrue);
      expect(edited.timeLabel, contains('مُعدَّل'));
    });

    test('an unedited message carries no edit marker', () {
      final plain = ScannerSessionMessageModel.fromJson(const {
        'id': 'm1',
        'sentAt': '2026-09-12T10:00:00Z',
      });

      expect(plain.wasEdited, isFalse);
      expect(plain.timeLabel, isNot(contains('مُعدَّل')));
    });
  });

  group('DigitalScanModel', () {
    test('a removed file is still a readable row — the record outlives it', () {
      final scan = DigitalScanModel.fromJson(const {
        'id': 's1',
        'fileName': 'upper.stl',
        'fileState': 2,
        'removalReason': 1,
        'fileRemovedAt': '2026-09-12T10:00:00Z',
      });

      expect(scan.isStored, isFalse);
      expect(scan.displayName, 'upper.stl');
      expect(scan.removalReason, DigitalScanRemovalReason.retentionAge);
    });

    test('a NAS-archived scan is retrievable even with the file removed', () {
      final scan = DigitalScanModel.fromJson(const {
        'id': 's1',
        'fileState': 2,
        'removalReason': 4,
        'isArchivedAtLaboratory': true,
      });

      expect(scan.isStored, isFalse);
      expect(scan.isRetrievable, isTrue);
    });

    test('a swept scan with no archive copy is not retrievable', () {
      final scan = DigitalScanModel.fromJson(const {
        'id': 's1',
        'fileState': 2,
        'removalReason': 2,
      });

      expect(scan.isRetrievable, isFalse);
    });

    test('sizeLabel scales to the unit instead of printing raw bytes', () {
      final megabytes = DigitalScanModel.fromJson(const {
        'id': 's1',
        'fileSizeBytes': 13002342,
      });

      expect(megabytes.sizeLabel, contains('م.ب'));
    });

    test('a small file stays in bytes with no misleading fraction', () {
      final bytes = DigitalScanModel.fromJson(const {
        'id': 's1',
        'fileSizeBytes': 512,
      });

      expect(bytes.sizeLabel, '512 بايت');
    });

    test('an unreported size is a dash, not a confident zero', () {
      final unknown = DigitalScanModel.fromJson(const {'id': 's1'});

      expect(unknown.sizeLabel, '—');
    });

    test('a session scan has no case yet — the case is what it produces', () {
      final scan = DigitalScanModel.fromJson(const {
        'id': 's1',
        'scannerSessionId': 'sess1',
        'source': 2,
      });

      expect(scan.caseId, isNull);
      expect(scan.source, DigitalScanSource.labScannerSession);
    });
  });

  group('DigitalScanRole', () {
    test('every wire value maps to a labelled role', () {
      for (final role in DigitalScanRole.values) {
        expect(DigitalScanRole.fromValue(role.value), role);
        expect(role.label, isNotEmpty);
      }
    });

    test('an unknown value degrades to null rather than a wrong arch', () {
      expect(DigitalScanRole.fromValue(99), isNull);
      expect(DigitalScanRole.fromValue(null), isNull);
    });
  });
}
