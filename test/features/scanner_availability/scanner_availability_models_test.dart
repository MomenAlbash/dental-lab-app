import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_exception_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_rule_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_day_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScannerAvailabilityRuleModel.fromJson', () {
    test('reads every field of the DTO', () {
      final rule = ScannerAvailabilityRuleModel.fromJson(const {
        'id': 'r1',
        'dayOfWeek': 2,
        'startTime': '09:00:00',
        'endTime': '17:00:00',
        'slotMinutes': 30,
        'gapMinutes': 10,
        'capacity': 2,
        'isActive': true,
      });

      expect(rule.dayOfWeek, 2);
      expect(rule.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(rule.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(rule.gapMinutes, 10);
      expect(rule.capacity, 2);
      expect(rule.dayLabel, 'الثلاثاء');
      expect(rule.timeRangeLabel, '09:00 - 17:00');
    });

    test('an unparseable time leaves the field null, not a wrong time', () {
      final rule = ScannerAvailabilityRuleModel.fromJson(const {
        'id': 'r1',
        'startTime': 'nonsense',
      });

      expect(rule.startTime, isNull);
      expect(rule.timeRangeLabel, '— - —');
    });
  });

  group('ScannerAvailabilityRuleModel.slotsPerDay', () {
    test('counts the appointments the window actually offers', () {
      // 09:00–17:00 is 480 minutes; 30-minute slots, no gap → 16.
      const rule = ScannerAvailabilityRuleModel(
        id: 'r1',
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 17, minute: 0),
        slotMinutes: 30,
      );

      expect(rule.slotsPerDay, 16);
    });

    test('the gap eats into the count', () {
      // Slots start every 40 minutes; the trailing gap after the last one
      // does not have to fit, so 480 + 10 gives 12 slots.
      const rule = ScannerAvailabilityRuleModel(
        id: 'r1',
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 17, minute: 0),
        slotMinutes: 30,
        gapMinutes: 10,
      );

      expect(rule.slotsPerDay, 12);
    });

    test('capacity multiplies the count', () {
      const rule = ScannerAvailabilityRuleModel(
        id: 'r1',
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 11, minute: 0),
        slotMinutes: 60,
        capacity: 3,
      );

      expect(rule.slotsPerDay, 6);
    });

    test('an inverted or empty window reports nothing, not zero', () {
      const inverted = ScannerAvailabilityRuleModel(
        id: 'r1',
        startTime: TimeOfDay(hour: 17, minute: 0),
        endTime: TimeOfDay(hour: 9, minute: 0),
      );
      const missing = ScannerAvailabilityRuleModel(id: 'r2');

      expect(inverted.slotsPerDay, isNull);
      expect(missing.slotsPerDay, isNull);
    });
  });

  test(
    'SaveScannerAvailabilityRuleRequestModel serialises API field names',
    () {
      const body = SaveScannerAvailabilityRuleRequestModel(
        dayOfWeek: 3,
        startTime: TimeOfDay(hour: 8, minute: 30),
        endTime: TimeOfDay(hour: 16, minute: 0),
        slotMinutes: 45,
        gapMinutes: 5,
        capacity: 2,
      );

      expect(body.toJson(), {
        'dayOfWeek': 3,
        'startTime': '08:30:00',
        'endTime': '16:00:00',
        'slotMinutes': 45,
        'gapMinutes': 5,
        'capacity': 2,
        'isActive': true,
      });
    },
  );

  group('ScannerAvailabilityExceptionModel', () {
    test('a closure summarises as closed', () {
      final exception = ScannerAvailabilityExceptionModel.fromJson(const {
        'id': 'e1',
        'date': '2026-04-01',
        'isClosed': true,
        'reason': 'عطلة',
      });

      expect(exception.dateLabel, '2026-04-01');
      expect(exception.summaryLabel, 'مغلق');
      expect(exception.reason, 'عطلة');
    });

    test('changed hours summarise as the range', () {
      final exception = ScannerAvailabilityExceptionModel.fromJson(const {
        'id': 'e1',
        'date': '2026-04-02',
        'isClosed': false,
        'startTime': '10:00:00',
        'endTime': '13:00:00',
      });

      expect(exception.summaryLabel, '10:00 - 13:00');
    });
  });

  test('a closed exception never sends hours alongside it', () {
    final body = SaveScannerAvailabilityExceptionRequestModel(
      date: DateTime(2026, 4, 1),
      isClosed: true,
      // Left over from the user toggling back and forth in the dialog.
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 17, minute: 0),
      reason: 'عطلة',
    );

    final json = body.toJson();

    expect(json['isClosed'], isTrue);
    expect(json['startTime'], isNull);
    expect(json['endTime'], isNull);
    expect(json['date'], '2026-04-01');
  });

  group('ScannerDayModel', () {
    test('counts only the slots still bookable', () {
      final day = ScannerDayModel.fromJson(const {
        'date': '2026-04-03',
        'isOpen': true,
        'slots': [
          {
            'startAt': '2026-04-03T09:00:00',
            'isAvailable': true,
            'remainingCapacity': 2,
          },
          {
            'startAt': '2026-04-03T09:30:00',
            'isAvailable': false,
            'remainingCapacity': 0,
          },
          {
            'startAt': '2026-04-03T10:00:00',
            'isAvailable': true,
            'remainingCapacity': 1,
          },
        ],
      });

      expect(day.slots.length, 3);
      expect(day.availableCount, 2);
      expect(day.slots.first.timeLabel, '09:00');
    });

    test('an open day can still have nothing left', () {
      final day = ScannerDayModel.fromJson(const {
        'date': '2026-04-03',
        'isOpen': true,
        'slots': [
          {
            'startAt': '2026-04-03T09:00:00',
            'isAvailable': false,
            'remainingCapacity': 0,
          },
        ],
      });

      expect(day.isOpen, isTrue);
      expect(day.availableCount, 0);
    });

    test('a closed day carries its reason', () {
      final day = ScannerDayModel.fromJson(const {
        'date': '2026-04-04',
        'isOpen': false,
        'closedReason': 'صيانة',
        'slots': <dynamic>[],
      });

      expect(day.isOpen, isFalse);
      expect(day.closedReason, 'صيانة');
      expect(day.availableCount, 0);
    });
  });
}
