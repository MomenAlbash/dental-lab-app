import 'package:dental_lab_app/features/scan_storage/data/models/scan_storage_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/digital_scan_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatBytes', () {
    test('bytes carry no misleading fraction', () {
      expect(formatBytes(512), '512 بايت');
    });

    test('scales up to the readable unit', () {
      expect(formatBytes(13 * 1024 * 1024), contains('م.ب'));
      expect(formatBytes(5 * 1024 * 1024 * 1024), contains('غ.ب'));
    });

    test('zero is zero, not an empty string', () {
      expect(formatBytes(0), '0 بايت');
    });
  });

  group('ScanStorageModel', () {
    test('usageFraction is clamped — over budget is an ordinary state', () {
      final over = ScanStorageModel.fromJson(const {
        'usagePercent': 140,
        'isOverBudget': true,
      });

      expect(over.usageFraction, 1.0);
      expect(over.isOverBudget, isTrue);
    });

    test('usagePercent is read from the server, not divided locally', () {
      // 3 of 10 bytes, but the server says 42 — the server wins, because its
      // number is the one the sweep decides against.
      final storage = ScanStorageModel.fromJson(const {
        'storedBytes': 3,
        'budgetBytes': 10,
        'usagePercent': 42,
      });

      expect(storage.usagePercent, 42);
    });

    test('hasSomethingToSweep is false when nothing is eligible', () {
      final storage = ScanStorageModel.fromJson(const {
        'storedCount': 500,
        'eligibleNowCount': 0,
      });

      expect(storage.hasSomethingToSweep, isFalse);
    });

    test('over budget with nothing eligible is carried as its own flag', () {
      final stuck = ScanStorageModel.fromJson(const {
        'isOverBudget': true,
        'eligibleNowCount': 0,
        'overBudgetAndNothingEligible': true,
      });

      expect(stuck.overBudgetAndNothingEligible, isTrue);
      expect(stuck.hasSomethingToSweep, isFalse);
    });

    test('the largest and removed lists parse', () {
      final storage = ScanStorageModel.fromJson(const {
        'largestStored': [
          {
            'id': 's1',
            'fileName': 'upper.stl',
            'fileSizeBytes': 2048,
            'isEligibleForAutomaticRemoval': true,
          },
        ],
        'recentRemovals': [
          {'id': 's2', 'fileName': 'lower.stl', 'removalReason': 4},
        ],
      });

      expect(storage.largestStored.single.isEligibleForAutomaticRemoval, isTrue);
      expect(storage.recentRemovals.single.isArchived, isTrue);
    });
  });

  group('RemovedScanModel', () {
    test('an archived scan is distinguished from a swept one', () {
      final archived = RemovedScanModel.fromJson(const {
        'id': 's1',
        'removalReason': 4,
      });
      final swept = RemovedScanModel.fromJson(const {
        'id': 's2',
        'removalReason': 1,
      });

      expect(archived.isArchived, isTrue);
      expect(swept.isArchived, isFalse);
      expect(swept.removalReason, DigitalScanRemovalReason.retentionAge);
    });
  });

  group('ScanRetentionRunResultModel', () {
    test('a run that leaves the lab over budget says so', () {
      final result = ScanRetentionRunResultModel.fromJson(const {
        'removedCount': 12,
        'reclaimedBytes': 1024,
        'stillOverBudget': true,
      });

      expect(result.removedCount, 12);
      expect(result.stillOverBudget, isTrue);
    });

    test('missing files are reported so the numbers add up', () {
      final result = ScanRetentionRunResultModel.fromJson(const {
        'removedCount': 5,
        'missingFileCount': 2,
        'reclaimedBytes': 0,
      });

      expect(result.missingFileCount, 2);
      expect(result.reclaimedBytes, 0);
    });
  });

  group('ConfirmNasArchiveRequestModel', () {
    test('each item carries where the copy went', () {
      final json = const ConfirmNasArchiveRequestModel(
        items: [
          ConfirmNasArchiveItemModel(
            scanId: 's1',
            nasPath: '/nas/scans/upper.stl',
          ),
        ],
      ).toJson();

      final items = json['items'] as List;
      expect(items.single['scanId'], 's1');
      expect(items.single['nasPath'], '/nas/scans/upper.stl');
    });

    test('an unrecorded path is sent as null, not omitted', () {
      final json = const ConfirmNasArchiveRequestModel(
        items: [ConfirmNasArchiveItemModel(scanId: 's1')],
      ).toJson();

      final items = json['items'] as List;
      expect((items.single as Map).containsKey('nasPath'), isTrue);
      expect(items.single['nasPath'], isNull);
    });
  });
}
