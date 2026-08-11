import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiTime.parseTime', () {
    test('reads the API\'s HH:mm:ss', () {
      expect(
        ApiTime.parseTime('09:30:00'),
        const TimeOfDay(hour: 9, minute: 30),
      );
    });

    test('also accepts HH:mm', () {
      expect(ApiTime.parseTime('17:05'), const TimeOfDay(hour: 17, minute: 5));
    });

    test('returns null rather than throwing on junk', () {
      // A bad value from the server must not take a whole screen down.
      expect(ApiTime.parseTime(null), isNull);
      expect(ApiTime.parseTime(''), isNull);
      expect(ApiTime.parseTime('noon'), isNull);
      expect(ApiTime.parseTime('9'), isNull);
      expect(ApiTime.parseTime('25:00:00'), isNull);
      expect(ApiTime.parseTime('09:61:00'), isNull);
    });
  });

  group('ApiTime.formatTime', () {
    test('pads to HH:mm:ss, which is what the API binder expects', () {
      expect(
        ApiTime.formatTime(const TimeOfDay(hour: 9, minute: 5)),
        '09:05:00',
      );
    });

    test('round-trips through parseTime', () {
      const time = TimeOfDay(hour: 14, minute: 45);
      expect(ApiTime.parseTime(ApiTime.formatTime(time)), time);
    });
  });

  group('ApiTime dates', () {
    test('formats without a time part', () {
      expect(ApiTime.formatDate(DateTime(2026, 3, 7)), '2026-03-07');
    });

    test('a late-evening date keeps its own day', () {
      // toIso8601String + UTC conversion is what would shift this one.
      expect(ApiTime.formatDate(DateTime(2026, 3, 7, 23, 30)), '2026-03-07');
    });

    test('parses a plain date and drops any time', () {
      expect(ApiTime.parseDate('2026-03-07'), DateTime(2026, 3, 7));
      expect(ApiTime.parseDate('2026-03-07T13:00:00'), DateTime(2026, 3, 7));
    });

    test('returns null on junk', () {
      expect(ApiTime.parseDate(null), isNull);
      expect(ApiTime.parseDate('not-a-date'), isNull);
    });
  });

  group('WeekDays', () {
    test('0 is Sunday, matching the API', () {
      expect(WeekDays.labelOf(0), 'الأحد');
      expect(WeekDays.labelOf(6), 'السبت');
    });

    test('an out-of-range day falls back instead of throwing', () {
      expect(WeekDays.labelOf(7), '—');
      expect(WeekDays.labelOf(-1), '—');
    });

    test('converts Dart weekdays (Mon=1) to the API\'s (Sun=0)', () {
      // 2026-03-08 is a Sunday.
      expect(WeekDays.fromDateTime(DateTime(2026, 3, 8)), 0);
      expect(WeekDays.fromDateTime(DateTime(2026, 3, 9)), 1);
      expect(WeekDays.fromDateTime(DateTime(2026, 3, 14)), 6);
    });
  });
}
